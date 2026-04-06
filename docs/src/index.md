```@meta
CurrentModule = Reversi
```

# Reversi.jl

A high-performance Reversi (Othello) engine in Julia built on bitboard
representation, with a clean three-layer architecture:

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| **Core game** | `src/core/` | Pure game state, rules, bitboard logic |
| **I/O** | `src/io/` | File formats: game records, WTHOR binary |
| **UI** | `src/ui/` | Terminal (CUI), GLMakie GUI |

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/sotashimozono/Reversi.jl")
```

## Quick start

```julia
using Reversi

# Terminal game — Human vs Random AI
play_game(HumanPlayer(), RandomPlayer())
```

```julia
# GUI game
launch_gui(GUIPlayer(), RandomPlayer())
```

## Custom player interface

```julia
using Reversi

struct MyPlayer <: Player end

function Reversi.get_move(::MyPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing   # pass
    return rand(moves)                 # your logic here
end

play_game(MyPlayer(), RandomPlayer(); verbose=false)
```

## Key design decisions

### `IN_PROGRESS` result constant

`GameRecord.result` uses named constants instead of magic numbers:

| Constant | Value | Meaning |
|----------|-------|---------|
| `BLACK` | `1` | Black wins |
| `WHITE` | `-1` | White wins |
| `EMPTY` | `0` | Draw |
| `IN_PROGRESS` | `2` | Game not yet finished |

### Safe `pass!`

`pass!(game)` checks that the current player genuinely has no legal moves.
Use `pass!(game; force=true)` only when you need to override (e.g. WTHOR replay).

### `Base.copy` vs `deepcopy`

`copy(game)` performs a fast field-by-field copy of the game state (all fields
are value types).  Prefer it over `deepcopy` in hot loops such as tree search.

### `validate_record` before replay

```julia
err = validate_record(record)
err === nothing || error("Bad record: $err")
replayed = replay_game(record; strict=true)
```
