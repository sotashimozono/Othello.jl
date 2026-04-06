```@meta
CurrentModule = Reversi
```

# Custom players

[`examples/custom_player.jl`](https://github.com/sotashimozono/Reversi.jl/blob/main/examples/custom_player.jl) —
three example `Player` implementations showing common patterns.

## The `Player` interface

```julia
abstract type Player end
get_move(player::Player, game::ReversiGame) -> Union{Position, Nothing}
```

Return `nothing` to signal a pass.  The game engine calls `pass!` automatically.

## 1. Heuristic player (position weights)

```julia
struct HeuristicPlayer <: Player
    weights::Matrix{Float64}
    HeuristicPlayer() = new(Float64[
        100 -20  10   5   5  10 -20 100;
        # … (8×8 table; corners=100, adjacent-to-corner=-20, …)
    ])
end

function Reversi.get_move(player::HeuristicPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    return argmax(m -> player.weights[m.row, m.col], moves)
end
```

## 2. Minimax with alpha-beta pruning

Uses [`copy(game)`](@ref Base.copy) (fast field copy) instead of `deepcopy`,
and [`pass!(game; force=true)`](@ref pass!) for null moves.

```julia
struct MinimaxPlayer <: Player
    depth::Int
end

function Reversi.get_move(player::MinimaxPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    color = game.current_player
    return argmax(moves) do m
        g2 = copy(game)
        make_move!(g2, m)
        _minimax(g2, player.depth - 1, -Inf, Inf, false, color)
    end
end
```

## 3. Mobility player

Maximises own mobility minus opponent mobility — a strong and simple heuristic.

```julia
struct MobilityPlayer <: Player end

function Reversi.get_move(::MobilityPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    opp = opponent(game.current_player)
    return argmax(moves) do m
        g2 = copy(game)
        make_move!(g2, m)
        mobility(g2, game.current_player) - mobility(g2, opp)
    end
end
```

## Integrating a machine-learning model

```julia
struct MyMLPlayer <: Player
    model   # ITensors MPS, Flux Chain, …
end

function Reversi.get_move(p::MyMLPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing

    # Convert board to model input
    mat = Float32[get_piece(game, r, c) for r in 1:8, c in 1:8]

    # Score each candidate move with the model
    scores = [infer(p.model, mat, m) for m in moves]

    return moves[argmax(scores)]
end
```

The same pattern works whether the model is an ITensors tensor network,
a Flux neural network, or any other callable.
