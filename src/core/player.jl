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
        display_board(game, hints=moves)
    else
        display_board(game, hints=[])
    end

    while true
        print("\nMove (row,col): ")
        input = readline() |> strip |> lowercase
        # imput format: "row,col" or "row col"
        m = match(r"^([1-8])[\s,]*([1-8])$", input)
        if m !== nothing
            row, col = parse(Int, m.captures[1]), parse(Int, m.captures[2])
            pos = Position(row, col)
            if pos in moves
                return pos
            else
                println("\e[31mInvalid move! See the green '*' marks.\e[0m")
            end
        else
            println("\e[31mPlease enter as 'row,col' (e.g., 4,3) using numbers 1-8.\e[0m")
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
