using Reversi
using Reversi: BLACK, WHITE, EMPTY
using Test

@testset "opening book – build from synthetic WTHOR" begin
    mktempdir() do dir
        path = joinpath(dir, "test.wtb")
        # Three games sharing the first move, diverging afterwards
        games = [
            WThorGame(0, 0, 0, 40, 40, ["f5", "d6", "c5", "f4", "e3"]),  # black win
            WThorGame(0, 0, 0, 24, 24, ["f5", "f6", "e6", "f4", "g5"]),  # white win
            WThorGame(0, 0, 0, 32, 32, ["f5", "d6", "c3", "d3", "c4"]),  # draw
        ]
        write_wthor(path, games)

        book = build_opening_book(path; max_depth=10)
        @test book.game_count == 3
        @test length(book.entries) > 0
        @test book.max_depth == 10
        @test book.source_file == path

        # Root position: all 3 games go through it and all played f5
        root = lookup_opening(book, ReversiGame())
        @test root !== nothing
        @test root.total == 3
        @test root.black_wins == 1
        @test root.white_wins == 1
        @test root.draws == 1
        @test root.next_moves == Dict("f5" => 3)
    end
end

@testset "opening book – lookup miss" begin
    mktempdir() do dir
        path = joinpath(dir, "test.wtb")
        write_wthor(path, [WThorGame(0, 0, 0, 40, 40, ["f5", "d6", "c5"])])
        book = build_opening_book(path; max_depth=5)

        # Play a legal but different opening (d3) — not in synthetic book
        game = ReversiGame()
        make_move!(game, 3, 4)  # d3
        @test lookup_opening(book, game) === nothing

        dict = opening_book_lookup_dict(book, game)
        @test dict["found"] == false
    end
end

@testset "opening book – save/load round-trip" begin
    mktempdir() do dir
        path = joinpath(dir, "test.wtb")
        write_wthor(path, [WThorGame(0, 0, 0, 40, 40, ["f5", "d6", "c5"])])
        book = build_opening_book(path; max_depth=10)

        save_path = joinpath(dir, "book.jls")
        save_opening_book(book, save_path)
        loaded = load_opening_book(save_path)

        @test length(loaded.entries) == length(book.entries)
        @test loaded.game_count == book.game_count
        @test loaded.source_file == book.source_file

        # Round-trip lookup should return equivalent data
        orig_root = lookup_opening(book, ReversiGame())
        loaded_root = lookup_opening(loaded, ReversiGame())
        @test orig_root.total == loaded_root.total
        @test orig_root.next_moves == loaded_root.next_moves
    end
end

@testset "opening book – lookup dict has sorted candidates" begin
    mktempdir() do dir
        path = joinpath(dir, "test.wtb")
        # 5 games with different opening splits after f5
        games = [
            WThorGame(0, 0, 0, 40, 40, ["f5", "d6", "c5"]),
            WThorGame(0, 0, 0, 24, 24, ["f5", "d6", "c4"]),
            WThorGame(0, 0, 0, 32, 32, ["f5", "d6", "c3"]),
            WThorGame(0, 0, 0, 40, 40, ["f5", "f6", "e6"]),
            WThorGame(0, 0, 0, 32, 32, ["f5", "f4", "e3"]),
        ]
        write_wthor(path, games)
        book = build_opening_book(path; max_depth=10)

        # After f5 is played, the current player is white. Check the candidates.
        game = ReversiGame()
        make_move!(game, 5, 6)  # f5 → black to white's turn
        dict = opening_book_lookup_dict(book, game)
        @test dict["found"] == true
        @test dict["total"] == 5
        # Candidates sorted by count desc: d6 (3), f6 (1), f4 (1)
        @test dict["candidates"][1]["move"] == "d6"
        @test dict["candidates"][1]["count"] == 3
    end
end
