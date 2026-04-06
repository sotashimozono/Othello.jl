# ---------------------------------------------------------------------------
# GUI stubs
#
# GUIPlayer is defined here so it is always available as a concrete type
# (e.g. for dispatch and for play_game calls).
#
# The actual windows (launch_gui / launch_replay_gui) are provided by
# the package extension  ext/ReversiGLMakieExt.jl  and become available
# only after GLMakie has been loaded:
#
#   using GLMakie   # must be loaded before or alongside Reversi
#   using Reversi
# ---------------------------------------------------------------------------

"""
    GUIPlayer <: Player

A player that inputs moves by clicking squares on the GLMakie GUI board.

`get_move` blocks until a valid board square is clicked.
Use `launch_gui(GUIPlayer(), ...)` to open the window.
Requires the GLMakie package to be loaded for `launch_gui` to work.
"""
mutable struct GUIPlayer <: Player
    move_channel::Channel{Union{Position,Nothing}}
    GUIPlayer() = new(Channel{Union{Position,Nothing}}(1))
end

function get_move(player::GUIPlayer, game::ReversiGame)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    while true
        pos = take!(player.move_channel)
        (pos === nothing || pos in moves) && return pos
    end
end

"""
    launch_gui([black, white]; show_hints=true)

Open an interactive GLMakie Reversi window.

**Requires GLMakie to be loaded first:**
```julia
using GLMakie, Reversi
launch_gui()                            # human (black) vs random AI
launch_gui(GUIPlayer(), GUIPlayer())    # human vs human
```
"""
function launch_gui end

"""
    launch_replay_gui(record_or_moves; title="Game Replay")

Open a read-only GLMakie replay window for a recorded game.

**Requires GLMakie to be loaded first:**
```julia
using GLMakie, Reversi
rec = load_game("mygame.txt")
launch_replay_gui(rec)
```
"""
function launch_replay_gui end
