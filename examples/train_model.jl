#!/usr/bin/env julia
# ===========================================================================
# train_model.jl — Reversi Neural Network Training (Self-play + REINFORCE)
#
# 使い方:
#   julia --project=. examples/train_model.jl
#
# 訓練後、reversi_model.bson が生成されます。
# GUIの [+ Add Player] で以下を入力すれば対戦できます:
#   Name:       Neural Net
#   Expression: FluxPlayer(load_reversi_model("reversi_model.bson"))
# ===========================================================================

using Pkg

# 必要なパッケージを自動インストール
let
    installed = keys(Pkg.dependencies())
    needed = ["Flux", "BSON", "Optimisers"]
    to_install = filter(p -> !any(d -> d.name == p, values(Pkg.dependencies())), needed)
    if !isempty(to_install)
        println("Installing missing packages: $(join(to_install, ", "))")
        Pkg.add(to_install)
    end
end

using Flux
using Flux: logitcrossentropy, params
using BSON: @save, @load
using Statistics: mean
using Printf
using Reversi
using Reversi: BLACK, WHITE, EMPTY, opponent

# ===========================================================================
# 1. 入力特徴量変換
#    入力は (8, 8, 3, batch) の Float32 テンソル
#    ch1: 手番プレイヤーの石
#    ch2: 相手プレイヤーの石
#    ch3: 合法手マスク
# ===========================================================================

"""
    board_to_input(game::ReversiGame) -> Array{Float32,4}

現在の盤面を (8, 8, 3, 1) の Float32 テンソルに変換する。
チャンネル:
  1 = 手番プレイヤーの石
  2 = 相手プレイヤーの石
  3 = 合法手マスク
"""
function board_to_input(game::ReversiGame)
    inp = zeros(Float32, 8, 8, 3, 1)
    color = game.current_player
    opp_color = opponent(color)
    moves = Set(valid_moves(game))
    for row in 1:8, col in 1:8
        piece = get_piece(game, row, col)
        if piece == color
            inp[row, col, 1, 1] = 1.0f0
        elseif piece == opp_color
            inp[row, col, 2, 1] = 1.0f0
        end
        if Position(row, col) in moves
            inp[row, col, 3, 1] = 1.0f0
        end
    end
    return inp
end

"""
    pos_to_index(pos::Position) -> Int

Position を 1-indexed の 64 次元ベクトルの index に変換 (row-major)。
"""
pos_to_index(pos::Position) = (pos.row - 1) * 8 + pos.col

"""
    index_to_pos(idx::Int) -> Position

1-indexed の index を Position に変換。
"""
index_to_pos(idx::Int) = Position(div(idx - 1, 8) + 1, mod(idx - 1, 8) + 1)

# ===========================================================================
# 2. モデル定義 (CNN → Policy head)
# ===========================================================================

"""
    build_model() -> Chain

リバーシ用ポリシーネットワーク。
入力: (8, 8, 3, batch)
出力: (64, batch) — 各マスへの未正規化スコア (logits)
"""
function build_model()
    return Chain(
        # conv block 1
        Conv((3, 3), 3 => 64, relu; pad=1),
        BatchNorm(64),
        # conv block 2
        Conv((3, 3), 64 => 128, relu; pad=1),
        BatchNorm(128),
        # conv block 3
        Conv((3, 3), 128 => 128, relu; pad=1),
        BatchNorm(128),
        # policy head: 1x1 conv → flatten → dense
        Conv((1, 1), 128 => 2, relu),
        x -> reshape(x, 2 * 8 * 8, :),
        Dense(2 * 8 * 8, 64),
    )
end

# ===========================================================================
# 3. FluxPlayer — 訓練済みモデルを使うプレイヤー
# ===========================================================================

"""
    FluxPlayer <: Player

訓練済みFluxモデルを使ってリバーシを打つプレイヤー。
"""
struct FluxPlayer <: Player
    model
end

