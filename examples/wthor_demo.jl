#!/usr/bin/env julia
# wthor_demo.jl — WTHOR binary format: write, read, and verify
#
# Demonstrates both sides of WTHOR I/O:
#   A. Internally generated games  → write_wthor → read_wthor → verify
#   B. Externally downloaded games → read_wthor  → verify (optional)
#
# Usage:
#   julia --project=next next/examples/wthor_demo.jl
#
# To verify a real WTHOR file from the FFO database, set WTHOR_PATH:
#   WTHOR_PATH=WTH_2001.wtb julia --project=next next/examples/wthor_demo.jl

using Reversi

println("="^60)
println("WTHOR Demo")
println("="^60)

# ---------------------------------------------------------------------------
# Helper: play one full random game; return (WThorGame, final board)
# ---------------------------------------------------------------------------

function play_to_wthor(id::Int)
    game = ReversiGame()
    moves = String[]
    while !is_game_over(game)
        ms = valid_moves(game)
        if isempty(ms)
            pass!(game; force=true)   # pass is NOT recorded in WTHOR
        else
            m = rand(ms)
            make_move!(game, m)
            push!(moves, position_to_string(m))
        end
    end
    b, _ = count_pieces(game)
    return WThorGame(id, id, id + 1, b, b, moves), (game.black, game.white)
end

# ---------------------------------------------------------------------------
# A. Internal round-trip: play N games, write, read, verify
# ---------------------------------------------------------------------------

println("\nA. Internal round-trip (5 random games)")
println("-"^40)

N = 5
games_out = WThorGame[]
ref_boards = Tuple{UInt64,UInt64}[]

for i in 1:N
    g, board = play_to_wthor(i)
    push!(games_out, g)
    push!(ref_boards, board)
end

tmp = tempname() * ".wtb"
try
    write_wthor(tmp, games_out; year=2024, game_year=2024)
    expected_size = 16 + N * 68
    actual_size = filesize(tmp)
    size_ok = actual_size == expected_size
    println(
        "  File size : $actual_size bytes  (expected $expected_size)  $(size_ok ? "✓" : "✗")",
    )

    header, games_in = read_wthor(tmp)
    println("  n_games   : $(header.n_games)  $(header.n_games == N ? "✓" : "✗")")

    all_ok = true
    for i in 1:N
        g = games_in[i]
        moves_match = g.moves == games_out[i].moves
        score_match = g.black_score == games_out[i].black_score
        verify_ok = verify_wthor_game(g)

        # Deep board comparison via auto-pass replay
        replayed = ReversiGame()
        for m in g.moves
            while isempty(valid_moves(replayed)) && !is_game_over(replayed)
                pass!(replayed; force=true)
            end
            make_move!(replayed, m)
        end
        while isempty(valid_moves(replayed)) && !is_game_over(replayed)
            pass!(replayed; force=true)
        end
        board_match =
            replayed.black == ref_boards[i][1] && replayed.white == ref_boards[i][2]

        ok = moves_match && score_match && verify_ok && board_match
        all_ok &= ok
        status = ok ? "✓" : "✗"
        println("  Game $i: $(length(g.moves)) moves  score=$(g.black_score)  $status")
    end
    println("  → All games reproduced correctly: $(all_ok ? "✓" : "✗")")
finally
    isfile(tmp) && rm(tmp)
end

# ---------------------------------------------------------------------------
# B. External WTHOR file (optional)
# ---------------------------------------------------------------------------

println("\nB. External WTHOR file")
println("-"^40)

wthor_path = get(ENV, "WTHOR_PATH", "")

if isempty(wthor_path) || !isfile(wthor_path)
    println("  Skipped (set WTHOR_PATH=<path>.wtb to enable)")
    println()
    println("  Example:")
    println("    using Downloads")
    println(
        "    Downloads.download(\"https://www.ffothello.org/wthor/base/WTH_2001.wtb\", \"WTH_2001.wtb\")",
    )
    println("    WTHOR_PATH=WTH_2001.wtb julia --project=next next/examples/wthor_demo.jl")
else
    header, games = read_wthor(wthor_path)
    gy = header.game_year
    println("  File      : $wthor_path")
    println("  Games     : $(header.n_games)  (year $gy)")
    println("  Board     : $(header.board_size)×$(header.board_size)")

    check_n = min(200, length(games))
    ok = sum(verify_wthor_game(g) for g in games[1:check_n])
    pct = round(ok / check_n * 100; digits=1)
    println("  Verify $check_n: $ok / $check_n pass  ($pct%)")

    # Round-trip: write a subset back out and compare
    sub = games[1:min(50, end)]
    tmp2 = tempname() * ".wtb"
    try
        write_wthor(tmp2, sub; game_year=gy)
        _, reloaded = read_wthor(tmp2)
        mismatch = sum(reloaded[i].moves != sub[i].moves for i in eachindex(sub))
        println(
            "  Round-trip ($(length(sub)) games): $(mismatch == 0 ? "✓ all match" : "✗ $mismatch mismatches")",
        )
    finally
        isfile(tmp2) && rm(tmp2)
    end
end

println("\nDone.")
