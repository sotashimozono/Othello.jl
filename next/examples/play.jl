#!/usr/bin/env julia
# play.jl — Interactive CUI game
#
# Usage:
#   julia --project=next next/examples/play.jl

using Reversi

println("="^60)
println("Welcome to Reversi.jl")
println("="^60)
println("""
Rules:
  ● Black plays first
  ○ You must flip at least one opponent piece
  ○ If you have no valid moves you must pass
  ○ Game ends when both players pass or the board is full
""")

function select_mode()
    println("Select mode:")
    println("  1. Human (Black) vs Random AI (White)")
    println("  2. Random AI (Black) vs Human (White)")
    println("  3. Human vs Human")
    println("  4. AI vs AI (watch)")
    while true
        print("Choice [1-4]: ")
        c = tryparse(Int, strip(readline()))
        c !== nothing && 1 <= c <= 4 && return c
        println("  Please enter 1, 2, 3 or 4.")
    end
end

# Uncomment to pick interactively; default is AI vs AI so the script is
# runnable non-interactively (e.g. in CI).
# mode = select_mode()
mode = 4

black, white = if mode == 1
    HumanPlayer(), RandomPlayer()
elseif mode == 2
    RandomPlayer(), HumanPlayer()
elseif mode == 3
    HumanPlayer(), HumanPlayer()
else
    RandomPlayer(), RandomPlayer()
end

println()
winner = play_game(black, white; verbose=true, save_record=true, record_path="last_game.txt")
println()
println("Record saved to last_game.txt — replay it with:")
println("  julia --project=next next/examples/record_demo.jl")
