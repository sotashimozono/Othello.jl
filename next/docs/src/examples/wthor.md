```@meta
CurrentModule = Reversi
```

# WTHOR format

[`examples/wthor_demo.jl`](../../../../next/examples/wthor_demo.jl) —
write, read, and verify `.wtb` files (both internal and external).

## Writing your own games

```julia
using Reversi

# Play a game and collect non-pass moves
game  = ReversiGame()
moves = String[]
while !is_game_over(game)
    ms = valid_moves(game)
    if isempty(ms)
        pass!(game; force=true)    # pass not stored in WTHOR
    else
        m = rand(ms)
        make_move!(game, m)
        push!(moves, position_to_string(m))
    end
end
b, _ = count_pieces(game)

g = WThorGame(1, 42, 99, b, b, moves)
write_wthor("my_game.wtb", [g]; year=2024, game_year=2024)
```

## Reading back and verifying

```julia
header, games = read_wthor("my_game.wtb")
println("Games: $(header.n_games)")

g = games[1]
println("Moves: $(length(g.moves))  Score: $(g.black_score)")

verify_wthor_game(g)   # true if replay matches black_score
```

## Reading FFO professional databases

```julia
using Downloads

Downloads.download("https://www.ffothello.org/wthor/base/WTH_2001.wtb",
                   "WTH_2001.wtb")

header, games = read_wthor("WTH_2001.wtb")
println("$(header.n_games) games from $(header.game_year)")

# Convert to GameRecord and replay in the GUI
rec = wthor_game_to_record(games[1])
launch_replay_gui(rec)
```

## Pass handling

WTHOR does not encode pass moves.  When replaying a WTHOR file, auto-pass
when the current player has no valid moves:

```julia
game = ReversiGame()
for m in g.moves
    while isempty(valid_moves(game)) && !is_game_over(game)
        pass!(game; force=true)
    end
    make_move!(game, m)
end
```

## File-size invariant

Every well-formed `.wtb` file satisfies:
```
filesize(path) == 16 + n_games * 68
```
(16-byte header + 68 bytes per game record).
