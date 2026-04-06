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
# (GUIPlayer has been merged into HumanPlayer in core/player.jl)

"""
    launch_gui([black, white]; show_hints=true)

Open an interactive GLMakie Reversi window.

**Requires GLMakie to be loaded first:**
```julia
using GLMakie, Reversi
launch_gui()                            # human (black) vs random AI
launch_gui(HumanPlayer(), HumanPlayer())  # human vs human
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
