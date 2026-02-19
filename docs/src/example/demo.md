```@meta
EditURL = "../../../examples/demo.jl"
```

# How to Play with Reversi.jl
## Example1: script demonstrating Reversi.jl usage

````@example demo
using Reversi

println("="^60)
println("Reversi.jl Demo")
println("="^60)
println()
````

Example 1: Play a game between two random players

````@example demo
println("Example 1: Two Random Players")
println("-" * "="^59)
winner = play_game(RandomPlayer(), RandomPlayer(); verbose=true)
println()
````

## Example 2: Create a custom player that prefers corner moves

````@example demo
struct CornerPlayer <: Player end
function Reversi.get_move(player::CornerPlayer, game::ReversiGame)
    moves = valid_moves(game)
    if isempty(moves)
        return nothing
    end
    corners = [Position(1, 1), Position(1, 8), Position(8, 1), Position(8, 8)]
    for corner in corners
        if corner in moves
            return corner
        end
    end
    return rand(moves)
end

println("\n" * "="^60)
println("Example 2: Corner-Preferring Player vs Random Player")
println("-" * "="^59)
winner = play_game(CornerPlayer(), RandomPlayer(); verbose=true)
println()
````

Example 3: Programmatic game control

````@example demo
println("\n" * "="^60)
println("Example 3: Programmatic Control")
println("-" * "="^59)

game = ReversiGame()
println("Initial board:")
display_board(game)

println("\nMaking first move at (3, 4)...")
make_move!(game, 3, 4)
display_board(game)

println("\nValid moves for current player:")
moves = valid_moves(game)
for move in moves
    println("  ($(move.row), $(move.col))")
end

println("\n" * "="^60)
println("Demo Complete!")
println("="^60)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

