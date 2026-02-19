```@meta
EditURL = "../../../examples/play.jl"
```

Interactive terminal Reversi game

````@example play
using Reversi

println("="^60)
println("Welcome to Reversi!")
println("="^60)
println()
println("Rules:")
println("  - Black (●) plays first")
println("  - You must flip at least one opponent piece")
println("  - If no valid moves, you must pass")
println("  - Game ends when both players pass or board is full")
println()

function select_game_mode()
    println("Select game mode:")
    println("  1. Human (Black) vs Random AI (White)")
    println("  2. Human (White) vs Random AI (Black)")
    println("  3. Human vs Human")
    println("  4. Random AI vs Random AI (watch)")

    while true
        print("Enter choice (1-4): ")
        input = readline()
        choice = tryparse(Int, strip(input))

        if choice !== nothing && 1 <= choice <= 4
            return choice
        end
        println("Invalid choice. Please enter 1, 2, 3, or 4.")
    end
end

mode = select_game_mode()
println()

if mode == 1
    println("You are Black (●), AI is White (○)")
    player1 = HumanPlayer()
    player2 = RandomPlayer()
elseif mode == 2
    println("AI is Black (●), You are White (○)")
    player1 = RandomPlayer()
    player2 = HumanPlayer()
elseif mode == 3
    println("Human vs Human mode")
    player1 = HumanPlayer()
    player2 = HumanPlayer()
else
    println("Watch mode: AI vs AI")
    player1 = RandomPlayer()
    player2 = RandomPlayer()
end

println()
play_game(player1, player2; verbose=true)
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

