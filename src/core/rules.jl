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

# ---------------------------------------------------------------------------
# Bitboard shift helpers
# Column-A mask: bits where col == 1 (must not shift west).
# Column-H mask: bits where col == 8 (must not shift east).
# ---------------------------------------------------------------------------

const _COL_A = UInt64(0x0101010101010101)
const _COL_H = UInt64(0x8080808080808080)

@inline _shift_n(x::UInt64) = x >> 8
@inline _shift_s(x::UInt64) = x << 8
@inline _shift_e(x::UInt64) = (x & ~_COL_H) << 1
@inline _shift_w(x::UInt64) = (x & ~_COL_A) >> 1
@inline _shift_ne(x::UInt64) = (x & ~_COL_H) >> 7
@inline _shift_nw(x::UInt64) = (x & ~_COL_A) >> 9
@inline _shift_se(x::UInt64) = (x & ~_COL_H) << 9
@inline _shift_sw(x::UInt64) = (x & ~_COL_A) << 7

const _SHIFTS = (
    _shift_n, _shift_s, _shift_e, _shift_w, _shift_ne, _shift_nw, _shift_se, _shift_sw
)

# ---------------------------------------------------------------------------
# Core bitboard algorithms
# ---------------------------------------------------------------------------

"""
    legal_moves_bb(player::UInt64, opponent::UInt64) -> UInt64

Return a bitmask of all squares where `player` can legally place a piece,
using a Kogge-Stone (Dumb7Fill) flood-fill in each of the 8 directions.
"""
function legal_moves_bb(player::UInt64, opponent::UInt64)::UInt64
    empty = ~(player | opponent)
    legal = zero(UInt64)
    for shift_fn in _SHIFTS
        # Flood from player through opponent pieces (up to 6 in a row)
        gen = shift_fn(player) & opponent
        gen |= shift_fn(gen) & opponent
        gen |= shift_fn(gen) & opponent
        gen |= shift_fn(gen) & opponent
        gen |= shift_fn(gen) & opponent
        gen |= shift_fn(gen) & opponent
        legal |= shift_fn(gen) & empty
    end
    return legal
end

"""
    compute_flips(pos::UInt64, player::UInt64, opponent::UInt64) -> UInt64

Return a bitmask of opponent pieces that would be flipped if `player` places
at the single-bit position `pos`.
"""
function compute_flips(pos::UInt64, player::UInt64, opponent::UInt64)::UInt64
    flips = zero(UInt64)
    for shift_fn in _SHIFTS
        candidates = shift_fn(pos) & opponent
        candidates |= shift_fn(candidates) & opponent
        candidates |= shift_fn(candidates) & opponent
        candidates |= shift_fn(candidates) & opponent
        candidates |= shift_fn(candidates) & opponent
        candidates |= shift_fn(candidates) & opponent
        # Valid only when a player piece closes the bracket
        if shift_fn(candidates) & player != 0
            flips |= candidates
        end
    end
    return flips
end

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

"""
    get_piece(game::ReversiGame, row::Int, col::Int) -> Int

Return `BLACK`, `WHITE`, or `EMPTY` for the given square.
"""
function get_piece(game::ReversiGame, row::Int, col::Int)::Int
    bit = one(UInt64) << ((row - 1) * 8 + (col - 1))
    (game.black & bit) != 0 && return BLACK
    (game.white & bit) != 0 && return WHITE
    return EMPTY
end

"""
    is_valid_move(game::ReversiGame, row::Int, col::Int[, player::Int]) -> Bool

Check if placing a piece at `(row, col)` is a valid move for `player`.
"""
function is_valid_move(
    game::ReversiGame, row::Int, col::Int, player::Int=game.current_player
)
    is_valid_position(row, col) || return false
    bit = one(UInt64) << ((row - 1) * 8 + (col - 1))
    player_bb = player == BLACK ? game.black : game.white
    opponent_bb = player == BLACK ? game.white : game.black
    return (bit & legal_moves_bb(player_bb, opponent_bb)) != 0
end

"""
    valid_moves(game::ReversiGame[, player::Int]) -> Vector{Position}

Return all valid moves for `player` (defaults to `game.current_player`).
"""
function valid_moves(game::ReversiGame, player::Int=game.current_player)
    player_bb = player == BLACK ? game.black : game.white
    opponent_bb = player == BLACK ? game.white : game.black
    bb = legal_moves_bb(player_bb, opponent_bb)
    moves = Position[]
    while bb != 0
        idx = trailing_zeros(bb)
        push!(moves, Position(div(idx, 8) + 1, mod(idx, 8) + 1))
        bb &= bb - one(UInt64)
    end
    return moves
