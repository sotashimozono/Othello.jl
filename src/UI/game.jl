"""
    display_board(game::ReversiGame; hints::Vector{Position}=Position[])

Display the current board state in the terminal.
Columns are labelled `a`–`h` and rows `1`–`8`.
Optional `hints` highlights valid moves with a green `*`.
"""
function display_board(game::ReversiGame; hints::Vector{Position}=Position[])
    hint_set = Set(hints)
    println("  a b c d e f g h")
    for row in 1:8
        print("$row ")
        for col in 1:8
            bit = one(UInt64) << ((row - 1) * 8 + (col - 1))
            pos = Position(row, col)
            if (game.black & bit) != 0
                print("● ")
            elseif (game.white & bit) != 0
                print("○ ")
            elseif pos in hint_set
                print("\e[32m* \e[0m")
            else
                print("· ")
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
