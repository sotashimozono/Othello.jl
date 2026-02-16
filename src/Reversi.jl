module Reversi

using StaticArrays

# Export main types and functions
export ReversiGame, Player, Position
export make_move!, valid_moves, is_game_over, get_winner, display_board
export HumanPlayer, RandomPlayer, play_game






"""
    is_valid_move(game::ReversiGame, row::Int, col::Int, player::Int) -> Bool

Check if placing a piece at (row, col) is a valid move for the player.
"""
function is_valid_move(game::ReversiGame, row::Int, col::Int, player::Int)
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
    valid_moves(game::ReversiGame, player::Int=game.current_player) -> Vector{Position}

Returns a list of all valid moves for the specified player.
"""
function valid_moves(game::ReversiGame, player::Int=game.current_player)
    moves = Position[]
    for row in 1:8, col in 1:8
        if is_valid_move(game, row, col, player)
            push!(moves, Position(row, col))
        end
    end
    return moves
end

"""
    flip_pieces!(game::ReversiGame, row::Int, col::Int, player::Int)

Flip all pieces that should be flipped when placing a piece at (row, col).
"""
function flip_pieces!(game::ReversiGame, row::Int, col::Int, player::Int)
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
    make_move!(game::ReversiGame, row::Int, col::Int) -> Bool

Make a move at the specified position. Returns true if successful, false otherwise.
"""
function make_move!(game::ReversiGame, row::Int, col::Int)
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
    pass!(game::ReversiGame)

Pass the turn to the opponent.
"""
function pass!(game::ReversiGame)
    game.pass_count += 1
    game.current_player = opponent(game.current_player)
end

"""
    is_game_over(game::ReversiGame) -> Bool

Check if the game is over (no valid moves for either player or board is full).
"""
function is_game_over(game::ReversiGame)
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
    count_pieces(game::ReversiGame) -> (Int, Int)

Returns (black_count, white_count).
"""
function count_pieces(game::ReversiGame)
    black_count = sum(game.board .== BLACK)
    white_count = sum(game.board .== WHITE)
    return black_count, white_count
end

"""
    get_winner(game::ReversiGame) -> Int

Returns the winner (BLACK, WHITE, or EMPTY for draw).
"""
function get_winner(game::ReversiGame)
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
    display_board(game::ReversiGame)

Display the current board state in the terminal.
"""
function display_board(game::ReversiGame)
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


"""
    play_game(player1::Player, player2::Player; verbose::Bool=true) -> Int

Play a complete game between two players. Returns the winner.
"""
function play_game(player1::Player, player2::Player; verbose::Bool=true)
    game = ReversiGame()
    players = Dict(BLACK => player1, WHITE => player2)

    if verbose
        println("Starting new Reversi game!")
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

end # module Reversi
