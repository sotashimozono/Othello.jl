```@meta
CurrentModule = Reversi
```

# Play (CUI)

[`examples/play.jl`](../../../../next/examples/play.jl) — interactive terminal game.

```julia
# Run:
#   julia --project=next next/examples/play.jl

using Reversi

play_game(HumanPlayer(), RandomPlayer(); verbose=true,
          save_record=true, record_path="last_game.txt")
```

Moves are entered as standard notation (`e4`, `d3`, …) or `row,col` format.
The board is re-drawn after every move with valid-move hints highlighted in green.

The game record is automatically saved; see [Game records](record.md) to
load and replay it.
