ENV["GKSwstype"] = "100"

using Reversi, Test
using Reversi: EMPTY, BLACK, WHITE, opponent, is_valid_position, count_pieces, pass!
using Reversi: compute_full_hash, update_hash, get_piece, next_state, position_to_string
using Reversi: GameRecord, save_game, load_game, replay_game

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
        # All other squares are empty at start
        @test get_piece(game, 1, 1) == EMPTY
        @test get_piece(game, 8, 8) == EMPTY
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
        @test is_valid_position(0, 0) == false
        @test is_valid_position(4, 4) == true
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
        # All 8 columns are parsed correctly
        @test Position("a1").col == 1
        @test Position("b1").col == 2
        @test Position("c1").col == 3
        @test Position("d1").col == 4
        @test Position("h1").col == 8
        # Round-trip: string → Position → string
        for col_ch in 'a':'h', row_ch in '1':'8'
            s = string(col_ch) * string(row_ch)
            @test position_to_string(Position(s)) == s
        end
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

        # White's opening moves are also exactly 4 and symmetric
        white_moves = valid_moves(game, WHITE)
        @test length(white_moves) == 4
        @test Position(3, 5) in white_moves
        @test Position(4, 6) in white_moves
        @test Position(5, 3) in white_moves
        @test Position(6, 4) in white_moves
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
        @test game.pass_count == 0

        # Try invalid move (occupied square)
        @test make_move!(game, 3, 4) == false
        @test game.current_player == WHITE  # Turn not changed

        # Try invalid move (out-of-board corner for empty game)
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

    @testset "Flip Verification" begin
        # After Black plays d3 (3,4), the piece at d4 (4,4) must flip to BLACK
        game = ReversiGame()
        @test get_piece(game, 4, 4) == WHITE
        make_move!(game, 3, 4)
        @test get_piece(game, 4, 4) == BLACK
        black_count, white_count = count_pieces(game)
        # After d3 (new BLACK) + d4 flips to BLACK: BLACK has d3,d4,e4; WHITE has e5
        @test black_count == 4
        @test white_count == 1

        # White's only valid moves at this point are c3, e3, c5
        white_moves = valid_moves(game, WHITE)
        @test Position(3, 3) in white_moves
        @test Position(3, 5) in white_moves
        @test Position(5, 3) in white_moves

        # After White plays c3 (3,3), the diagonal piece at d4 (4,4) flips back to WHITE
        make_move!(game, 3, 3)
        @test get_piece(game, 3, 3) == WHITE
        @test get_piece(game, 4, 4) == WHITE  # flipped back along NW-SE diagonal
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

    @testset "Game Over – Full Board" begin
        game = ReversiGame()
        # Fill the entire board: game_over must be true
        game.black = typemax(UInt64)
        game.white = zero(UInt64)
        @test is_game_over(game) == true
        @test get_winner(game) == BLACK

        game.white = typemax(UInt64)
        game.black = zero(UInt64)
        @test is_game_over(game) == true
        @test get_winner(game) == WHITE
    end

    @testset "Winner Detection" begin
        game = ReversiGame()

        # Manually set up a winning position for Black
        game.black = (one(UInt64) << 0) | (one(UInt64) << 1)  # (1,1), (1,2)
        game.white = one(UInt64) << 2                          # (1,3)
        game.hash = compute_full_hash(game)

        @test get_winner(game) == BLACK

        # White wins
        game.black = one(UInt64) << 0   # (1,1)
        game.white = (one(UInt64) << 1) | (one(UInt64) << 2)  # (1,2), (1,3)
        game.hash = compute_full_hash(game)
        @test get_winner(game) == WHITE

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

        # Chained next_state calls must not affect each other
        new_game3 = next_state(game, "d3")
        @test new_game3.hash == new_game.hash
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

        # Hash consistency throughout a sequence of moves
        for move_str in ("c3", "b3", "b2", "b1")
            make_move!(game, move_str)
            @test game.hash == compute_full_hash(game)
        end

        # Two independent games with the same move sequence share the same hash
        g1 = ReversiGame()
        g2 = ReversiGame()
        for move_str in ("d3", "c3", "b3")
            make_move!(g1, move_str)
            make_move!(g2, move_str)
        end
        @test g1.hash == g2.hash
    end

    @testset "display_board smoke test" begin
        game = ReversiGame()
        # Should run without throwing any exception
        tmp = tempname()
        open(tmp, "w") do f
            redirect_stdout(f) do
                display_board(game)
                display_board(game; hints=valid_moves(game))
            end
        end
        output = read(tmp, String)
        rm(tmp)
        @test occursin("●", output)
        @test occursin("○", output)
        @test occursin("Black", output)
        @test occursin("White", output)
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

    @testset "Hash Consistency – Full Random Games" begin
        for _ in 1:3
            g = ReversiGame()
            while !is_game_over(g)
                moves = valid_moves(g)
                if isempty(moves)
                    pass!(g)
                else
                    make_move!(g, rand(moves))
                end
            end
            @test g.hash == compute_full_hash(g)
        end
    end

    @testset "GameRecord – save and load" begin
        moves = ["d3", "c3", "b3", "b2"]
        record = GameRecord(moves, BLACK)

        tmp = tempname() * ".txt"
        try
            save_game(record, tmp)
            loaded = load_game(tmp)
            @test loaded.moves == moves
            @test loaded.result == BLACK
        finally
            isfile(tmp) && rm(tmp)
        end

        # Draw result round-trips
        draw_record = GameRecord(["d3"], EMPTY)
        tmp2 = tempname() * ".txt"
        try
            save_game(draw_record, tmp2)
            loaded2 = load_game(tmp2)
            @test loaded2.result == EMPTY
        finally
            isfile(tmp2) && rm(tmp2)
        end
    end

    @testset "GameRecord – replay" begin
        moves = ["d3", "c3", "b3"]
        record = GameRecord(moves, 2)
        replayed = replay_game(record)

        # Apply the same moves manually and compare final state
        ref = ReversiGame()
        for m in moves
            make_move!(ref, m)
        end
        @test replayed.black == ref.black
        @test replayed.white == ref.white
        @test replayed.current_player == ref.current_player
        @test replayed.hash == ref.hash
    end

    @testset "play_game with save_record" begin
        tmp = tempname() * ".txt"
        try
            winner = play_game(
                RandomPlayer(),
                RandomPlayer();
                verbose=false,
                save_record=true,
                record_path=tmp,
            )
            @test winner in [BLACK, WHITE, EMPTY]
            @test isfile(tmp)
            rec = load_game(tmp)
            # Re-playing the record must reproduce a consistent hash
            replayed = replay_game(rec)
            @test replayed.hash == compute_full_hash(replayed)
        finally
            isfile(tmp) && rm(tmp)
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
