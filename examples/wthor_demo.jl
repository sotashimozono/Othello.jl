#!/usr/bin/env julia
# ===========================================================================
# wthor_demo.jl — WTHOR データベースのダウンロードと検証デモ
#
# 使い方:
#   julia --project=. examples/wthor_demo.jl
#
# 何をするか:
#   1. Downloads.jl で FFO公式サイトから WTH_2001.wtb をダウンロード
#   2. バイナリをパースしてヘッダー情報と棋譜を表示
#   3. 最初の N ゲームをリプレイして整合性を検証
#   4. write_wthor でファイルに書き出し → 再読み込みのラウンドトリップ確認
#   5. launch_replay_gui でGUIリプレイを起動（オプション）
# ===========================================================================

using Reversi
using Downloads
using Pkg

# ===========================================================================
# 1. ダウンロード
# ===========================================================================

const WTHOR_BASE_URL = "https://www.ffothello.org/wthor/base"
const DEMO_YEAR      = 2001
const LOCAL_WTB      = "WTH_$DEMO_YEAR.wtb"

function download_wthor(year::Int=DEMO_YEAR; dest::String="WTH_$year.wtb")
    if isfile(dest)
        println("✓ $dest already exists — skipping download.")
        return dest
    end
    url = "$WTHOR_BASE_URL/WTH_$year.wtb"
    println("Downloading $url …")
    try
        Downloads.download(url, dest)
        println("  Saved → $dest  ($(filesize(dest)) bytes)")
    catch e
        @error "Download failed: $e"
        println("""
        Manual download instructions:
          1. Open: $url
          2. Save as: $(abspath(dest))
          Then re-run this script.
        """)
        rethrow(e)
    end
    return dest
end

# ===========================================================================
# 2. パースと統計表示
# ===========================================================================

function show_header(header::WThorHeader)
    gy = header.game_year < 100 ? header.game_year + 1900 : header.game_year
    println("""
    ┌─────────────────────────────────────────
    │  WTHOR Header
    │  Created  : $DEMO_YEAR-$(lpad(header.created_month,2,'0'))-$(lpad(header.created_day,2,'0'))
    │  Games    : $(header.n_games)
    │  Year     : $gy
    │  Board    : $(header.board_size)×$(header.board_size)
    │  Type     : $(header.game_type)   Depth: $(header.depth)
    └─────────────────────────────────────────""")
end

function show_game(g::WThorGame, idx::Int)
    score_str = "B $(g.black_score) – W $(64 - g.black_score)"
    println("""  Game #$idx  | TRN=$(g.tournament_id) B#$(g.black_id) W#$(g.white_id) | $score_str
    Moves ($(length(g.moves))): $(join(g.moves[1:min(8,end)], " ")) …""")
end

# ===========================================================================
# 3. 整合性検証
# ===========================================================================

function verify_games(games::Vector{WThorGame}; n::Int=200)
    n = min(n, length(games))
    ok = 0
    fail = 0
    invalid_move_errors = 0
    println("Verifying first $n games …")
    for i in 1:n
        try
            if verify_wthor_game(games[i])
                ok += 1
            else
                fail += 1
            end
        catch e
            invalid_move_errors += 1
        end
    end
    total = ok + fail + invalid_move_errors
    println("""  ✓ Pass  : $ok / $total
  ✗ Score mismatch: $fail / $total
  ✗ Invalid move  : $invalid_move_errors / $total""")
    return ok, fail + invalid_move_errors
end

# ===========================================================================
# 4. ラウンドトリップ (write → read)
# ===========================================================================

function roundtrip_test(games::Vector{WThorGame}; n::Int=50)
    subset = games[1:min(n, end)]
    tmp = tempname() * ".wtb"
    write_wthor(tmp, subset; year=DEMO_YEAR, game_year=DEMO_YEAR - 1900)
    _, reloaded = read_wthor(tmp)
    rm(tmp)
    @assert length(reloaded) == length(subset)
    for (orig, rel) in zip(subset, reloaded)
        @assert orig.moves == rel.moves  "Round-trip moves mismatch!"
        @assert orig.black_score == rel.black_score
    end
    println("  Round-trip OK for $(length(subset)) games.")
end

# ===========================================================================
# 5. エントリポイント
# ===========================================================================

function main()
    println("="^50)
    println("WTHOR Demo — year $DEMO_YEAR")
    println("="^50)

    path   = download_wthor(DEMO_YEAR)
    header, games = read_wthor(path)
    show_header(header)

    println("\nFirst 5 games:")
    for i in 1:min(5, length(games))
        show_game(games[i], i)
    end

    println("\nMove length histogram (sample of 100):")
    sample = games[1:min(100, end)]
    lens = [length(g.moves) for g in sample]
    for l in [40, 45, 50, 55, 60]
        cnt = count(x -> x >= l && x < l + 5, lens)
        bar = "█" ^ cnt
        println("  $l-$(l+4) moves: $bar ($cnt)")
    end

    println()
    ok_count, _ = verify_games(games; n=200)
    pass_rate = round(ok_count / min(200, length(games)) * 100, digits=1)
    println("  → Pass rate: $pass_rate%")

    println("\nRound-trip test (write → read → compare):")
    roundtrip_test(games; n=50)

    println()
    println("="^50)
    println("To replay a game in the GUI:")
    println("""
  julia --project=. -e '
    using Reversi
    _, games = read_wthor("$LOCAL_WTB")
    g = games[1]   # pick any game
    rec = wthor_game_to_record(g)
    launch_replay_gui(rec; title="WTHOR Game #1")
  '
""")
    println("="^50)
end

main()
