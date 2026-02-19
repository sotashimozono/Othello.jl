# # Zobrist Hashing in Reversi.jl
#
# ## Overview
#
# [Zobrist hashing](https://en.wikipedia.org/wiki/Zobrist_hashing) is a
# technique for efficiently computing a nearly-unique integer fingerprint of a
# board position.  `Reversi.jl` keeps an **incremental** Zobrist hash in every
# `ReversiGame` object so that identifying positions and detecting transpositions
# in game-tree search costs almost nothing.

using Reversi
using Reversi: BLACK, WHITE, EMPTY, compute_full_hash, update_hash, ZOBRIST_TABLE

# ## 1. Initial hash
#
# Every `ReversiGame` is created with its `hash` field already set to the
# Zobrist hash of the four starting pieces.

game = ReversiGame()
println("Initial incremental hash : 0x", string(game.hash; base=16, pad=16))
println("Full recomputed hash      : 0x", string(compute_full_hash(game); base=16, pad=16))
@assert game.hash == compute_full_hash(game)

# ## 2. Hash after a move
#
# After each `make_move!` call the hash is updated **incrementally** — only the
# newly placed piece and the flipped pieces are XOR-ed in or out.  The result
# must always match `compute_full_hash`.

make_move!(game, "d3")   # Black plays d3
println("\nAfter d3:")
println("Incremental hash : 0x", string(game.hash; base=16, pad=16))
println("Full hash        : 0x", string(compute_full_hash(game); base=16, pad=16))
@assert game.hash == compute_full_hash(game)

# ## 3. XOR self-inverse property
#
# Toggling the same piece twice returns the original hash — a direct consequence
# of XOR being its own inverse.

h0 = compute_full_hash(ReversiGame())
h1 = update_hash(h0, 3, 4, BLACK)   # add a piece
h2 = update_hash(h1, 3, 4, BLACK)   # remove the same piece
println("\nOriginal hash    : 0x", string(h0; base=16, pad=16))
println("After toggle ×2  : 0x", string(h2; base=16, pad=16))
@assert h0 == h2 "XOR inverse property failed!"

# ## 4. Position lookup / transposition detection
#
# Because the hash is cheap to maintain, it is ideal for **transposition
# tables**: a dictionary from hash → evaluation that avoids re-searching the
# same position reached via different move orders.

transposition_table = Dict{UInt64,Int}()

function cached_piece_diff(game::ReversiGame)::Int
    haskey(transposition_table, game.hash) && return transposition_table[game.hash]
    black, white = count_pieces(game)
    val = black - white
    transposition_table[game.hash] = val
    return val
end

g1 = ReversiGame()
make_move!(g1, "d3");
make_move!(g1, "c5")

g2 = ReversiGame()
make_move!(g2, "d3");
make_move!(g2, "c5")

println("\nHash of g1: 0x", string(g1.hash; base=16, pad=16))
println("Hash of g2: 0x", string(g2.hash; base=16, pad=16))
@assert g1.hash == g2.hash "Same move sequence must yield same hash!"

val1 = cached_piece_diff(g1)
val2 = cached_piece_diff(g2)   # cache hit
println("Cached piece diff: $val1  (table size: $(length(transposition_table)))")
@assert val1 == val2

println("\nZobrist hashing demo complete.")
