"""
    Player

Abstract type for all player implementations.
Subtype and implement `get_move(player, game)` to create a new player.
"""
abstract type Player end

"""
    get_move(player::Player, game::ReversiGame) -> Union{Position, Nothing}

Get the next move from a player.  Returns `nothing` to indicate a pass.
"""
function get_move end

"""
    HumanPlayer <: Player

A player that gets moves from terminal input.
"""
struct HumanPlayer <: Player end

function get_move(::HumanPlayer, game::ReversiGame; hints=true)
    moves = valid_moves(game)
    if isempty(moves)
        println("\e[33mNo valid moves. Press Enter to pass...\e[0m")
        readline()
        return nothing
    end

    if hints
        display_board(game; hints=moves)
    else
        display_board(game; hints=Position[])
    end

    while true
        print("\nMove (e.g. e4 or row,col): ")
        input = lowercase(strip(readline()))
        m_std = match(r"^([a-h])([1-8])$", input)
        m_leg = match(r"^([1-8])[\s,]*([1-8])$", input)
        pos = if m_std !== nothing
            Position(string(m_std.captures[1]) * string(m_std.captures[2]))
        elseif m_leg !== nothing
            Position(parse(Int, m_leg.captures[1]), parse(Int, m_leg.captures[2]))
        else
            nothing
        end
        if pos !== nothing && pos in moves
            return pos
        elseif pos !== nothing
            println("\e[31mInvalid move! See the green '*' marks.\e[0m")
        else
            println("\e[31mPlease enter as 'e4' or 'row,col' (e.g., 4,3).\e[0m")
        end
    end
end

"""
    RandomPlayer <: Player

A player that picks a random valid move each turn.
"""
struct RandomPlayer <: Player end

function get_move(::RandomPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    return rand(moves)
end

"""
    GreedyPlayer <: Player

A player that always picks the move that flips the most pieces.
"""
struct GreedyPlayer <: Player end

function get_move(::GreedyPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    player_bb = game.current_player == BLACK ? game.black : game.white
    opponent_bb = game.current_player == BLACK ? game.white : game.black
    best_move = moves[1]
    best_count = -1
    for m in moves
        bit = one(UInt64) << ((m.row - 1) * 8 + (m.col - 1))
        n = count_ones(compute_flips(bit, player_bb, opponent_bb))
        if n > best_count
            best_count = n
            best_move = m
        end
    end
    return best_move
end
