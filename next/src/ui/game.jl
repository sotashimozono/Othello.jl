"""
    play_game(player1, player2; verbose, save_record, record_path) -> Int

Play a full game between `player1` (Black) and `player2` (White).
Returns the winner (`BLACK`, `WHITE`, or `EMPTY` for draw).

Optional keyword arguments:
- `verbose::Bool=true`         – print moves and board to stdout
- `save_record::Bool=false`    – write the game record to disk after the game
- `record_path::String`        – file path used when `save_record=true`
"""
function play_game(
    player1::Player,
    player2::Player;
    verbose::Bool    = true,
    save_record::Bool = false,
    record_path::String = "game_record.txt",
)
    game    = ReversiGame()
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
        color   = game.current_player == BLACK ? "Black" : "White"

        verbose && println("\n" * "="^40)

        move = get_move(current, game)

        if move === nothing
            verbose && println("$color passes.")
            save_record && push!(recorded_moves, "pass")
            pass!(game; force=false)   # force=false: pass! validates no legal moves
        else
            verbose && println("$color plays at $(position_to_string(move))")
            save_record && push!(recorded_moves, position_to_string(move))
            make_move!(game, move.row, move.col)
        end

        verbose && display_board(game)
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
