
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
#   Bytes 10-11 : game_year (Int16 LE)
#   Byte 12     : board_size (8 for standard Othello)
#   Byte 13     : game_type
#   Byte 14     : depth
#   Byte 15     : reserved
#
# Game record layout (68 bytes each):
#   Bytes 0-1   : tournament_id  (Int16 LE)
#   Bytes 2-3   : black_id       (Int16 LE)
#   Bytes 4-5   : white_id       (Int16 LE)
#   Byte 6      : black_score    (UInt8)
#   Byte 7      : best_score     (UInt8)
#   Bytes 8-67  : moves          (60 × UInt8, 0x00 = end/padding)
#
# Move encoding: byte = row * 10 + col  (row 1-8, col a=1…h=8)
#   e.g.  a1=11, h1=18, a8=81, h8=88, f5=56
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

"""
    WThorHeader

Metadata from the 16-byte header of a `.wtb` WTHOR database file.
"""
struct WThorHeader
    created_century::Int
    created_year::Int
    created_month::Int
    created_day::Int
    n_games::Int
    game_year::Int
    board_size::Int
    game_type::Int
    depth::Int
end

"""
    WThorGame

One game record from a `.wtb` WTHOR database file.
"""
struct WThorGame
    tournament_id::Int
    black_id::Int
    white_id::Int
    black_score::Int
    best_score::Int
    moves::Vector{String}
end

# ---------------------------------------------------------------------------
# Move encoding helpers
# ---------------------------------------------------------------------------

"""
    _wthor_byte_to_notation(b) -> Union{String, Nothing}

Decode one WTHOR move byte to standard Othello notation.
Returns `nothing` for 0x00 (end-of-game / padding).
"""
function _wthor_byte_to_notation(b::UInt8)
    b == 0x00 && return nothing
    row = div(Int(b), 10)
    col = mod(Int(b), 10)
    (1 <= row <= 8 && 1 <= col <= 8) || return nothing
    return string(Char(Int('a') + col - 1)) * string(row)
end

"""
    _notation_to_wthor_byte(s) -> UInt8

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
    read_wthor(path) -> (WThorHeader, Vector{WThorGame})

Parse a WTHOR `.wtb` binary file.

# Example
```julia
header, games = read_wthor("WTH_2001.wtb")
println("Games: \$(header.n_games), year: \$(header.game_year)")
```
"""
function read_wthor(path::String)
    data = read(path)
    length(data) >= 16 || error("File too short to contain a WTHOR header: $path")

    io = IOBuffer(data)

    century = Int(read(io, UInt8))
    yr = Int(read(io, UInt8))
    month = Int(read(io, UInt8))
    day = Int(read(io, UInt8))
    n_games = Int(read(io, Int32))
    _ = read(io, Int16)        # count field (same as n_games)
    game_year = Int(read(io, Int16))
    board_size = Int(read(io, UInt8))
    game_type = Int(read(io, UInt8))
    depth = Int(read(io, UInt8))
    _ = read(io, UInt8)        # reserved

    header = WThorHeader(
        century, yr, month, day, n_games, game_year, board_size, game_type, depth
    )

    n_available = div(length(data) - 16, 68)
    if n_available < n_games
        @warn "File has $(n_available) records but header declares $(n_games). Reading available."
    end

    games = WThorGame[]
    sizehint!(games, n_available)

    for _ in 1:n_available
        tourn = Int(read(io, Int16))
        black_id = Int(read(io, Int16))
        white_id = Int(read(io, Int16))
        b_score = Int(read(io, UInt8))
        t_score = Int(read(io, UInt8))
        raw = read(io, 60)

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
    write_wthor(path, games; year, month, day, game_year, game_type, depth)

Write `games` to `path` in WTHOR binary format.

Each game record is exactly 68 bytes: 8 bytes of metadata followed by a
60-byte move array zero-padded to fill the fixed-size slot.  Pass moves are
silently omitted (WTHOR does not encode passes).

# Example
```julia
g = WThorGame(1, 42, 99, 34, 36, ["f5","d6","c5"])
write_wthor("out.wtb", [g]; year=2024, game_year=2024)
header, loaded = read_wthor("out.wtb")
@assert loaded[1].moves == g.moves
```
"""
function write_wthor(
    path::String,
    games::Vector{WThorGame};
    year::Int=0,
    month::Int=1,
    day::Int=1,
    game_year::Int=0,
    game_type::Int=0,
    depth::Int=0,
)
    n = length(games)
    century = div(year, 100)
    yr_in_c = mod(year, 100)

    # Build into a buffer first, then write as binary (avoids \r\n on Windows).
    buf = IOBuffer()

    # ---- Header (16 bytes) ----
    write(buf, UInt8(century), UInt8(yr_in_c), UInt8(month), UInt8(day))
    write(buf, Int32(n))
    write(buf, Int16(n))
    write(buf, Int16(game_year))
    write(buf, UInt8(8))           # board_size always 8
    write(buf, UInt8(game_type))
    write(buf, UInt8(depth))
    write(buf, UInt8(0))           # reserved

    # ---- Game records (68 bytes each) ----
    for g in games
        write(buf, Int16(g.tournament_id))
        write(buf, Int16(g.black_id))
        write(buf, Int16(g.white_id))
        write(buf, UInt8(g.black_score))
        write(buf, UInt8(g.best_score))

        # Build zero-initialised 60-byte move array, then fill with encoded moves.
        # Pass tokens are skipped: WTHOR has no encoding for a pass.
        move_bytes = zeros(UInt8, 60)
        idx = 1
        for m in g.moves
            m == "pass" && continue
            idx > 60 && break
            move_bytes[idx] = _notation_to_wthor_byte(m)
            idx += 1
        end
        write(buf, move_bytes)
    end

    Base.write(path, take!(buf))
    return path
end

# ---------------------------------------------------------------------------
# Conversion helpers
# ---------------------------------------------------------------------------

"""
    wthor_game_to_record(g) -> GameRecord

Convert a `WThorGame` to a `GameRecord`.
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
    verify_wthor_game(g) -> Bool

Replay all moves of `g` on a fresh board and verify the final black disc count
matches `g.black_score`.  Returns `false` on any invalid move (does not throw).
"""
function verify_wthor_game(g::WThorGame)
    game = ReversiGame()
    for move_str in g.moves
        if move_str == "pass"
            pass!(game; force=true)
        else
            # WTHOR does not encode passes; auto-pass whenever the current
            # player has no legal moves before applying the stored move.
            while isempty(valid_moves(game)) && !is_game_over(game)
                pass!(game; force=true)
            end
            ok = make_move!(game, move_str)
            ok || return false
        end
    end
    # Auto-pass any trailing forced passes after all stored moves.
    while isempty(valid_moves(game)) && !is_game_over(game)
        pass!(game; force=true)
    end
    actual_black, _ = count_pieces(game)
    return actual_black == g.black_score
end
