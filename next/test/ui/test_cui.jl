using Reversi
using Reversi: BLACK, WHITE, EMPTY, valid_moves, make_move!
using Test

# display_board は副作用（stdout 出力）のみなので、出力内容を検査する。

@testset "display_board – contains expected symbols" begin
    game   = ReversiGame()
    output = sprint(io -> redirect_stdout(io) do; display_board(game); end)
    @test occursin("●", output)
    @test occursin("○", output)
    @test occursin("Black", output)
    @test occursin("White", output)
    # Column labels
    for ch in 'a':'h'
        @test occursin(string(ch), output)
    end
end

@testset "display_board – with hints" begin
    game   = ReversiGame()
    hints  = valid_moves(game)
    output = sprint(io -> redirect_stdout(io) do; display_board(game; hints=hints); end)
    @test occursin("*", output)
end

@testset "display_board – no hints shown when hints=[]" begin
    game   = ReversiGame()
    output = sprint(io -> redirect_stdout(io) do; display_board(game; hints=Position[]); end)
    @test !occursin("*", output)
end

@testset "display_board – score reflects board state" begin
    game = ReversiGame()
    make_move!(game, "d3")   # BLACK adds a piece; BLACK=4, WHITE=1

    output = sprint(io -> redirect_stdout(io) do; display_board(game); end)
    @test occursin("4", output)
    @test occursin("1", output)
end
