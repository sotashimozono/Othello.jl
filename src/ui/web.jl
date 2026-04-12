# ---------------------------------------------------------------------------
# Web UI stubs
#
# The actual server (launch_web_gui) is provided by the package extension
# ext/ReversiWebExt/src/ReversiWebExt.jl and becomes available only after
# Oxygen and other web dependencies have been loaded.
# ---------------------------------------------------------------------------

"""
    launch_web_gui(; port=8080, open_browser=true)

Launch the modern local-first web UI for Reversi.jl.

**Requires Oxygen, HTTP, JSON3, and DefaultApplication to be loaded:**
```julia
using Oxygen, HTTP, JSON3, DefaultApplication
using Reversi
launch_web_gui()
```
"""
function launch_web_gui end