"""
    get_move(player::FluxPlayer, game::ReversiGame) -> Union{Position, Nothing}

合法手の中でモデルのスコアが最も高いマスを選択する。
"""
function Reversi.get_move(player::FluxPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing

    inp = board_to_input(game)
    logits = player.model(inp)[:, 1]   # (64,)

    # 合法手マスクを適用してargmax
    legal_mask = fill(-Inf32, 64)
    for m in moves
        legal_mask[pos_to_index(m)] = logits[pos_to_index(m)]
    end
    best_idx = argmax(legal_mask)
    return index_to_pos(best_idx)
end

# ===========================================================================
# 4. 自己対戦エピソード収集 (REINFORCE用)
# ===========================================================================

"""
    PolicyPlayer

訓練中モデルを使って、合法手に対してソフトマックスサンプリングで手を選ぶプレイヤー。
"""
mutable struct PolicyPlayer <: Player
    model
    temperature::Float32
end
PolicyPlayer(model) = PolicyPlayer(model, 1.0f0)

function Reversi.get_move(player::PolicyPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing

    inp = board_to_input(game)
    logits = player.model(inp)[:, 1]   # (64,)

    # 合法手だけの確率を計算
    idxs = [pos_to_index(m) for m in moves]
    legal_logits = logits[idxs] ./ player.temperature
    probs = softmax(legal_logits)

    # 確率に基づきサンプリング
    r = rand(Float32)
    cumsum_p = 0.0f0
    chosen = moves[end]
    for (i, m) in enumerate(moves)
        cumsum_p += probs[i]
        if r <= cumsum_p
            chosen = m
            break
        end
    end
    return chosen
end

"""
    Episode

1ゲームのトレース。(input, action_index, reward) のタプルのベクター。
"""
const Episode = Vector{Tuple{Array{Float32,4}, Int, Float32}}

"""
    run_episode(model; temperature=1.0f0) -> Episode

2つのPolicyPlayerが自己対戦し、トレース (state, action, reward) を返す。
reward: 勝ち=+1, 負け=-1, 引き分け=0
"""
function run_episode(model; temperature=1.0f0)
    game = ReversiGame()
    # 両者同じモデルを使い、手番視点で入力を作る
    player_b = PolicyPlayer(model, temperature)
    player_w = PolicyPlayer(model, temperature)
    players = Dict(BLACK => player_b, WHITE => player_w)

    # (カラー, input, action_index)
    trajectory = Tuple{Int, Array{Float32,4}, Int}[]

    while !is_game_over(game)
        color = game.current_player
        inp = board_to_input(game)
        move = get_move(players[color], game)
        if move === nothing
            pass!(game)
            push!(trajectory, (color, inp, 0))  # 0 = pass
        else
            action_idx = pos_to_index(move)
            push!(trajectory, (color, inp, action_idx))
            make_move!(game, move.row, move.col)
        end
    end

    winner = get_winner(game)
    # 各ステップに報酬を割り当て
    episode = Episode()
    for (color, inp, action_idx) in trajectory
        action_idx == 0 && continue  # pass は学習しない
        r = if winner == color
            1.0f0
        elseif winner == opponent(color)
            -1.0f0
        else
            0.0f0
        end
        push!(episode, (inp, action_idx, r))
    end
    return episode
end

# ===========================================================================
# 5. REINFORCE 訓練ループ
# ===========================================================================

"""
    reinforce_loss(model, episode::Episode) -> scalar

REINFORCE目的関数: -∑ R_t * log π(a_t | s_t)
合法手のlogitsに対してcross-entropyを使って計算する。
"""
function reinforce_loss(model, episode::Episode)
    total_loss = 0.0f0
    for (inp, action_idx, reward) in episode
        reward == 0.0f0 && continue  # 引き分けは除外
        logits = model(inp)[:, 1]   # (64,)
        # cross-entropyで action_idx に対する負の対数尤度を計算
        log_prob = logsoftmax(logits)[action_idx]
        total_loss += -reward * log_prob
    end
    return total_loss / max(length(episode), 1)
end

"""
    train!(model, opt_state;
           n_iterations=500, episodes_per_iter=20,
           temperature_start=2.0f0, temperature_end=0.5f0,
           save_path="reversi_model.bson")

REINFORCE で `model` を訓練し、`save_path` に保存する。

パラメータ:
- `n_iterations`: イテレーション回数（多いほど強くなる）
- `episodes_per_iter`: 1イテレーションあたりの自己対戦ゲーム数
- `temperature_start/end`: 探索温度（最初は大きく探索、後半は絞る）
- `save_path`: BSON 保存先
"""
function train!(
    model,
    opt_state;
    n_iterations=500,
    episodes_per_iter=20,
    temperature_start=2.0f0,
    temperature_end=0.5f0,
    save_path="reversi_model.bson",
)
    println("="^60)
    println("REINFORCE Training: Reversi Neural Network")
    println("="^60)
    println("  Iterations:       $n_iterations")
    println("  Episodes/iter:    $episodes_per_iter")
    println("  Save path:        $save_path")
    println()

    best_loss = Inf

    for iter in 1:n_iterations
        # 線形にtemperatureをannealing
        t = temperature_start + (temperature_end - temperature_start) * (iter - 1) / (n_iterations - 1)

        # エピソード収集
        episodes = [run_episode(model; temperature=t) for _ in 1:episodes_per_iter]
        all_episodes = vcat(episodes...)
        isempty(all_episodes) && continue

        # 勝ち/負け/引き分け統計
        wins = count(e -> e[3] > 0, all_episodes)
        losses = count(e -> e[3] < 0, all_episodes)

        # 勾配計算 & パラメータ更新
        loss_val, grads = Flux.withgradient(model) do m
            reinforce_loss(m, all_episodes)
        end

        Flux.update!(opt_state, model, grads[1])

        # ログ
        if iter % 10 == 0 || iter <= 5
            @printf("Iter %4d/%d | loss=%.4f | temp=%.2f | steps: %d (W:%d L:%d)\n",
                iter, n_iterations, loss_val, t, length(all_episodes), wins, losses)
        end

        # ベストモデルを保存
        if loss_val < best_loss
            best_loss = loss_val
            @save save_path model
        end
    end

    # 最終モデルも保存
    @save save_path model
    println()
    println("Training complete! Model saved to: $save_path")
    println("best_loss = $best_loss")
end

# ===========================================================================
# 6. モデル読み込みヘルパー
# ===========================================================================

"""
    load_reversi_model(path="reversi_model.bson") -> Flux model

BSONファイルからモデルをロードして返す。

# 使い方 (GUIの + Add Player):
```julia
FluxPlayer(load_reversi_model("reversi_model.bson"))
```
"""
function load_reversi_model(path="reversi_model.bson")
    @load path model
    return model
end

# ===========================================================================
# 7. エントリポイント
# ===========================================================================

function main()
    println("Building model...")
    model = build_model()
    println("  Parameters: $(sum(length, Flux.params(model)))")

    # Adam optimizer (lr=1e-3)
    opt_state = Flux.setup(Adam(1e-3), model)

    # 訓練 (デフォルトは 500 iter。性能を高めたいなら増やして)
    train!(
        model,
        opt_state;
        n_iterations     = 500,
        episodes_per_iter = 20,
        temperature_start = 2.0f0,
        temperature_end   = 0.5f0,
        save_path         = "reversi_model.bson",
    )

    # 動作確認: FluxPlayer vs RandomPlayer を5ゲーム
    println()
    println("="^60)
    println("Evaluation: FluxPlayer vs RandomPlayer (5 games)")
    println("="^60)
    flux_wins = 0
    for i in 1:5
        winner = play_game(FluxPlayer(model), RandomPlayer(); verbose=false)
        if winner == BLACK
            flux_wins += 1
            println("  Game $i: FluxPlayer (Black) WON")
        elseif winner == WHITE
            println("  Game $i: RandomPlayer (White) WON")
        else
            println("  Game $i: Draw")
        end
    end
    println("FluxPlayer win rate: $flux_wins/5")
    println()
    println("="^60)
    println("GUI Integration:")
    println("  1. launch_gui()")
    println("  2. Click [+ Add Player]")
    println("  3. Name:       Neural Net")
    println("  4. Expression: FluxPlayer(load_reversi_model(\"reversi_model.bson\"))")
    println("     ※ Before this, run in REPL:")
    println("        include(\"examples/train_model.jl\")")
    println("="^60)
end

main()
