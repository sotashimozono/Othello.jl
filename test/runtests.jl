ENV["GKSwstype"] = "100"

using Othello, Test

# Import internal constants for testing
using Othello: EMPTY, BLACK, WHITE, opponent, is_valid_position, count_pieces, pass!

@testset "Othello.jl" begin
    @testset "Game Initialization" begin
        game = OthelloGame()
        @test game.board[4, 4] == WHITE
        @test game.board[4, 5] == BLACK
        @test game.board[5, 4] == BLACK
        @test game.board[5, 5] == WHITE
        @test game.current_player == BLACK
        @test game.pass_count == 0
    end

    @testset "Opponent Function" begin
        @test opponent(BLACK) == WHITE
        @test opponent(WHITE) == BLACK
    end

    @testset "Position Validation" begin
        @test is_valid_position(1, 1) == true
        @test is_valid_position(8, 8) == true
        @test is_valid_position(0, 1) == false
        @test is_valid_position(1, 9) == false
        @test is_valid_position(9, 1) == false
    end

    @testset "Valid Moves" begin
        game = OthelloGame()
        moves = valid_moves(game, BLACK)

        # Black should have exactly 4 valid opening moves
        @test length(moves) == 4
        @test Position(3, 4) in moves
        @test Position(4, 3) in moves
        @test Position(5, 6) in moves
        @test Position(6, 5) in moves
    end

    @testset "Make Move" begin
        game = OthelloGame()

        # Black makes a valid move
        @test make_move!(game, 3, 4) == true
        @test game.board[3, 4] == BLACK
        @test game.board[4, 4] == BLACK  # White piece flipped
        @test game.current_player == WHITE

        # Try invalid move
        game2 = OthelloGame()
        @test make_move!(game2, 1, 1) == false
        @test game2.current_player == BLACK  # Turn not changed
    end

    @testset "Piece Counting" begin
        game = OthelloGame()
        black_count, white_count = count_pieces(game)
        @test black_count == 2
        @test white_count == 2

        make_move!(game, 3, 4)
        black_count, white_count = count_pieces(game)
        @test black_count == 4
        @test white_count == 1
    end

    @testset "Pass and Game Over" begin
        game = OthelloGame()
        @test is_game_over(game) == false

        pass!(game)
        @test game.pass_count == 1
        @test game.current_player == WHITE
        @test is_game_over(game) == false

        pass!(game)
        @test game.pass_count == 2
        @test is_game_over(game) == true
    end

    @testset "Winner Detection" begin
        game = OthelloGame()

        # Manually set up a winning position for black
        game.board .= EMPTY
        game.board[1, 1] = BLACK
        game.board[1, 2] = BLACK
        game.board[1, 3] = WHITE

        @test get_winner(game) == BLACK

        # Test draw
        game.board .= EMPTY
        game.board[1, 1] = BLACK
        game.board[1, 2] = WHITE

        @test get_winner(game) == EMPTY
    end

    @testset "Complete Game Simulation" begin
        # Play a game between two random players
        player1 = RandomPlayer()
        player2 = RandomPlayer()

        winner = play_game(player1, player2, verbose=false)

        @test winner in [BLACK, WHITE, EMPTY]
    end

    @testset "Multiple Random Games" begin
        # Test that games complete successfully
        for i in 1:5
            player1 = RandomPlayer()
            player2 = RandomPlayer()
            winner = play_game(player1, player2, verbose=false)
            @test winner in [BLACK, WHITE, EMPTY]
        end
    end
end
