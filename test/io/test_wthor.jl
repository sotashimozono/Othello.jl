using Reversi
using Reversi:
    WThorGame, WThorHeader, read_wthor, write_wthor, wthor_game_to_record, verify_wthor_game
using Reversi:
    BLACK,
    WHITE,
    EMPTY,
    count_pieces,
    make_move!,
    pass!,
    position_to_string,
    valid_moves,
    ReversiGame,
    GameRecord
using Test

# ---------------------------------------------------------------------------
# Move encoding
# ---------------------------------------------------------------------------

@testset "move encoding – known values" begin
    @test Reversi._wthor_byte_to_notation(UInt8(11)) == "a1"
    @test Reversi._wthor_byte_to_notation(UInt8(18)) == "h1"
    @test Reversi._wthor_byte_to_notation(UInt8(81)) == "a8"
    @test Reversi._wthor_byte_to_notation(UInt8(88)) == "h8"
    @test Reversi._wthor_byte_to_notation(UInt8(56)) == "f5"
    @test Reversi._wthor_byte_to_notation(UInt8(34)) == "d3"
    @test Reversi._wthor_byte_to_notation(UInt8(0)) === nothing  # end marker
    @test Reversi._wthor_byte_to_notation(UInt8(99)) === nothing  # out of range

    @test Reversi._notation_to_wthor_byte("a1") == UInt8(11)
    @test Reversi._notation_to_wthor_byte("h8") == UInt8(88)
    @test Reversi._notation_to_wthor_byte("f5") == UInt8(56)
    @test Reversi._notation_to_wthor_byte("d3") == UInt8(34)
end

@testset "move encoding – round-trip all 64 squares" begin
    for row in 1:8, col in 1:8
        notation = string(Char(Int('a') + col - 1)) * string(row)
        byte = UInt8(row * 10 + col)
        @test Reversi._wthor_byte_to_notation(byte) == notation
        @test Reversi._notation_to_wthor_byte(notation) == byte
    end
end

# ---------------------------------------------------------------------------
# File size invariant
# ---------------------------------------------------------------------------

@testset "file layout – sizes" begin
    tmp = tempname() * ".wtb"
    try
        # Empty file: header only
        write_wthor(tmp, WThorGame[])
        @test filesize(tmp) == 16

        # Two games: header + 2 × 68 bytes
        g1 = WThorGame(1, 10, 20, 34, 36, ["f5", "d6", "c5", "f4"])
        g2 = WThorGame(2, 11, 21, 30, 32, ["d3"])
        write_wthor(tmp, [g1, g2])
        @test filesize(tmp) == 16 + 2 * 68
    finally
        isfile(tmp) && rm(tmp)
    end
end

# ---------------------------------------------------------------------------
# Write → Read round-trip (internal games)
# ---------------------------------------------------------------------------

@testset "write/read round-trip – metadata" begin
    moves = ["f5", "d6", "c5", "f4", "e3", "d3", "c4"]
    g = WThorGame(7, 42, 99, 34, 36, moves)
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, [g]; year=2024, month=3, day=15, game_year=2024)
        header, games = read_wthor(tmp)

        @test header.n_games == 1
        @test header.game_year == 2024
        @test header.board_size == 8

        @test games[1].tournament_id == 7
        @test games[1].black_id == 42
        @test games[1].white_id == 99
        @test games[1].black_score == 34
        @test games[1].best_score == 36
        @test games[1].moves == moves
    finally
        isfile(tmp) && rm(tmp)
    end
end

@testset "write/read round-trip – move truncation at 60" begin
    # Generate a full 60-move sequence from a real game
    game = ReversiGame()
    moves = String[]
    while !is_game_over(game) && length(moves) < 60
        ms = valid_moves(game)
        if isempty(ms)
            pass!(game)   # legal pass
        else
            m = rand(ms)
            make_move!(game, m)
            push!(moves, position_to_string(m))
        end
    end

    g = WThorGame(0, 0, 0, 0, 0, moves)
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, [g])
        _, games = read_wthor(tmp)
        @test games[1].moves == moves
        @test filesize(tmp) == 16 + 68
    finally
        isfile(tmp) && rm(tmp)
    end
end

@testset "write/read round-trip – zero padding is clean" begin
    # A short game: only a few moves.  Remaining 60 - n bytes must read as nothing.
    short_moves = ["f5", "d6", "c5"]
    g = WThorGame(0, 0, 0, 0, 0, short_moves)
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, [g])
        raw = read(tmp)
        # Move bytes start at offset 16 (header) + 8 (metadata) = 24
        move_bytes = raw[25:84]          # bytes 25..84 are the 60 move slots
        n = length(short_moves)
        # First n bytes are non-zero
        for i in 1:n
            @test move_bytes[i] != 0x00
        end
        # Remaining bytes are all zero
        for i in (n + 1):60
            @test move_bytes[i] == 0x00
        end
    finally
        isfile(tmp) && rm(tmp)
    end
end

@testset "write/read round-trip – multiple games" begin
    moves1 = ["f5", "d6", "c5", "f4"]
    moves2 = ["d3", "c3"]
    g1 = WThorGame(1, 10, 20, 34, 36, moves1)
    g2 = WThorGame(2, 11, 21, 30, 32, moves2)
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, [g1, g2]; game_year=2001)
        header, games = read_wthor(tmp)
        @test header.n_games == 2
        @test header.game_year == 2001
        @test games[1].moves == moves1
        @test games[2].moves == moves2
    finally
        isfile(tmp) && rm(tmp)
    end
end

@testset "write/read round-trip – empty game list" begin
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, WThorGame[])
        header, games = read_wthor(tmp)
        @test header.n_games == 0
        @test isempty(games)
    finally
        isfile(tmp) && rm(tmp)
    end
