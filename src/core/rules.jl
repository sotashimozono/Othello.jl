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
    can_flip_in_direction(game::ReversiGame, row::Int, col::Int, drow::Int, dcol::Int, player::Int) -> Bool

Check if pieces can be flipped in a given direction from a position.
"""
function can_flip_in_direction(
    game::ReversiGame, row::Int, col::Int, drow::Int, dcol::Int, player::Int
)
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
