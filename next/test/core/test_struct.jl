using Reversi
using Reversi: EMPTY, BLACK, WHITE, IN_PROGRESS, _color_idx
using Reversi: compute_full_hash, update_hash, get_piece
using Test

@testset "constants" begin
    @test BLACK       ==  1
    @test WHITE       == -1
    @test EMPTY       ==  0
    @test IN_PROGRESS ==  2
    @test _color_idx(BLACK) == 1
    @test _color_idx(WHITE) == 2
end

@testset "Position – parse" begin
    @test Position("e4") == Position(4, 5)
    @test Position("a1") == Position(1, 1)
    @test Position("h8") == Position(8, 8)
    @test_throws ArgumentError Position("z9")
    @test_throws ArgumentError Position("e")
    @test_throws ArgumentError Position("e9")
    @test_throws ArgumentError Position("i4")
end

@testset "Position – to string" begin
    @test position_to_string(Position(4, 5)) == "e4"
    @test position_to_string(Position(1, 1)) == "a1"
    @test position_to_string(Position(8, 8)) == "h8"
end

@testset "Position – round-trip all 64 squares" begin
    for col_ch in 'a':'h', row_ch in '1':'8'
        s = string(col_ch) * string(row_ch)
        @test position_to_string(Position(s)) == s
    end
end

@testset "ReversiGame – initial state" begin
    game = ReversiGame()
    @test get_piece(game, 4, 4) == WHITE
    @test get_piece(game, 4, 5) == BLACK
    @test get_piece(game, 5, 4) == BLACK
    @test get_piece(game, 5, 5) == WHITE
    @test game.current_player == BLACK
    @test game.pass_count == 0
    @test game.hash == compute_full_hash(game)
    # All other squares empty
    @test get_piece(game, 1, 1) == EMPTY
    @test get_piece(game, 8, 8) == EMPTY
end

@testset "Base.copy(game)" begin
    game = ReversiGame()
    c    = copy(game)
    @test c.black          == game.black
    @test c.white          == game.white
    @test c.current_player == game.current_player
    @test c.pass_count     == game.pass_count
    @test c.hash           == game.hash
    # Mutating the copy must not affect the original
    c.black = zero(UInt64)
    @test game.black != zero(UInt64)
end

@testset "Zobrist – update_hash is self-inverse" begin
    game = ReversiGame()
    h0   = game.hash
    h1   = update_hash(h0, 3, 4, BLACK)
    @test h1 != h0
    @test update_hash(h1, 3, 4, BLACK) == h0
end

@testset "Zobrist – compute_full_hash consistency" begin
    game = ReversiGame()
    make_move!(game, "d3")
    @test game.hash == compute_full_hash(game)
end
