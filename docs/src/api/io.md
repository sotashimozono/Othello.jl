```@meta
CurrentModule = Reversi
```

# I/O (`src/io/`)

Serialisation and file-format support.  Depends on `core/`; does not depend
on `ui/`.

## Game records (`record.jl`)

`GameRecord` is the primary in-memory and on-disk representation of a finished
or in-progress game.

```@autodocs
Modules = [Reversi]
Pages   = ["io/record.jl"]
```

### File format

```
MOVES: f5 d6 c5 f4 e3 d3 c4 ...
RESULT: BLACK | WHITE | DRAW | IN_PROGRESS
```

- Moves are space-separated standard notation (`a1`–`h8`).
- Passes are recorded as the token `pass`.
- `load_game` throws `ArgumentError` if either line is missing or the result
  value is unrecognised.

### Recommended workflow

```julia
# Save
play_game(p1, p2; save_record=true, record_path="game.txt")

# Validate before use
rec = load_game("game.txt")
err = validate_record(rec)
err === nothing || error("Corrupt record: $err")

# Replay (strict mode catches any remaining inconsistency)
final = replay_game(rec; strict=true)
```

---

## WTHOR binary format (`wthor.jl`)

WTHOR (`.wtb`) is the standard database format for professional Othello games,
maintained by the Fédération Française d'Othello (FFO).

```@autodocs
Modules = [Reversi]
Pages   = ["io/wthor.jl"]
```

### File layout

```
Header  (16 bytes)
  byte  0     : creation century
  byte  1     : year within century
  bytes 2-3   : month, day
  bytes 4-7   : n_games  (Int32 LE)
  bytes 8-9   : count    (Int16 LE, same as n_games)
  bytes 10-11 : game_year (Int16 LE)
  byte  12    : board_size (always 8)
  bytes 13-15 : game_type, depth, reserved

Per-game record  (68 bytes × n_games)
  bytes 0-1  : tournament_id  (Int16 LE)
  bytes 2-3  : black_id       (Int16 LE)
  bytes 4-5  : white_id       (Int16 LE)
  byte  6    : black_score    (UInt8, actual disc count)
  byte  7    : best_score     (UInt8, theoretical best)
  bytes 8-67 : moves          (60 × UInt8, 0x00 = padding)
```

Move encoding: `byte = row × 10 + col` (row/col 1-indexed, col a=1…h=8).

### File-size invariant

```julia
filesize(path) == 16 + n_games * 68
```

### Pass handling

WTHOR does not encode pass moves.  When replaying a WTHOR file, auto-pass
between recorded moves:

```julia
for m in g.moves
    while isempty(valid_moves(game)) && !is_game_over(game)
        pass!(game; force=true)
    end
    make_move!(game, m)
end
```
