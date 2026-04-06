#!/usr/bin/env julia
# Standalone WTHOR IO verification (no GLMakie needed)
using Reversi
using Reversi: WThorGame, WThorHeader, read_wthor, write_wthor,
               wthor_game_to_record, verify_wthor_game
using Reversi: BLACK, WHITE, EMPTY, count_pieces, make_move!, pass!, position_to_string,
               valid_moves, ReversiGame, GameRecord
using Test

@testset "WTHOR move encoding" begin
    @test Reversi._wthor_byte_to_notation(UInt8(11)) == "a1"
    @test Reversi._wthor_byte_to_notation(UInt8(88)) == "h8"
    @test Reversi._wthor_byte_to_notation(UInt8(56)) == "f5"
    @test Reversi._wthor_byte_to_notation(UInt8(34)) == "d3"
    @test Reversi._wthor_byte_to_notation(UInt8(18)) == "h1"
    @test Reversi._wthor_byte_to_notation(UInt8(81)) == "a8"
    @test Reversi._wthor_byte_to_notation(UInt8(0))  === nothing
    @test Reversi._wthor_byte_to_notation(UInt8(99)) === nothing

    @test Reversi._notation_to_wthor_byte("a1") == UInt8(11)
    @test Reversi._notation_to_wthor_byte("h8") == UInt8(88)
    @test Reversi._notation_to_wthor_byte("f5") == UInt8(56)
    @test Reversi._notation_to_wthor_byte("d3") == UInt8(34)
    @test Reversi._notation_to_wthor_byte("h1") == UInt8(18)
    @test Reversi._notation_to_wthor_byte("a8") == UInt8(81)

    # Round-trip all 64 squares
    for row in 1:8, col in 1:8
        notation = string(Char(Int('a') + col - 1)) * string(row)
        byte = UInt8(row * 10 + col)
        @test Reversi._wthor_byte_to_notation(byte) == notation
        @test Reversi._notation_to_wthor_byte(notation) == byte
    end
end

@testset "WTHOR write/read round-trip" begin
    moves1 = ["f5", "d6", "c5", "f4", "e3", "d3", "c4"]
    moves2 = ["d3", "c4", "c3"]

    g1 = WThorGame(1, 10, 20, 34, 36, moves1)
    g2 = WThorGame(2, 11, 21, 30, 32, moves2)

    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, [g1, g2]; year=2024, game_year=2001)
        @test isfile(tmp)

        # Header should be exactly 16 bytes + 2*68 = 152 bytes total
        @test filesize(tmp) == 16 + 2 * 68

        header, games = read_wthor(tmp)
        @test header.n_games    == 2
        @test header.game_year  == 2001
        @test header.board_size == 8
        @test length(games)     == 2

        @test games[1].tournament_id == 1
        @test games[1].black_id      == 10
        @test games[1].white_id      == 20
        @test games[1].black_score   == 34
        @test games[1].best_score    == 36
        @test games[1].moves         == moves1

        @test games[2].moves         == moves2
        @test games[2].black_score   == 30
    finally
        isfile(tmp) && rm(tmp)
    end
end

@testset "WTHOR empty file" begin
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, WThorGame[])
        @test filesize(tmp) == 16
        header, games = read_wthor(tmp)
        @test header.n_games == 0
        @test isempty(games)
    finally
        isfile(tmp) && rm(tmp)
    end
end

@testset "wthor_game_to_record" begin
    @test wthor_game_to_record(WThorGame(0,0,0, 34, 36, ["f5"])).result == BLACK
    @test wthor_game_to_record(WThorGame(0,0,0, 30, 32, ["f5"])).result == WHITE
    @test wthor_game_to_record(WThorGame(0,0,0, 32, 32, ["f5"])).result == EMPTY
    @test wthor_game_to_record(WThorGame(0,0,0, 34, 36, ["f5","d6"])).moves == ["f5","d6"]
end

@testset "verify_wthor_game" begin
    # Build a real, valid game sequence and check verify returns true
    game = ReversiGame()
    moves = String[]
    for _ in 1:10
        ms = valid_moves(game)
        isempty(ms) && (pass!(game); continue)
        m = first(ms)
        make_move!(game, m)
        push!(moves, position_to_string(m))
    end
    black_score, _ = count_pieces(game)
    @test verify_wthor_game(WThorGame(0,0,0, black_score, black_score, moves)) == true
    @test verify_wthor_game(WThorGame(0,0,0, black_score+3, black_score, moves)) == false
    # Invalid move at start → false
    @test verify_wthor_game(WThorGame(0,0,0, 32, 32, ["a1"])) == false
end

println("\nAll WTHOR tests passed!")
