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
