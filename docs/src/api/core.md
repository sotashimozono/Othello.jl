```@meta
CurrentModule = Reversi
```

# Core game (`src/core/`)

Pure game logic with no I/O and no rendering.  Every other layer depends on
this one; this layer depends on nothing else in the package.

## Types and constants (`struct.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["core/struct.jl"]
```

## Rules and bitboard logic (`rules.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["core/rules.jl"]
```

## Player interface (`player.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["core/player.jl"]
```

## Classical AI players (`ai_players.jl`)

Five non-ML players built on the bitboard primitives:

- `HeuristicPlayer` — static positional weight table
- `CornerPlayer` — corner-first then positional fallback
- `MobilityPlayer` — maximises own mobility minus opponent's
- `MinimaxPlayer(depth)` — alpha-beta search on piece-count diff
- `MCTSPlayer(iterations)` — UCB1 + random rollout MCTS

```@autodocs
Modules = [Reversi]
Pages   = ["core/ai_players.jl"]
```

---

## Notes

### Bitboard layout

Bit index `i = (row-1)*8 + (col-1)` (0-based), so bit 0 = `(1,1)` (a1) and
bit 63 = `(8,8)` (h8).

### Hash invariant

After every `make_move!` or `pass!` call,
`game.hash == compute_full_hash(game)` holds.  Tests verify this property
throughout random full games.

### Copying game state

```julia
g2 = copy(game)      # fast: copies 5 integer fields
g2 = deepcopy(game)  # slower: avoid in hot loops
```

### `pass!` semantics

```julia
pass!(game)               # throws if current player has legal moves
pass!(game; force=true)   # always passes — use only in replay / tests
```