end

"""
    make_move!(game::ReversiGame, row::Int, col::Int) -> Bool

Place a piece at `(row, col)` for the current player.  Updates the board and
the incremental Zobrist hash.  Returns `true` on success, `false` if the move
is illegal.
"""
function make_move!(game::ReversiGame, row::Int, col::Int)
    player = game.current_player
    opp = opponent(player)

    player_bb = player == BLACK ? game.black : game.white
    opponent_bb = player == BLACK ? game.white : game.black

    bit = one(UInt64) << ((row - 1) * 8 + (col - 1))

    (bit & legal_moves_bb(player_bb, opponent_bb)) != 0 || return false

    flips = compute_flips(bit, player_bb, opponent_bb)

    # Incremental hash: add placed piece
    game.hash ⊻= ZOBRIST_TABLE[row, col, _color_idx(player)]

    # Incremental hash: toggle each flipped piece (remove opp, add player)
    flip_copy = flips
    while flip_copy != 0
        idx = trailing_zeros(flip_copy)
        r = div(idx, 8) + 1
        c = mod(idx, 8) + 1
        game.hash ⊻= ZOBRIST_TABLE[r, c, _color_idx(opp)]
        game.hash ⊻= ZOBRIST_TABLE[r, c, _color_idx(player)]
        flip_copy &= flip_copy - one(UInt64)
    end

    new_player_bb = player_bb | bit | flips
    new_opponent_bb = opponent_bb & ~flips

    if player == BLACK
        game.black = new_player_bb
        game.white = new_opponent_bb
    else
        game.white = new_player_bb
        game.black = new_opponent_bb
    end

    game.pass_count = 0
    game.current_player = opp
    return true
end

"""
    make_move!(game::ReversiGame, pos::Position) -> Bool

Make a move at the given `Position`.
"""
make_move!(game::ReversiGame, pos::Position) = make_move!(game, pos.row, pos.col)

"""
    make_move!(game::ReversiGame, s::AbstractString) -> Bool

Make a move specified in standard Reversi notation (e.g. `"e4"`).
"""
make_move!(game::ReversiGame, s::AbstractString) = make_move!(game, Position(s))

"""
    pass!(game::ReversiGame)

Pass the turn to the opponent and increment the consecutive-pass counter.
"""
function pass!(game::ReversiGame)
    game.pass_count += 1
    game.current_player = opponent(game.current_player)
end

"""
    is_game_over(game::ReversiGame) -> Bool

Return `true` when the game has ended (two consecutive passes, or board full,
or neither player has any legal move).
"""
function is_game_over(game::ReversiGame)
    game.pass_count >= 2 && return true
    (game.black | game.white) == typemax(UInt64) && return true
    # End game if neither player has any legal moves (stalemate condition)
    legal_black = legal_moves_bb(game.black, game.white)
    legal_white = legal_moves_bb(game.white, game.black)
    (legal_black | legal_white) == 0 && return true
    return false
end

"""
    count_pieces(game::ReversiGame) -> (Int, Int)

Return `(black_count, white_count)`.
"""
function count_pieces(game::ReversiGame)
    return count_ones(game.black), count_ones(game.white)
end

"""
    get_winner(game::ReversiGame) -> Int

Return `BLACK`, `WHITE`, or `EMPTY` (draw) based on piece counts.
"""
function get_winner(game::ReversiGame)
    black_count, white_count = count_pieces(game)
    black_count > white_count && return BLACK
    white_count > black_count && return WHITE
    return EMPTY
end

"""
    next_state(game::ReversiGame, move::Position) -> ReversiGame

Return a new `ReversiGame` that results from applying `move` to a deep copy of
`game`.  The original `game` is not modified (copy-on-move semantics).
"""
function next_state(game::ReversiGame, move::Position)::ReversiGame
    new_game = deepcopy(game)
    make_move!(new_game, move.row, move.col)
    return new_game
end

"""
    next_state(game::ReversiGame, move::AbstractString) -> ReversiGame

Copy-on-move variant that accepts standard Reversi notation (e.g. `"e4"`).
"""
next_state(game::ReversiGame, move::AbstractString) = next_state(game, Position(move))
