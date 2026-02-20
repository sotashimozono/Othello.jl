# # Example: Creating a Custom AI Player for Machine Learning Integration
#
# This example demonstrates how to create custom players that can integrate
# with machine learning frameworks like Flux.jl or reinforcement learning libraries.

using Reversi
using Reversi: BLACK, WHITE, EMPTY, count_pieces, is_game_over, opponent

# ## Example 1: Simple Heuristic Player
# This player uses a position-based heuristic
# Corner squares are valuable, edges are decent, next to corners are bad
struct HeuristicPlayer <: Player
    weights::Matrix{Float64}

    function HeuristicPlayer()
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

function Reversi.get_move(player::HeuristicPlayer, game::ReversiGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

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

# ## Example 2: Player that tracks game state for ML training
# Board state is represented as a plain `Matrix{Int}` where `0` = empty,
# `1` = BLACK, `-1` = WHITE — no external dependencies required.
mutable struct TrainingPlayer <: Player
    move_history::Vector{Tuple{Matrix{Int},Position}}

    TrainingPlayer() = new(Tuple{Matrix{Int},Position}[])
end

"""
    board_to_matrix(game::ReversiGame) -> Matrix{Int}

Convert the bitboard state of `game` into an 8×8 `Matrix{Int}` where
`EMPTY == 0`, `BLACK == 1`, and `WHITE == -1`.
"""
function board_to_matrix(game::ReversiGame)
    mat = zeros(Int, 8, 8)
    for row in 1:8, col in 1:8
        mat[row, col] = get_piece(game, row, col)
    end
    return mat
end

# Record the board state as a plain matrix
# Make a random move (in practice, this would use your ML model)
# Store the state-action pair for training
function Reversi.get_move(player::TrainingPlayer, game::ReversiGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    board_copy = board_to_matrix(game)
    move = rand(moves)
    push!(player.move_history, (board_copy, move))

    return move
end

# ## Example 3: Mock Neural Network Player
# This shows the structure for integrating with a real neural network
# In practice, this would be your trained model from Flux, TensorFlow, etc.
struct NeuralNetPlayer <: Player
    model
end

# Convert board to neural network input
# In practice: input = preprocess_board(game.board, game.current_player)
# For demo, we'll just use random

# Get policy from neural network
# In practice: policy = player.model(input)

# Select move based on policy
# In practice: return select_move_from_policy(policy, moves)

function Reversi.get_move(player::NeuralNetPlayer, game::ReversiGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    return rand(moves)
end

# Example 4: Minimax Player (game tree search)
struct MinimaxPlayer <: Player
    depth::Int
    MinimaxPlayer(depth=3) = new(depth)
end
# Simple evaluation: piece count difference
function evaluate_board(game::ReversiGame, player_color::Int)
    black, white = count_pieces(game)
    return player_color == BLACK ? (black - white) : (white - black)
end

function minimax(
    game::ReversiGame,
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
                break
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
                break
            end
        end
        return min_eval
    end
end

function Reversi.get_move(player::MinimaxPlayer, game::ReversiGame)
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
