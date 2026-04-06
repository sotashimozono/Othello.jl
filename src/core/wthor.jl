
# ---------------------------------------------------------------------------
# WTHOR (.wtb) Binary Format I/O
#
# WTHOR is the standard database format for professional Othello/Reversi games,
# maintained by the Fédération Française d'Othello (FFO).
# Files: https://www.ffothello.org/wthor/base/WTH_YYYY.wtb
#
# Header layout (16 bytes, all integers little-endian):
#   Byte 0      : file-creation century (e.g. 20)
#   Byte 1      : year within century   (e.g. 1 for 2001)
#   Byte 2      : month
#   Byte 3      : day
#   Bytes 4-7   : n_games   (Int32 LE)
#   Bytes 8-9   : count     (Int16 LE, equals n_games for .wtb files)
#   Bytes 10-11 : game_year (Int16 LE)  ← 2-byte field!
#   Byte 12     : board_size (8 for standard Othello)
#   Byte 13     : game_type
#   Byte 14     : depth
#   Byte 15     : reserved
#
# Game record layout (68 bytes each):
#   Bytes 0-1   : tournament_id  (Int16 LE)
#   Bytes 2-3   : black_id       (Int16 LE)
#   Bytes 4-5   : white_id       (Int16 LE)
#   Byte 6      : black_score    (UInt8 — actual black disc count)
#   Byte 7      : best_score     (UInt8 — theoretical best for black)
#   Bytes 8-67  : moves          (60 × UInt8, 0 = end)
#
# Move encoding: byte = row * 10 + col  (row 1-8, col 1-8 where col a=1 … h=8)
#   e.g.  a1=11, h1=18, a8=81, h8=88, f5=56
#
# References (Qiita article, Japanese):
#   https://qiita.com/tanaka-a/items/c7beeba7e6f88d7ff42b
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

"""
    WThorHeader

Metadata from the 16-byte header of a `.wtb` WTHOR database file.
"""
struct WThorHeader
    created_century::Int   # e.g. 20 for 2000s
    created_year::Int      # year within century (0-99)
    created_month::Int
    created_day::Int
    n_games::Int           # number of game records
    game_year::Int         # year of the games (Int16 in file)
    board_size::Int        # always 8 for standard Othello
    game_type::Int
    depth::Int             # search depth for theoretical scores
end

"""
    WThorGame

One game record from a `.wtb` WTHOR database file.
"""
struct WThorGame
    tournament_id::Int
    black_id::Int
    white_id::Int
    black_score::Int    # actual score (black disc count, 0-64)
    best_score::Int     # theoretical best score for black
    moves::Vector{String}   # standard notation ("f5", "d6", …)
end

# ---------------------------------------------------------------------------
# Move encoding helpers
# ---------------------------------------------------------------------------

"""
    _wthor_byte_to_notation(b::UInt8) -> Union{String, Nothing}

Decode one WTHOR move byte to standard Othello notation.
Encoding: `byte = row * 10 + col`  (row 1-8, col 1-8 where a=1,…,h=8).
Returns `nothing` for 0x00 (end-of-game / unused slot).
"""
function _wthor_byte_to_notation(b::UInt8)
    b == 0x00 && return nothing
    row = div(Int(b), 10)
    col = mod(Int(b), 10)
    (1 <= row <= 8 && 1 <= col <= 8) || return nothing
    return string(Char(Int('a') + col - 1)) * string(row)
end

"""
    _notation_to_wthor_byte(s::AbstractString) -> UInt8

Encode standard Othello notation to a WTHOR move byte.
"""
function _notation_to_wthor_byte(s::AbstractString)
    length(s) == 2 || throw(ArgumentError("Expected 2-char notation, got: $s"))
    col = Int(lowercase(s[1])) - Int('a') + 1
    row = parse(Int, string(s[2]))
    (1 <= row <= 8 && 1 <= col <= 8) || throw(ArgumentError("Position out of range: $s"))
    return UInt8(row * 10 + col)
end

# ---------------------------------------------------------------------------
# Reading
# ---------------------------------------------------------------------------

