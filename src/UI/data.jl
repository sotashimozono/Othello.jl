"""
    GameRecord

Stores the complete move history of a finished (or in-progress) Reversi game
as a vector of standard notation strings (e.g. `["d3", "c5", ...]`).

Fields:
- `moves::Vector{String}` – ordered list of moves in standard notation.
- `result::Int`           – `BLACK`, `WHITE`, or `EMPTY` (draw); `2` when not yet finished.
"""
struct GameRecord
    moves::Vector{String}
    result::Int
end

GameRecord(moves::Vector{String}) = GameRecord(moves, 2)

"""
    save_game(record::GameRecord, filepath::String)

Write a `GameRecord` to `filepath` in a simple text format.

Format:
```
MOVES: d3 c5 f4 ...
RESULT: BLACK | WHITE | DRAW
```
"""
function save_game(record::GameRecord, filepath::String)
    open(filepath, "w") do io
        println(io, "MOVES: " * join(record.moves, " "))
        result_str = if record.result == BLACK
            "BLACK"
        elseif record.result == WHITE
            "WHITE"
        elseif record.result == EMPTY
            "DRAW"
        else
            "UNKNOWN"
        end
        println(io, "RESULT: $result_str")
    end
end

"""
    load_game(filepath::String) -> GameRecord

Read a `GameRecord` from a file previously written by `save_game`.
"""
function load_game(filepath::String)::GameRecord
    moves = String[]
    result = 2
    for line in eachline(filepath)
        if startswith(line, "MOVES:")
            raw = strip(line[(length("MOVES:") + 1):end])
            moves = isempty(raw) ? String[] : split(raw, " ")
        elseif startswith(line, "RESULT:")
            val = strip(line[(length("RESULT:") + 1):end])
            result = if val == "BLACK"
                BLACK
            elseif val == "WHITE"
                WHITE
            elseif val == "DRAW"
                EMPTY
            else
                2
            end
        end
    end
    return GameRecord(moves, result)
end

"""
    replay_game(record::GameRecord; verbose::Bool=false) -> ReversiGame

Replay all moves stored in `record` on a fresh `ReversiGame` and return the
resulting game state.  Passes are represented by the special token `"pass"`.
"""
function replay_game(record::GameRecord; verbose::Bool=false)::ReversiGame
    game = ReversiGame()
    for (i, move_str) in enumerate(record.moves)
        if verbose
            println("Move $i: $move_str")
        end
        if move_str == "pass"
            pass!(game)
        else
            make_move!(game, move_str)
        end
    end
    return game
end

"""
    play_game(player1::Player, player2::Player;
              verbose::Bool=true, save_record::Bool=false,
              record_path::String="game_record.txt") -> Int

Extended version of `play_game` that optionally saves the move history.
When `save_record=true` the record is written to `record_path` after the game.
Returns the winner (`BLACK`, `WHITE`, or `EMPTY`).
"""
function play_game(
    player1::Player,
    player2::Player;
    verbose::Bool=true,
    save_record::Bool=false,
    record_path::String="game_record.txt",
)
    game = ReversiGame()
    players = Dict(BLACK => player1, WHITE => player2)
    recorded_moves = String[]

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
            save_record && push!(recorded_moves, "pass")
            pass!(game)
        else
            if verbose
                color = game.current_player == BLACK ? "Black" : "White"
                println("$color plays at $(position_to_string(move))")
            end
            save_record && push!(recorded_moves, position_to_string(move))
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

    if save_record
        record = GameRecord(recorded_moves, winner)
        save_game(record, record_path)
        verbose && println("Game record saved to: $record_path")
    end

    return winner
end
