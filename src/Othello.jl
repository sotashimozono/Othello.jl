module Othello

using StaticArrays

# Export main types and functions
export OthelloGame, Player, Position
export make_move!, valid_moves, is_game_over, get_winner, display_board
export HumanPlayer, RandomPlayer, play_game

# Player color constants
const EMPTY = 0
const BLACK = 1
const WHITE = 2

"""
    Position

Represents a position on the Othello board (row, col).
"""
struct Position
    row::Int
    col::Int
end

"""
    OthelloGame

Represents the state of an Othello game.
Uses StaticArrays for efficient board representation.
"""
mutable struct OthelloGame
    board::MMatrix{8,8,Int,64}  # 8x8 mutable static array
    current_player::Int           # BLACK or WHITE
    pass_count::Int              # Track consecutive passes
    
    function OthelloGame()
        board = @MMatrix zeros(Int, 8, 8)
        # Initial setup: center 4 pieces
        board[4, 4] = WHITE
        board[4, 5] = BLACK
        board[5, 4] = BLACK
        board[5, 5] = WHITE
        new(board, BLACK, 0)
    end
end

"""
    opponent(player::Int) -> Int

Returns the opponent's color.
"""
opponent(player::Int) = player == BLACK ? WHITE : BLACK

"""
    is_valid_position(row::Int, col::Int) -> Bool

Check if a position is within the board boundaries.
"""
is_valid_position(row::Int, col::Int) = 1 <= row <= 8 && 1 <= col <= 8

"""
    directions() -> Vector{Tuple{Int,Int}}

Returns all 8 directions (row_delta, col_delta) for checking lines.
"""
directions() = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

"""
    can_flip_in_direction(game::OthelloGame, row::Int, col::Int, drow::Int, dcol::Int, player::Int) -> Bool

Check if pieces can be flipped in a given direction from a position.
"""
function can_flip_in_direction(game::OthelloGame, row::Int, col::Int, drow::Int, dcol::Int, player::Int)
    opp = opponent(player)
    r, c = row + drow, col + dcol
    found_opponent = false
    
    while is_valid_position(r, c)
        if game.board[r, c] == EMPTY
            return false
        elseif game.board[r, c] == opp
            found_opponent = true
            r += drow
            c += dcol
        else  # Found player's piece
            return found_opponent
        end
    end
    return false
end

"""
    is_valid_move(game::OthelloGame, row::Int, col::Int, player::Int) -> Bool

Check if placing a piece at (row, col) is a valid move for the player.
"""
function is_valid_move(game::OthelloGame, row::Int, col::Int, player::Int)
    if !is_valid_position(row, col) || game.board[row, col] != EMPTY
        return false
    end
    
    for (drow, dcol) in directions()
        if can_flip_in_direction(game, row, col, drow, dcol, player)
            return true
        end
    end
    return false
end

"""
    valid_moves(game::OthelloGame, player::Int=game.current_player) -> Vector{Position}

Returns a list of all valid moves for the specified player.
"""
function valid_moves(game::OthelloGame, player::Int=game.current_player)
    moves = Position[]
    for row in 1:8, col in 1:8
        if is_valid_move(game, row, col, player)
            push!(moves, Position(row, col))
        end
    end
    return moves
end

"""
    flip_pieces!(game::OthelloGame, row::Int, col::Int, player::Int)

Flip all pieces that should be flipped when placing a piece at (row, col).
"""
function flip_pieces!(game::OthelloGame, row::Int, col::Int, player::Int)
    opp = opponent(player)
    
    for (drow, dcol) in directions()
        if can_flip_in_direction(game, row, col, drow, dcol, player)
            r, c = row + drow, col + dcol
            while game.board[r, c] == opp
                game.board[r, c] = player
                r += drow
                c += dcol
            end
        end
    end
end

"""
    make_move!(game::OthelloGame, row::Int, col::Int) -> Bool

Make a move at the specified position. Returns true if successful, false otherwise.
"""
function make_move!(game::OthelloGame, row::Int, col::Int)
    if !is_valid_move(game, row, col, game.current_player)
        return false
    end
    
    game.board[row, col] = game.current_player
    flip_pieces!(game, row, col, game.current_player)
    game.pass_count = 0
    game.current_player = opponent(game.current_player)
    return true
end

"""
    pass!(game::OthelloGame)

Pass the turn to the opponent.
"""
function pass!(game::OthelloGame)
    game.pass_count += 1
    game.current_player = opponent(game.current_player)
end

