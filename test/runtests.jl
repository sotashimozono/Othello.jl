ENV["GKSwstype"] = "100"

using Reversi, Test
using Reversi: EMPTY, BLACK, WHITE, opponent, is_valid_position, count_pieces, pass!
using Reversi: compute_full_hash, update_hash, get_piece, next_state, position_to_string

@testset "Reversi.jl" begin
    @testset "Game Initialization" begin
        game = ReversiGame()
        @test get_piece(game, 4, 4) == WHITE
        @test get_piece(game, 4, 5) == BLACK
        @test get_piece(game, 5, 4) == BLACK
        @test get_piece(game, 5, 5) == WHITE
        @test game.current_player == BLACK
        @test game.pass_count == 0
        # Verify incremental hash matches full recomputation
        @test game.hash == compute_full_hash(game)
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

    @testset "Position String Conversion" begin
        @test Position("e4") == Position(4, 5)
        @test Position("a1") == Position(1, 1)
        @test Position("h8") == Position(8, 8)
        @test position_to_string(Position(4, 5)) == "e4"
        @test position_to_string(Position(1, 1)) == "a1"
        @test position_to_string(Position(8, 8)) == "h8"
        @test_throws ArgumentError Position("z9")
        @test_throws ArgumentError Position("e")
    end

    @testset "Valid Moves" begin
        game = ReversiGame()
        moves = valid_moves(game, BLACK)

        # Black should have exactly 4 valid opening moves
        @test length(moves) == 4
        @test Position(3, 4) in moves
        @test Position(4, 3) in moves
        @test Position(5, 6) in moves
        @test Position(6, 5) in moves
    end

    @testset "Make Move" begin
        game = ReversiGame()

        # Black makes a valid move
        @test make_move!(game, 3, 4) == true
        @test get_piece(game, 3, 4) == BLACK
        @test get_piece(game, 4, 4) == BLACK  # White piece flipped
        @test game.current_player == WHITE
        # Hash should stay consistent
        @test game.hash == compute_full_hash(game)

        # Try invalid move
        game2 = ReversiGame()
        @test make_move!(game2, 1, 1) == false
        @test game2.current_player == BLACK  # Turn not changed

        # String notation overload
        game3 = ReversiGame()
        @test make_move!(game3, "d3") == true   # same as (3,4)
        @test get_piece(game3, 3, 4) == BLACK

        # Position overload
        game4 = ReversiGame()
        @test make_move!(game4, Position(3, 4)) == true
    end

    @testset "Piece Counting" begin
        game = ReversiGame()
        black_count, white_count = count_pieces(game)
        @test black_count == 2
        @test white_count == 2

        make_move!(game, 3, 4)
        black_count, white_count = count_pieces(game)
        @test black_count == 4
        @test white_count == 1
    end

    @testset "Pass and Game Over" begin
        game = ReversiGame()
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
        game = ReversiGame()

        # Manually set up a winning position for Black
        game.black = (one(UInt64) << 0) | (one(UInt64) << 1)  # (1,1), (1,2)
        game.white = one(UInt64) << 2                          # (1,3)
        game.hash = compute_full_hash(game)

        @test get_winner(game) == BLACK

        # Test draw
        game.black = one(UInt64) << 0   # (1,1)
        game.white = one(UInt64) << 1   # (1,2)
        game.hash = compute_full_hash(game)

        @test get_winner(game) == EMPTY
    end

    @testset "next_state (copy-on-move)" begin
        game = ReversiGame()
        new_game = next_state(game, Position(3, 4))

        # Original unchanged
        @test get_piece(game, 3, 4) == EMPTY
        @test game.current_player == BLACK

        # New game has the move applied
        @test get_piece(new_game, 3, 4) == BLACK
        @test new_game.current_player == WHITE
        @test new_game.hash == compute_full_hash(new_game)

        # String variant
        new_game2 = next_state(game, "d3")
        @test get_piece(new_game2, 3, 4) == BLACK
    end

    @testset "Zobrist Hash" begin
        game = ReversiGame()
        h0 = game.hash

        make_move!(game, 3, 4)
        h1 = game.hash
        @test h1 != h0
        @test h1 == compute_full_hash(game)

        # update_hash is its own inverse
        @test update_hash(update_hash(h0, 3, 4, BLACK), 3, 4, BLACK) == h0
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

const dirs = []
const FIG_BASE = joinpath(pkgdir(Reversi), "docs", "src", "assets")
const PATHS = Dict()
mkpath.(values(PATHS))

@testset "tests" begin
    test_args = copy(ARGS)
    println("Passed arguments ARGS = $(test_args) to tests.")
    @time for dir in dirs
        dirpath = joinpath(@__DIR__, dir)
        println("\nTest $(dirpath)")
        files = sort(
            filter(f -> startswith(f, "test_") && endswith(f, ".jl"), readdir(dirpath))
        )
        if isempty(files)
            println("  No test files found in $(dirpath).")
            @test false
        else
            for f in files
                @testset "$f" begin
                    filepath = joinpath(dirpath, f)
                    @time begin
                        println("  Including $(filepath)")
                        include(filepath)
                    end
                end
            end
        end
    end
end
