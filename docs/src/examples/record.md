```@meta
CurrentModule = Reversi
```

# Game records

[`examples/record_demo.jl`](https://github.com/sotashimozono/Reversi.jl/blob/main/examples/record_demo.jl) —
save, load, validate, and replay game records.

## Workflow

```julia
using Reversi

# 1. Play and save
play_game(RandomPlayer(), RandomPlayer();
          verbose=false, save_record=true, record_path="game.txt")

# 2. Load (throws ArgumentError if format is invalid)
rec = load_game("game.txt")

# 3. Validate move legality before replaying
err = validate_record(rec)
err === nothing || error("Corrupt record: $err")

# 4. Replay (strict=true throws on the first invalid move)
final = replay_game(rec; strict=true)
b, w  = count_pieces(final)
println("Final — Black: $b  White: $w")
```

## `result` field

| Value | Meaning |
|-------|---------|
| `BLACK` (`1`) | Black wins |
| `WHITE` (`-1`) | White wins |
| `EMPTY` (`0`) | Draw |
| `IN_PROGRESS` (`2`) | Game not finished |

## File format

```
MOVES: f5 d6 c5 f4 e3 d3 c4 pass b3 ...
RESULT: BLACK
```

`load_game` throws `ArgumentError` when:
- The file does not exist
- The `MOVES:` or `RESULT:` line is missing
- The result value is unrecognised (not `BLACK`, `WHITE`, `DRAW`, `IN_PROGRESS`)

## Error handling

```julia
# Detect corrupt record without raising
err = validate_record(rec)
# err === nothing  → valid
# err isa String   → describes the first bad move

# Strict replay: raises on any illegal move
try
    replay_game(rec; strict=true)
catch e::ArgumentError
    println("Bad move: ", e.msg)
end
```