end

# ---------------------------------------------------------------------------
# wthor_game_to_record
# ---------------------------------------------------------------------------

@testset "wthor_game_to_record – result mapping" begin
    @test wthor_game_to_record(WThorGame(0, 0, 0, 34, 36, ["f5"])).result == BLACK
    @test wthor_game_to_record(WThorGame(0, 0, 0, 30, 32, ["f5"])).result == WHITE
    @test wthor_game_to_record(WThorGame(0, 0, 0, 32, 32, ["f5"])).result == EMPTY
end

@testset "wthor_game_to_record – moves preserved" begin
    moves = ["f5", "d6", "c5"]
    rec = wthor_game_to_record(WThorGame(0, 0, 0, 34, 36, moves))
    @test rec.moves == moves
    # Mutation of WThorGame.moves must not affect the returned GameRecord
    orig = ["f5", "d6"]
    g = WThorGame(0, 0, 0, 34, 36, orig)
    rec2 = wthor_game_to_record(g)
    push!(orig, "c5")
    @test length(rec2.moves) == 2
end

# ---------------------------------------------------------------------------
# verify_wthor_game
# ---------------------------------------------------------------------------

@testset "verify_wthor_game – valid sequence" begin
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
    @test verify_wthor_game(WThorGame(0, 0, 0, black_score, black_score, moves)) == true
end

@testset "verify_wthor_game – wrong score" begin
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
    @test verify_wthor_game(WThorGame(0, 0, 0, black_score + 5, black_score, moves)) ==
        false
end

@testset "verify_wthor_game – invalid move" begin
    @test verify_wthor_game(WThorGame(0, 0, 0, 32, 32, ["a1"])) == false
end

# ---------------------------------------------------------------------------
# Full pipeline: play game → save as WTHOR → reload → verify
# ---------------------------------------------------------------------------

@testset "full pipeline: play → write_wthor → read_wthor → verify" begin
    # Play a complete random game and capture the moves
    game = ReversiGame()
    moves = String[]
    while !is_game_over(game)
        ms = valid_moves(game)
        if isempty(ms)
            pass!(game; force=true)
            # passes are not representable in WTHOR; skip recording
        else
            m = rand(ms)
            make_move!(game, m)
            push!(moves, position_to_string(m))
        end
    end
    black_score, _ = count_pieces(game)

    g = WThorGame(0, 1, 2, black_score, black_score, moves)
    tmp = tempname() * ".wtb"
    try
        write_wthor(tmp, [g]; game_year=2024)
        @test isfile(tmp)
        @test filesize(tmp) == 16 + 68

        _, loaded = read_wthor(tmp)
        @test length(loaded) == 1
        @test loaded[1].moves == moves
        @test loaded[1].black_score == black_score

        @test verify_wthor_game(loaded[1]) == true
    finally
        isfile(tmp) && rm(tmp)
    end
end

# ---------------------------------------------------------------------------
# Helper: replay WTHOR moves with automatic passing.
#
# WTHOR does not encode passes; they must be inferred during replay.
# When the current player has no valid moves before a recorded move,
# they are auto-passed until they do (or the game is over).
# This mirrors how real WTHOR databases are replayed.
# ---------------------------------------------------------------------------

function _replay_wthor_moves(moves::Vector{String})::ReversiGame
    game = ReversiGame()
    for m in moves
        # Auto-pass the current player if they have no valid moves
        while isempty(valid_moves(game)) && !is_game_over(game)
            pass!(game; force=true)
        end
        ok = make_move!(game, m)
        ok || error("Invalid WTHOR move \"$m\" during replay")
    end
    # Auto-pass at the tail end (e.g. if the last few moves left no response)
    while isempty(valid_moves(game)) && !is_game_over(game)
        pass!(game; force=true)
    end
    return game
end

# ---------------------------------------------------------------------------
# Reproducibility: 5 random complete games, batched in one WTHOR file
# ---------------------------------------------------------------------------

@testset "complete game reproducibility – 5 random games" begin
    N = 5
    # ref_boards[i] = (black_bb, white_bb) of game i after all moves
    ref_boards = Tuple{UInt64,UInt64}[]
    wthor_games = WThorGame[]

    for trial in 1:N
        ref = ReversiGame()
        moves = String[]

        while !is_game_over(ref)
            ms = valid_moves(ref)
            if isempty(ms)
                pass!(ref; force=true)   # pass not recorded in WTHOR
            else
                m = rand(ms)
                make_move!(ref, m)
                push!(moves, position_to_string(m))
            end
        end

        black_score, _ = count_pieces(ref)
        push!(ref_boards, (ref.black, ref.white))
        push!(
            wthor_games, WThorGame(trial, trial, trial + 1, black_score, black_score, moves)
        )
    end

    tmp = tempname() * ".wtb"
    try
        # --- Write all N games into one file ---
        write_wthor(tmp, wthor_games; game_year=2024)

        @test isfile(tmp)
        @test filesize(tmp) == 16 + N * 68

        # --- Read back ---
        header, loaded = read_wthor(tmp)
        @test header.n_games == N
        @test length(loaded) == N

        # --- Verify each game ---
        for i in 1:N
            g = loaded[i]

            # Move list is preserved verbatim
            @test g.moves == wthor_games[i].moves

            # Score field survives the round-trip
            @test g.black_score == wthor_games[i].black_score

            # verify_wthor_game: replay moves and compare final black disc count
            @test verify_wthor_game(g) == true

            # Deeper check: replay moves with auto-passing and compare full board
            replayed = _replay_wthor_moves(g.moves)
            ref_black, ref_white = ref_boards[i]
            @test replayed.black == ref_black
            @test replayed.white == ref_white
        end

    finally
        isfile(tmp) && rm(tmp)
    end
end
