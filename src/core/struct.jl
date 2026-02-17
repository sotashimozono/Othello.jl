# Player color constants
const EMPTY = 0
const BLACK = 1
const WHITE = 2

"""
    Position

Represents a position on the Reversi board (row, col).
"""
struct Position
    row::Int
    col::Int
end

"""
    ReversiGame

Represents the state of an Reversi game.
Uses StaticArrays for efficient board representation.
"""
mutable struct ReversiGame
    board::MMatrix{8,8,Int,64}  # 8x8 mutable static array
    current_player::Int         # BLACK or WHITE
    pass_count::Int             # Track consecutive passes

    function ReversiGame()
        board = @MMatrix zeros(Int, 8, 8)
        # Initial setup: center 4 pieces
        board[4, 4] = WHITE
        board[4, 5] = BLACK
        board[5, 4] = BLACK
        board[5, 5] = WHITE
        new(board, BLACK, 0)
    end
end