"""
    is_game_over(game::OthelloGame) -> Bool

Check if the game is over (no valid moves for either player or board is full).
"""
function is_game_over(game::OthelloGame)
    # Two consecutive passes means game over
    if game.pass_count >= 2
        return true
    end
    
    # Board is full
    if all(game.board .!= EMPTY)
        return true
    end
    
    return false
end

"""
    count_pieces(game::OthelloGame) -> (Int, Int)

Returns (black_count, white_count).
"""
function count_pieces(game::OthelloGame)
    black_count = sum(game.board .== BLACK)
    white_count = sum(game.board .== WHITE)
    return black_count, white_count
end

"""
    get_winner(game::OthelloGame) -> Int

Returns the winner (BLACK, WHITE, or EMPTY for draw).
"""
function get_winner(game::OthelloGame)
    black_count, white_count = count_pieces(game)
    if black_count > white_count
        return BLACK
    elseif white_count > black_count
        return WHITE
    else
        return EMPTY
    end
end

"""
    display_board(game::OthelloGame)

Display the current board state in the terminal.
"""
function display_board(game::OthelloGame)
    println("  1 2 3 4 5 6 7 8")
    for row in 1:8
        print("$row ")
        for col in 1:8
            piece = game.board[row, col]
            if piece == EMPTY
                print("· ")
            elseif piece == BLACK
                print("● ")
            else  # WHITE
                print("○ ")
            end
        end
        println()
    end
    black_count, white_count = count_pieces(game)
    println("Black (●): $black_count  White (○): $white_count")
    println("Current player: $(game.current_player == BLACK ? "Black (●)" : "White (○)")")
end

# Player interface
"""
    Player

Abstract type for all player implementations.
"""
abstract type Player end

"""
    get_move(player::Player, game::OthelloGame) -> Union{Position, Nothing}

Get the next move from a player. Returns Nothing if the player wants to pass.
"""
function get_move end

"""
    HumanPlayer

A player that gets moves from terminal input.
"""
struct HumanPlayer <: Player end

function get_move(player::HumanPlayer, game::OthelloGame)
    moves = valid_moves(game)
    
    if isempty(moves)
        println("No valid moves available. Passing turn.")
        return nothing
    end
    
    println("\nValid moves:")
    for (i, pos) in enumerate(moves)
        print("$(pos.row),$(pos.col) ")
        if i % 8 == 0
            println()
        end
    end
    println()
    
    while true
        print("Enter your move (row,col) or 'p' to pass: ")
        input = readline()
        
        if lowercase(strip(input)) == "p"
            return nothing
        end
        
        parts = split(input, ',')
        if length(parts) == 2
            try
                row = parse(Int, strip(parts[1]))
                col = parse(Int, strip(parts[2]))
                pos = Position(row, col)
                
                if pos in moves
                    return pos
                else
                    println("Invalid move. Please choose from the valid moves.")
                end
            catch
                println("Invalid input format. Use 'row,col' (e.g., '3,4')")
            end
        else
            println("Invalid input format. Use 'row,col' (e.g., '3,4')")
        end
    end
end

"""
    RandomPlayer

A player that makes random valid moves.
"""
struct RandomPlayer <: Player end

function get_move(player::RandomPlayer, game::OthelloGame)
    moves = valid_moves(game)
    
    if isempty(moves)
        return nothing
    end
    
    return rand(moves)
end

"""
    play_game(player1::Player, player2::Player; verbose::Bool=true) -> Int

Play a complete game between two players. Returns the winner.
"""
function play_game(player1::Player, player2::Player; verbose::Bool=true)
    game = OthelloGame()
    players = Dict(BLACK => player1, WHITE => player2)
    
    if verbose
        println("Starting new Othello game!")
        println("Black (●) vs White (○)")
        println()
        display_board(game)
    end
    
    while !is_game_over(game)
        current = players[game.current_player]
        
        if verbose
            println("\n" * "="^40)
        end
        
        move = get_move(current, game)
        
        if move === nothing
            if verbose
                color = game.current_player == BLACK ? "Black" : "White"
                println("$color passes.")
            end
            pass!(game)
        else
            if verbose
                color = game.current_player == BLACK ? "Black" : "White"
                println("$color plays at ($(move.row), $(move.col))")
            end
            make_move!(game, move.row, move.col)
        end
        
        if verbose
            display_board(game)
        end
    end
    
    winner = get_winner(game)
    
    if verbose
        println("\n" * "="^40)
        println("Game Over!")
        if winner == EMPTY
            println("It's a draw!")
        else
            winner_name = winner == BLACK ? "Black (●)" : "White (○)"
            println("$winner_name wins!")
        end
        black_count, white_count = count_pieces(game)
        println("Final score - Black: $black_count, White: $white_count")
    end
    
    return winner
end

end # module Othello
