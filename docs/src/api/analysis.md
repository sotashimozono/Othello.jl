```@meta
CurrentModule = Reversi
```

# Analysis (`src/analysis/`)

Position-level analysis using any [`Player`](@ref) as an evaluator. Different
player types use different scoring conventions (positional weights, piece-count
diff, mobility, win rate from rollouts), but
[`evaluate_position`](@ref) and [`principal_variation`](@ref) return uniform
JSON-serialisable shapes.

## Per-move scoring and evaluation (`evaluator.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["analysis/evaluator.jl"]
```

## Opening book (`opening_book.jl`)

Zobrist-hash-keyed opening book built from WTHOR professional game data.
Lookup returns aggregated statistics (game count, win split, candidate moves
with frequencies) for any reached position.

```@autodocs
Modules = [Reversi]
Pages   = ["analysis/opening_book.jl"]
```

---

## Notes

### Available evaluator names

[`make_evaluator`](@ref) accepts the following short names (used by the web API):

| Name | Player |
|------|--------|
| `"random"` | `RandomPlayer()` |
| `"greedy"` | `GreedyPlayer()` |
| `"heuristic"` | `HeuristicPlayer()` |
| `"corner"` | `CornerPlayer()` |
| `"mobility"` | `MobilityPlayer()` |
| `"minimax-N"` | `MinimaxPlayer(N)` (N clamped to 1..6) |
| `"mcts-N"` | `MCTSPlayer(N)` (N clamped to 10..5000) |

### Principal variation

[`principal_variation`](@ref) traces the sequence of moves both sides would
play if each followed the chosen evaluator for `depth` plies. The returned
`boards` array contains absolute board snapshots after each ply, suitable for
mini-board rendering in a UI.
