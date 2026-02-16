#!/usr/bin/env julia

# Example: Creating a Custom AI Player for Machine Learning Integration
#
# This example demonstrates how to create custom players that can integrate
# with machine learning frameworks like Flux.jl or reinforcement learning libraries.

using Othello
using Othello: BLACK, WHITE, EMPTY, count_pieces, is_game_over, opponent

# Example 1: Simple Heuristic Player
# This player uses a position-based heuristic
struct HeuristicPlayer <: Player
    weights::Matrix{Float64}  # Position weights

    function HeuristicPlayer()
        # Corner squares are valuable, edges are decent, next to corners are bad
        weights = [
            100 -20 10 5 5 10 -20 100;
            -20 -50 -2 -2 -2 -2 -50 -20;
            10 -2 5 3 3 5 -2 10;
            5 -2 3 1 1 3 -2 5;
            5 -2 3 1 1 3 -2 5;
            10 -2 5 3 3 5 -2 10;
            -20 -50 -2 -2 -2 -2 -50 -20;
            100 -20 10 5 5 10 -20 100
        ]
        new(weights)
    end
end

function Othello.get_move(player::HeuristicPlayer, game::OthelloGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    # Score each move by position weight
    best_move = moves[1]
    best_score = player.weights[best_move.row, best_move.col]

    for move in moves[2:end]
        score = player.weights[move.row, move.col]
        if score > best_score
            best_score = score
            best_move = move
        end
    end

    return best_move
end

# Example 2: Player that tracks game state for ML training
mutable struct TrainingPlayer <: Player
    move_history::Vector{Tuple{Matrix{Int},Position}}

    TrainingPlayer() = new(Tuple{Matrix{Int},Position}[])
end

function Othello.get_move(player::TrainingPlayer, game::OthelloGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    # Record the board state
    board_copy = Matrix(game.board)

    # Make a random move (in practice, this would use your ML model)
    move = rand(moves)

    # Store the state-action pair for training
    push!(player.move_history, (board_copy, move))

    return move
end

# Example 3: Mock Neural Network Player
# This shows the structure for integrating with a real neural network
struct NeuralNetPlayer <: Player
    # In practice, this would be your trained model from Flux, TensorFlow, etc.
    model
end

function Othello.get_move(player::NeuralNetPlayer, game::OthelloGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    # Convert board to neural network input
    # In practice: input = preprocess_board(game.board, game.current_player)
    # For demo, we'll just use random

    # Get policy from neural network
    # In practice: policy = player.model(input)

    # Select move based on policy
    # In practice: return select_move_from_policy(policy, moves)

    return rand(moves)  # Placeholder
end

# Example 4: Minimax Player (game tree search)
struct MinimaxPlayer <: Player
    depth::Int

    MinimaxPlayer(depth=3) = new(depth)
end

function evaluate_board(game::OthelloGame, player_color::Int)
    # Simple evaluation: piece count difference
    black, white = count_pieces(game)
    return player_color == BLACK ? (black - white) : (white - black)
end

function minimax(
    game::OthelloGame,
    depth::Int,
    maximizing::Bool,
    alpha::Float64,
    beta::Float64,
    player_color::Int,
)
    if depth == 0 || is_game_over(game)
        return evaluate_board(game, player_color)
    end

    moves = valid_moves(game)

    if isempty(moves)
        # Must pass
        temp_game = deepcopy(game)
        temp_game.current_player = opponent(temp_game.current_player)
        temp_game.pass_count += 1
        return minimax(temp_game, depth - 1, !maximizing, alpha, beta, player_color)
    end

    if maximizing
        max_eval = -Inf
        for move in moves
            temp_game = deepcopy(game)
            make_move!(temp_game, move.row, move.col)
            eval = minimax(temp_game, depth - 1, false, alpha, beta, player_color)
            max_eval = max(max_eval, eval)
            alpha = max(alpha, eval)
            if beta <= alpha
                break  # Alpha-beta pruning
            end
        end
        return max_eval
    else
        min_eval = Inf
        for move in moves
            temp_game = deepcopy(game)
            make_move!(temp_game, move.row, move.col)
            eval = minimax(temp_game, depth - 1, true, alpha, beta, player_color)
            min_eval = min(min_eval, eval)
            beta = min(beta, eval)
            if beta <= alpha
                break  # Alpha-beta pruning
            end
        end
        return min_eval
    end
end

function Othello.get_move(player::MinimaxPlayer, game::OthelloGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    best_move = moves[1]
    best_score = -Inf

    for move in moves
        temp_game = deepcopy(game)
        make_move!(temp_game, move.row, move.col)
        score = minimax(temp_game, player.depth - 1, false, -Inf, Inf, game.current_player)

        if score > best_score
            best_score = score
            best_move = move
        end
    end

    return best_move
end

# Demonstration
println("="^60)
println("Machine Learning Integration Examples")
println("="^60)
println()

println("Test 1: Heuristic Player vs Random")
println("-"^60)
winner = play_game(HeuristicPlayer(), RandomPlayer(); verbose=false)
winner_str =
    winner == BLACK ? "Heuristic (Black)" : (winner == WHITE ? "Random (White)" : "Draw")
println("Winner: $winner_str")
println()

println("Test 2: Training Player (collecting data)")
println("-"^60)
training_player = TrainingPlayer()
winner = play_game(training_player, RandomPlayer(); verbose=false)
println("Collected $(length(training_player.move_history)) state-action pairs for training")
println()

println("Test 3: Minimax Player vs Random (depth=2)")
println("-"^60)
winner = play_game(MinimaxPlayer(2), RandomPlayer(); verbose=false)
winner_str =
    winner == BLACK ? "Minimax (Black)" : (winner == WHITE ? "Random (White)" : "Draw")
println("Winner: $winner_str")
println()

println("="^60)
println("Integration Examples Complete!")
println()
println("Key Takeaways:")
println("  1. Abstract Player type enables easy custom implementations")
println("  2. Game state can be copied for tree search (Minimax, MCTS)")
println("  3. State-action pairs can be collected for supervised learning")
println("  4. Neural network policies can be integrated seamlessly")
println("="^60)