"""
    read_wthor(path::String) -> (WThorHeader, Vector{WThorGame})

Parse a WTHOR `.wtb` binary file.

# Example
```julia
header, games = read_wthor("WTH_2001.wtb")
println("Games: \$(header.n_games), year: \$(header.game_year)")
println("First 4 moves: \$(games[1].moves[1:4])")
```
"""
function read_wthor(path::String)
    data = read(path)
    length(data) < 16 && error("File too short to contain a WTHOR header: $path")

    io = IOBuffer(data)

    # ---- Header (16 bytes) ----
    century    = Int(read(io, UInt8))   # byte 0
    yr         = Int(read(io, UInt8))   # byte 1
    month      = Int(read(io, UInt8))   # byte 2
    day        = Int(read(io, UInt8))   # byte 3
    n_games    = Int(read(io, Int32))   # bytes 4-7  (Int32 LE)
    _           = read(io, Int16)       # bytes 8-9  (Int16 LE, same as n_games)
    game_year  = Int(read(io, Int16))   # bytes 10-11 (Int16 LE) ← 2-byte field!
    board_size = Int(read(io, UInt8))   # byte 12
    game_type  = Int(read(io, UInt8))   # byte 13
    depth      = Int(read(io, UInt8))   # byte 14
    _           = read(io, UInt8)       # byte 15 (reserved)

    header = WThorHeader(century, yr, month, day, n_games, game_year, board_size, game_type, depth)

    # ---- Game records (68 bytes each) ----
    n_available = div(length(data) - 16, 68)
    if n_available < n_games
        @warn "File has $(n_available) records but header declares $(n_games). Reading available."
    end

    games = WThorGame[]
    sizehint!(games, n_available)

    for _ in 1:n_available
        tourn    = Int(read(io, Int16))   # 2 bytes
        black_id = Int(read(io, Int16))   # 2 bytes
        white_id = Int(read(io, Int16))   # 2 bytes
        b_score  = Int(read(io, UInt8))   # 1 byte
        t_score  = Int(read(io, UInt8))   # 1 byte
        raw      = read(io, 60)           # 60 bytes of moves

        moves = String[]
        for b in raw
            m = _wthor_byte_to_notation(b)
            m === nothing && break
            push!(moves, m)
        end
        push!(games, WThorGame(tourn, black_id, white_id, b_score, t_score, moves))
    end

    return header, games
end

# ---------------------------------------------------------------------------
# Writing
# ---------------------------------------------------------------------------

"""
    write_wthor(path::String, games::Vector{WThorGame};
                year::Int=0, month::Int=1, day::Int=1,
                game_year::Int=0, game_type::Int=0, depth::Int=0)

Write `games` to `path` in WTHOR binary format.
"""
function write_wthor(
    path::String,
    games::Vector{WThorGame};
    year::Int      = 0,
    month::Int     = 1,
    day::Int       = 1,
    game_year::Int = 0,
    game_type::Int = 0,
    depth::Int     = 0,
)
    n        = length(games)
    century  = div(year, 100)
    yr_in_c  = mod(year, 100)

    # Build into an IOBuffer first, then write atomically as binary.
    # Do NOT use open(path, "w") on Windows — text mode converts \n to \r\n
    # and corrupts binary data.
    buf = IOBuffer()

    # Header (16 bytes)
    write(buf, UInt8(century), UInt8(yr_in_c), UInt8(month), UInt8(day))  # 4
    write(buf, Int32(n))           # 4 bytes n_games
    write(buf, Int16(n))           # 2 bytes count
    write(buf, Int16(game_year))   # 2 bytes game_year ← Int16!
    write(buf, UInt8(8))           # 1 byte board_size
    write(buf, UInt8(game_type))   # 1 byte
    write(buf, UInt8(depth))       # 1 byte
    write(buf, UInt8(0))           # 1 byte reserved

    # Game records (68 bytes each)
    for g in games
        write(buf, Int16(g.tournament_id))
        write(buf, Int16(g.black_id))
        write(buf, Int16(g.white_id))
        write(buf, UInt8(g.black_score))
        write(buf, UInt8(g.best_score))
        move_bytes = UInt8[_notation_to_wthor_byte(m) for m in g.moves if m != "pass"]
        resize!(move_bytes, 60)
        write(buf, move_bytes)
    end

    Base.write(path, take!(buf))   # binary write
    return path
end

# ---------------------------------------------------------------------------
# Conversion helpers
# ---------------------------------------------------------------------------

"""
    wthor_game_to_record(g::WThorGame) -> GameRecord

Convert a `WThorGame` to the `GameRecord` format used by `replay_game`.
`black_score > 32` → BLACK wins, `< 32` → WHITE wins, `== 32` → draw.
"""
function wthor_game_to_record(g::WThorGame)
    result = if g.black_score > 32
        BLACK
    elseif g.black_score < 32
        WHITE
    else
        EMPTY
    end
    return GameRecord(copy(g.moves), result)
end

"""
    verify_wthor_game(g::WThorGame) -> Bool

Replay all moves of `g` on a fresh board and verify the final black disc
count matches `g.black_score`.  Returns `false` on any invalid move.
"""
function verify_wthor_game(g::WThorGame)
    game = ReversiGame()
    for move_str in g.moves
        if move_str == "pass"
            pass!(game)
        else
            ok = make_move!(game, move_str)
            ok || return false
        end
    end
    actual_black, _ = count_pieces(game)
    return actual_black == g.black_score
end
