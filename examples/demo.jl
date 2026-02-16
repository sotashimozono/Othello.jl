#!/usr/bin/env julia

# Example script demonstrating Othello.jl usage

using Othello

println("="^60)
println("Othello.jl Demo")
println("="^60)
println()

# Example 1: Play a game between two random players
println("Example 1: Two Random Players")
println("-" * "="^59)
winner = play_game(RandomPlayer(), RandomPlayer(); verbose=true)
println()

# Example 2: Create a custom player that prefers corner moves
struct CornerPlayer <: Player end

function Othello.get_move(player::CornerPlayer, game::OthelloGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    # Prefer corners
    corners = [Position(1, 1), Position(1, 8), Position(8, 1), Position(8, 8)]
    for corner in corners
        if corner in moves
            return corner
        end
    end

    # Otherwise random
    return rand(moves)
end

println("\n" * "="^60)
println("Example 2: Corner-Preferring Player vs Random Player")
println("-" * "="^59)
winner = play_game(CornerPlayer(), RandomPlayer(); verbose=true)
println()

# Example 3: Programmatic game control
println("\n" * "="^60)
println("Example 3: Programmatic Control")
println("-" * "="^59)

game = OthelloGame()
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
