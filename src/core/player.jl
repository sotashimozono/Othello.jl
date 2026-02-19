# Player interface
"""
    Player

Abstract type for all player implementations.
if you want to create a new player type, subtype Player and implement the get_move function.
"""
abstract type Player end

"""
    get_move(player::Player, game::ReversiGame) -> Union{Position, Nothing}

Get the next move from a player. Returns Nothing if the player wants to pass.
"""
function get_move end

"""
    HumanPlayer <: Player

A player that gets moves from terminal input.
"""
struct HumanPlayer <: Player end

function get_move(player::HumanPlayer, game::ReversiGame; hints=true)
    moves = valid_moves(game)
    # if there are no valid moves, prompt the user to pass
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
        # Accept standard notation "e4"
        m_std = match(r"^([a-h])([1-8])$", input)
        # Accept legacy "row,col" notation
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

A player that makes random valid moves.
"""
struct RandomPlayer <: Player end

function get_move(player::RandomPlayer, game::ReversiGame)
    moves = valid_moves(game)

    if isempty(moves)
        return nothing
    end

    return rand(moves)
end
