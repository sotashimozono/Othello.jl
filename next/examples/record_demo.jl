#!/usr/bin/env julia
# record_demo.jl — GameRecord save / load / validate / replay workflow
#
# Usage:
#   julia --project=next next/examples/record_demo.jl

using Reversi
using Reversi: BLACK, WHITE, EMPTY, IN_PROGRESS

println("="^60)
println("GameRecord Demo")
println("="^60)

# ---------------------------------------------------------------------------
# 1. Play a game and save the record
# ---------------------------------------------------------------------------

println("\n1. Playing Random vs Random and saving the record …")

tmp = tempname() * ".txt"
winner = play_game(RandomPlayer(), RandomPlayer();
                   verbose=false, save_record=true, record_path=tmp)

result_str = winner == BLACK ? "Black wins" : winner == WHITE ? "White wins" : "Draw"
println("   Result: $result_str")
println("   Saved  : $tmp")

# ---------------------------------------------------------------------------
# 2. Load and inspect
# ---------------------------------------------------------------------------

println("\n2. Loading the record …")
rec = load_game(tmp)
println("   Moves : $(length(rec.moves))  (first 6: $(join(rec.moves[1:min(6,end)], " ")) …)")
println("   Result: $(rec.result == BLACK ? "BLACK" : rec.result == WHITE ? "WHITE" : "DRAW")")

# ---------------------------------------------------------------------------
# 3. Validate the record before replaying
# ---------------------------------------------------------------------------

println("\n3. Validating move legality …")
err = validate_record(rec)
if err === nothing
    println("   ✓ All moves are legal")
else
    println("   ✗ Invalid move found: $err")
end

# ---------------------------------------------------------------------------
# 4. Replay and verify hash consistency
# ---------------------------------------------------------------------------

println("\n4. Replaying …")
final_state = replay_game(rec; strict=true)
b, w = count_pieces(final_state)
println("   Final board — Black: $b  White: $w")
@assert final_state.hash == compute_full_hash(final_state) "Hash mismatch after replay!"
println("   ✓ Zobrist hash is consistent")

# ---------------------------------------------------------------------------
# 5. Demonstrate load_game error handling
# ---------------------------------------------------------------------------

println("\n5. Error handling …")

# Missing RESULT line
bad = tempname() * ".txt"
write(bad, "MOVES: d3 c3\n")
try
    load_game(bad)
    println("   ✗ Should have thrown!")
catch e
    println("   ✓ Caught $(typeof(e)): $(e.msg[1:min(60,end)])")
end
rm(bad)

# Invalid move in a hand-crafted record
corrupt = GameRecord(["d3", "a1"])   # a1 is illegal after d3
err2 = validate_record(corrupt)
println("   ✓ validate_record caught: $err2")

# strict replay throws
try
    replay_game(corrupt; strict=true)
    println("   ✗ Should have thrown!")
catch e
    println("   ✓ strict replay threw: $(typeof(e))")
end

# ---------------------------------------------------------------------------
# 6. IN_PROGRESS result value
# ---------------------------------------------------------------------------

println("\n6. IN_PROGRESS sentinel …")
partial = GameRecord(["d3", "c3"])            # no result yet
println("   partial.result == IN_PROGRESS : $(partial.result == IN_PROGRESS)")

rm(tmp)
println("\nDone.")
