using GLMakie

# ---------------------------------------------------------------------------
# GUIPlayer – GUI implementation of the Player interface
# ---------------------------------------------------------------------------

"""
    GUIPlayer <: Player

A player that inputs moves by clicking squares on the GUI board.
Internally uses a `Channel` to deliver moves from the GUI event loop
to the game loop running in a separate async task.
"""
mutable struct GUIPlayer <: Player
    move_channel::Channel{Union{Position,Nothing}}
    GUIPlayer() = new(Channel{Union{Position,Nothing}}(1))
end

function get_move(player::GUIPlayer, game::ReversiGame)
    moves = valid_moves(game)
    if isempty(moves)
        return nothing
    end
    # Block until a valid click arrives from the GUI
    while true
        pos = take!(player.move_channel)
        if pos === nothing || pos in moves
            return pos
        end
    end
end

# ---------------------------------------------------------------------------
# Internal utilities
# ---------------------------------------------------------------------------

# Colour palette
const _C_BG = RGBf(0.13, 0.13, 0.15)   # window background
const _C_PANEL = RGBf(0.19, 0.19, 0.22)   # sidebar / info panels
const _C_BOARD = RGBf(0.05, 0.42, 0.14)   # board green
const _C_GRID = RGBf(0.02, 0.28, 0.07)   # grid lines
const _C_BLACK_PC = RGBf(0.07, 0.07, 0.09)   # black piece fill
const _C_WHITE_PC = RGBf(0.94, 0.94, 0.96)   # white piece fill
const _C_HINT = RGBAf(0.95, 0.88, 0.20, 0.55)
const _C_HINT_RIM = RGBAf(0.80, 0.73, 0.05, 0.85)
const _C_LAST = RGBAf(1.0, 0.35, 0.35, 0.75)   # last-move marker
const _C_TEXT = RGBf(0.88, 0.88, 0.88)
const _C_TEXT_DIM = RGBf(0.55, 0.55, 0.58)
const _C_ACCENT_B = RGBf(0.25, 0.55, 1.00)   # black-player accent
const _C_ACCENT_W = RGBf(0.95, 0.95, 0.95)   # white-player accent
const _C_TURN_HL = RGBAf(0.25, 0.55, 1.00, 0.18)  # active player highlight

const _BOARD_SIZE = 8

# Convert board (row, col) to Axis-space centre (x, y)
_board_to_xy(row, col) = (col - 0.5, _BOARD_SIZE - row + 0.5)

# ---------------------------------------------------------------------------
# Board drawing helpers
# ---------------------------------------------------------------------------

function _draw_board!(ax)
    # Board background
    poly!(ax, Point2f[(0, 0), (8, 0), (8, 8), (0, 8)]; color=_C_BOARD, strokewidth=0)
    # Grid lines
    for i in 0:_BOARD_SIZE
        lines!(ax, [i, i], [0, 8]; color=_C_GRID, linewidth=1.0)
        lines!(ax, [0, 8], [i, i]; color=_C_GRID, linewidth=1.0)
    end
    # Star points (hoshi)
    for (r, c) in [(3, 3), (3, 6), (6, 3), (6, 6)]
        x, y = _board_to_xy(r, c)
        scatter!(ax, [x], [y]; color=_C_GRID, markersize=8)
    end
    # Column labels a-h (above board)
    for (i, ch) in enumerate('a':'h')
        text!(
            ax,
            i - 0.5,
            8.18;
            text=string(ch),
            color=_C_TEXT,
            fontsize=15,
            align=(:center, :bottom),
        )
    end
    # Row labels 1-8 (left of board)
    for r in 1:8
        text!(
            ax,
            -0.18,
            8 - r + 0.5;
            text=string(r),
            color=_C_TEXT,
            fontsize=15,
            align=(:right, :center),
        )
    end
end

function _draw_pieces!(
    ax, game::ReversiGame, px_per_unit::Real, last_move::Union{Position,Nothing}=nothing
)
    black_pts = Point2f[]
    white_pts = Point2f[]
    for row in 1:8, col in 1:8
        piece = get_piece(game, row, col)
        x, y = _board_to_xy(row, col)
        if piece == BLACK
            push!(black_pts, Point2f(x, y))
        elseif piece == WHITE
            push!(white_pts, Point2f(x, y))
        end
    end
    # Piece radius: 0.44 × cell size in pixels (px_per_unit is computed dynamically)
    r = 0.44
    ms = r * 2 * px_per_unit
    if !isempty(black_pts)
        scatter!(
            ax,
            black_pts;
            color=_C_BLACK_PC,
            markersize=ms,
            strokecolor=RGBf(0.30, 0.30, 0.32),
            strokewidth=2.0,
        )
    end
    if !isempty(white_pts)
        scatter!(
            ax,
            white_pts;
            color=_C_WHITE_PC,
            markersize=ms,
            strokecolor=RGBf(0.60, 0.60, 0.62),
            strokewidth=2.0,
        )
    end
    # Highlight last move: thin border around the cell (no overlay on the piece)
    if last_move !== nothing
        c0 = last_move.col - 1
        r0 = _BOARD_SIZE - last_move.row
        lines!(
            ax,
            [c0, c0 + 1, c0 + 1, c0, c0],
            [r0, r0, r0 + 1, r0 + 1, r0];
            color=RGBAf(1.0, 0.35, 0.35, 0.90),
            linewidth=3.5,
        )
    end
end

function _draw_hints!(ax, game::ReversiGame, px_per_unit::Real)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    pts = [Point2f(_board_to_xy(m.row, m.col)...) for m in moves]
    # Small clean dot – no stroke, just a semi-transparent filled circle
    return scatter!(
        ax,
        pts;
        color=RGBAf(0.90, 0.82, 0.10, 0.65),
        markersize=0.18 * 2 * px_per_unit,
        strokewidth=0,
    )
end

# ---------------------------------------------------------------------------
# Player name helper
# ---------------------------------------------------------------------------

_player_name(p::GUIPlayer) = "Human"
_player_name(p::RandomPlayer) = "Random AI"
_player_name(p::Player) = string(typeof(p))

# ---------------------------------------------------------------------------
# Player registry (name => factory function)
# ---------------------------------------------------------------------------

"""
    NamedPlayerEntry

A named player entry in the player registry.
- `name`: display name shown in menus
- `factory`: a zero-argument function that returns a new Player instance
"""
struct NamedPlayerEntry
    name::String
    factory::Function
end

# Built-in entries
const _BUILTIN_PLAYERS = [
    NamedPlayerEntry("Human (Player)", () -> GUIPlayer()),
    NamedPlayerEntry("Random AI", () -> RandomPlayer()),
]

# ---------------------------------------------------------------------------
# Add-Player dialog
# ---------------------------------------------------------------------------

"""
    _open_add_player_dialog!(registry_obs, update_cb)

Open a small secondary window where the user can register a custom player.
The user enters:
  - A display name (e.g. "My ML Player")
  - A Julia expression that evaluates to a Player instance
    (e.g. `MyMLPlayer(load_model("weights.bson"))`)

On "Register", the expression is eval'd in the Main module, the resulting
Player is wrapped in a factory closure, and `update_cb` is called so that
the selection menus can refresh.
"""
function _open_add_player_dialog!(registry_obs::Observable, update_cb::Function)
    dlg = Figure(; size=(480, 220), backgroundcolor=_C_BG)

    Label(
        dlg[1, 1:3];
        text="Register Custom Player",
        color=_C_TEXT,
        fontsize=16,
        font=:bold,
        halign=:center,
    )

    Label(dlg[2, 1]; text="Name:", color=_C_TEXT_DIM, fontsize=13, halign=:right)
    name_tb = Textbox(dlg[2, 2:3]; placeholder="e.g.  My ML Player", fontsize=13, width=280)

    Label(dlg[3, 1]; text="Expression:", color=_C_TEXT_DIM, fontsize=13, halign=:right)
    expr_tb = Textbox(
        dlg[3, 2:3]; placeholder="e.g.  RandomPlayer()", fontsize=13, width=280
    )

    msg_lbl = Label(
        dlg[4, 1:3]; text="", color=RGBf(1.0, 0.4, 0.4), fontsize=12, halign=:center
    )

    btn_reg = Button(
        dlg[5, 2];
        label="✔ Register",
        buttoncolor=RGBf(0.20, 0.45, 0.20),
        labelcolor=:white,
        fontsize=13,
    )
    btn_cancel = Button(
        dlg[5, 3];
        label="Cancel",
        buttoncolor=RGBf(0.30, 0.30, 0.34),
        labelcolor=_C_TEXT_DIM,
        fontsize=13,
    )

    on(btn_cancel.clicks) do _
        return close(dlg.scene)
    end

    on(btn_reg.clicks) do _
        raw_name = strip(name_tb.displayed_string[])
        raw_expr = strip(expr_tb.displayed_string[])
        if isempty(raw_name)
            msg_lbl.text[] = "⚠ Please enter a name."
            return nothing
        end
        if isempty(raw_expr)
            msg_lbl.text[] = "⚠ Please enter a Julia expression."
            return nothing
        end
        # Try to parse and evaluate
        local player_instance
        try
            parsed = Meta.parse(raw_expr)
            player_instance = Main.eval(parsed)
        catch e
            msg_lbl.text[] = "⚠ Error: $(sprint(showerror, e))"
            return nothing
        end
        if !(player_instance isa Player)
            msg_lbl.text[] = "⚠ Result is not a Player (got $(typeof(player_instance)))."
            return nothing
        end
        # Capture the expression string for repeated construction
        expr_str = raw_expr
        entry = NamedPlayerEntry(String(raw_name), () -> Main.eval(Meta.parse(expr_str)))
        new_registry = vcat(registry_obs[], [entry])
        registry_obs[] = new_registry
        update_cb()
        close(dlg.scene)
    end

    display(dlg)
    return dlg
end

# ---------------------------------------------------------------------------
# Main GUI entry point
# ---------------------------------------------------------------------------

"""
    launch_gui(black::Player, white::Player; show_hints::Bool=true)

Open a GLMakie window and start an interactive Reversi GUI in ShogiGUI style.
Pass any `Player` instances as `black` and `white` to configure the match.
A `GUIPlayer()` lets a human input moves by clicking the board;
any other `Player` subtype (e.g. `RandomPlayer()` or a custom ML player)
will play automatically via `get_move`.

The GUI includes a top bar where you can change players and restart the game
at any time, as well as a "+ Add Player" button to register custom players
by supplying a Julia expression (e.g. `MyMLPlayer(load_weights("w.bson"))`).

# Examples
```julia
launch_gui()                                  # human (black) vs random AI
launch_gui(GUIPlayer(), GUIPlayer())          # human vs human
launch_gui(RandomPlayer(), RandomPlayer())    # AI vs AI (spectator)
launch_gui(MyMLPlayer(model), GUIPlayer())    # ML model (black) vs human
```
"""
function launch_gui(
    black::Player=GUIPlayer(), white::Player=RandomPlayer(); show_hints::Bool=true
)
    # -----------------------------------------------------------------------
    # Observable state
    # -----------------------------------------------------------------------
    game_obs = Observable(ReversiGame())
    hints_obs = Observable(show_hints)
    game_over_obs = Observable(false)
    last_move_obs = Observable{Union{Position,Nothing}}(nothing)
    show_last_obs = Observable(false)   # last-move highlight: off by default
    # Kifu: vector of (move_number, color, notation_string)
    kifu_obs = Observable(Tuple{Int,Int,String}[])

    # Player registry observable (list of NamedPlayerEntry)
    registry_obs = Observable(copy(_BUILTIN_PLAYERS))

    # -----------------------------------------------------------------------
    # Figure layout
    # Row 1: player selection bar  (new)
    # Row 2: white player card
    # Row 3: board Axis
    # Row 4: black player card
    # Row 5: control bar
    # Col 2: kifu panel (spans all rows)
    # -----------------------------------------------------------------------
    fig = Figure(; size=(820, 760), backgroundcolor=_C_BG)

    # -----------------------------------------------------------------------
    # Row 1: Player selection bar
    # -----------------------------------------------------------------------
    sel_bar = fig[1, 1] = GridLayout()

    # Helper: build option names from registry
    _names(reg) = [e.name for e in reg]

    # Determine initial indices
    _find_idx(reg, p) = begin
        T = typeof(p)
        if p isa GUIPlayer
            return 1
        elseif p isa RandomPlayer
            idx = findfirst(e -> e.name == "Random AI", reg)
            return idx === nothing ? 1 : idx
        else
            return 1
        end
    end

    init_reg = registry_obs[]
    menu_options_obs = Observable(_names(init_reg))

    # Keep menu_options in sync with registry
    on(registry_obs) do reg
        menu_options_obs[] = _names(reg)
    end

    black_sel = Menu(
        sel_bar[1, 2];
        options=menu_options_obs,
        i_selected=_find_idx(init_reg, black),
        fontsize=13,
        width=160,
    )
    white_sel = Menu(
        sel_bar[1, 4];
        options=menu_options_obs,
        i_selected=_find_idx(init_reg, white),
        fontsize=13,
        width=160,
    )

    Label(
        sel_bar[1, 1];
        text="Black:",
        color=_C_ACCENT_B,
        fontsize=13,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    Label(
        sel_bar[1, 3];
        text="White:",
        color=_C_ACCENT_W,
        fontsize=13,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )

    btn_add = Button(
        sel_bar[1, 5];
        label="+ Add Player",
        buttoncolor=RGBf(0.22, 0.35, 0.50),
        labelcolor=:white,
        fontsize=13,
    )

    btn_start = Button(
        sel_bar[1, 6];
        label="▶ New Game",
        buttoncolor=RGBf(0.22, 0.22, 0.26),
        labelcolor=:white,
        fontsize=13,
    )

    rowsize!(fig.layout, 1, Fixed(44))
    colgap!(sel_bar, 6)
    colsize!(sel_bar, 1, Fixed(50))
    colsize!(sel_bar, 3, Fixed(50))

    # -----------------------------------------------------------------------
    # Row 2: White player info
    # -----------------------------------------------------------------------
    white_card = fig[2, 1] = GridLayout()
    white_name_lbl = Label(
        white_card[1, 1];
        text="[W]  White: $(_player_name(white))",
        color=_C_ACCENT_W,
        fontsize=15,
        halign=:left,
        tellwidth=false,
    )
    white_score_lbl = Label(
        white_card[1, 2];
        text=@lift("$(count_pieces($game_obs)[2])"),
        color=_C_TEXT,
        fontsize=20,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    white_turn_lbl = Label(
        white_card[1, 3];
        text=@lift((!$game_over_obs && $game_obs.current_player == WHITE) ? "< Turn" : ""),
        color=_C_ACCENT_B,
        fontsize=13,
        halign=:left,
        tellwidth=false,
    )
    rowsize!(fig.layout, 2, Fixed(40))

    # -----------------------------------------------------------------------
    # Row 3: Board Axis
    # -----------------------------------------------------------------------
    ax = Axis(
        fig[3, 1];
        aspect=DataAspect(),
        limits=(-0.40, 8.32, -0.24, 8.55),
        backgroundcolor=_C_BG,
        xgridvisible=false,
        ygridvisible=false,
        xticksvisible=false,
        yticksvisible=false,
        xticklabelsvisible=false,
        yticklabelsvisible=false,
        leftspinevisible=false,
        rightspinevisible=false,
        topspinevisible=false,
        bottomspinevisible=false,
    )

    # -----------------------------------------------------------------------
    # Row 4: Black player info
    # -----------------------------------------------------------------------
    black_card = fig[4, 1] = GridLayout()
    black_name_lbl = Label(
        black_card[1, 1];
        text="[B]  Black: $(_player_name(black))",
        color=_C_ACCENT_B,
        fontsize=15,
        halign=:left,
        tellwidth=false,
    )
    black_score_lbl = Label(
        black_card[1, 2];
        text=@lift("$(count_pieces($game_obs)[1])"),
        color=_C_TEXT,
        fontsize=20,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    black_turn_lbl = Label(
        black_card[1, 3];
        text=@lift((!$game_over_obs && $game_obs.current_player == BLACK) ? "< Turn" : ""),
        color=_C_ACCENT_B,
        fontsize=13,
        halign=:left,
        tellwidth=false,
    )
    rowsize!(fig.layout, 4, Fixed(40))

    # -----------------------------------------------------------------------
    # Row 5: Control bar
    # -----------------------------------------------------------------------
    ctrl = fig[5, 1] = GridLayout()
    tgl_hints = Toggle(ctrl[1, 1]; active=show_hints)
    Label(ctrl[1, 2]; text="Hints", color=_C_TEXT_DIM, fontsize=13)
    tgl_last = Toggle(ctrl[1, 3]; active=false)
    Label(ctrl[1, 4]; text="Last Move", color=_C_TEXT_DIM, fontsize=13)
    # Status label
    status_lbl = Label(
        ctrl[1, 5];
        text=@lift(
            begin
                game = $game_obs
                over = $game_over_obs
                if over
                    w = get_winner(game)
                    b, wc = count_pieces(game)
                    if w == BLACK
                        "Black wins!  (B $b - W $wc)"
                    elseif w == WHITE
                        "White wins!  (B $b - W $wc)"
                    else
                        "Draw!  (B $b - W $wc)"
                    end
                else
                    "B $(count_pieces(game)[1]) - W $(count_pieces(game)[2])"
                end
            end
        ),
        color=@lift($game_over_obs ? RGBf(1.0, 0.75, 0.3) : _C_TEXT_DIM),
        fontsize=14,
        halign=:left,
        tellwidth=false,
    )
    rowsize!(fig.layout, 5, Fixed(44))
    colsize!(ctrl, 5, Relative(1.0))

    # -----------------------------------------------------------------------
    # Kifu (move history) sidebar — spans all rows
    # -----------------------------------------------------------------------
    kifu_panel = fig[1:5, 2] = GridLayout()
    Label(
        kifu_panel[1, 1];
        text="Move History",
        color=_C_TEXT,
        fontsize=14,
        font=:bold,
        halign=:center,
    )

    # Scrollable text area for kifu
    kifu_ax = Axis(
        kifu_panel[2, 1];
        backgroundcolor=_C_PANEL,
        xgridvisible=false,
        ygridvisible=false,
        xticksvisible=false,
        yticksvisible=false,
        xticklabelsvisible=false,
        yticklabelsvisible=false,
        leftspinevisible=false,
        rightspinevisible=false,
        topspinevisible=false,
        bottomspinevisible=false,
        yreversed=true,
    )

    colsize!(fig.layout, 1, Relative(1.0))   # board column: all remaining space
    colsize!(fig.layout, 2, Fixed(230))        # kifu panel: fixed 230 px width
    rowsize!(fig.layout, 3, Relative(1.0))

    # -----------------------------------------------------------------------
    # Dynamic px-per-data-unit scaling (updates on window resize)
    # -----------------------------------------------------------------------
    # The board data range is 8 units wide (0..8). We compute how many pixels
    # that corresponds to from the Axis viewport, so pieces scale correctly.
    function _px_per_unit()
        area = ax.scene.viewport[]
        return area.widths[1] / 8.0
    end

    # -----------------------------------------------------------------------
    # Drawing helpers
    # -----------------------------------------------------------------------
    function _refresh!(ax, game, show_h, last_move)
        ppu = _px_per_unit()
        empty!(ax)
        _draw_board!(ax)
        _draw_pieces!(ax, game, ppu, show_last_obs[] ? last_move : nothing)
        return show_h && !game_over_obs[] && _draw_hints!(ax, game, ppu)
    end

    function _refresh_kifu!(kifu_ax, kifu)
        empty!(kifu_ax)
        if isempty(kifu)
            text!(
                kifu_ax,
                0.5,
                0.5;
                text="No moves yet",
                color=_C_TEXT_DIM,
                fontsize=12,
                align=(:center, :center),
                space=:relative,
            )
            ylims!(kifu_ax, 1, 0)
            return nothing
        end
        for (n, color, notation) in kifu
            pc_tag = color == BLACK ? "[B]" : "[W]"
            line_color = color == BLACK ? _C_ACCENT_B : _C_TEXT
            # Move number
            text!(
                kifu_ax,
                0.05,
                Float32(n - 1);
                text=lpad(string(n), 3),
                color=_C_TEXT_DIM,
                fontsize=12,
                align=(:left, :top),
            )
            # Tag + notation
            text!(
                kifu_ax,
                0.35,
                Float32(n - 1);
                text="$pc_tag  $notation",
                color=line_color,
                fontsize=12,
                align=(:left, :top),
            )
        end
        # keep limits so rows are visible
        ylims!(kifu_ax, length(kifu) + 0.5, -0.5)
        return xlims!(kifu_ax, 0, 1)
    end

    on(game_obs) do game
        _refresh!(ax, game, hints_obs[], last_move_obs[])
    end
    on(kifu_obs) do kifu
        _refresh_kifu!(kifu_ax, kifu)
    end
    on(tgl_hints.active) do v
        hints_obs[] = v
        _refresh!(ax, game_obs[], v, last_move_obs[])
    end
    on(tgl_last.active) do v
        show_last_obs[] = v
        _refresh!(ax, game_obs[], hints_obs[], last_move_obs[])
    end
    # Redraw when the window is resized so piece sizes stay proportional
    on(ax.scene.viewport) do _
        _refresh!(ax, game_obs[], hints_obs[], last_move_obs[])
    end

    # -----------------------------------------------------------------------
    # Players ref — updated each time a new game starts
    # -----------------------------------------------------------------------
    players = Ref{Dict{Int,Player}}(Dict(BLACK => black, WHITE => white))

    # Helper: build a fresh Player from the current menu selection
    function _selected_player(menu::Menu)
        reg = registry_obs[]
        idx = menu.i_selected[]
        idx = clamp(idx, 1, length(reg))
        return reg[idx].factory()
    end

    # -----------------------------------------------------------------------
    # Async game loop
    # -----------------------------------------------------------------------
    function run_game!(game_ref, kifu_ref)
        game = game_ref[]
        while !is_game_over(game)
            sleep(0.0)   # yield to the event loop
            current_player = players[][game.current_player]
            color = game.current_player
            move = get_move(current_player, game)

            if move === nothing
                push!(kifu_ref[], (length(kifu_ref[]) + 1, color, "pass"))
                pass!(game)
                last_move_obs[] = nothing
            else
                push!(kifu_ref[], (length(kifu_ref[]) + 1, color, position_to_string(move)))
                make_move!(game, move.row, move.col)
                last_move_obs[] = move
            end

            kifu_obs[] = copy(kifu_ref[])
            game_obs[] = deepcopy(game)
        end
        game_over_obs[] = true
        _refresh!(ax, game, false, last_move_obs[])
        return _refresh_kifu!(kifu_ax, kifu_obs[])
    end

    current_task = Ref{Union{Task,Nothing}}(nothing)

    function start_game!(new_black::Player, new_white::Player)
        # Reset GUIPlayer channels so any blocked get_move is unblocked
        for p in values(players[])
            if p isa GUIPlayer
                close(p.move_channel)   # unblock any waiting take!
            end
        end

        # Update the players dict with possibly fresh instances
        players[] = Dict{Int,Player}(BLACK => new_black, WHITE => new_white)

        # Update name labels
        white_name_lbl.text[] = "[W]  White: $(_player_name(new_white))"
        black_name_lbl.text[] = "[B]  Black: $(_player_name(new_black))"

        game = ReversiGame()
        kifu = Tuple{Int,Int,String}[]
        game_over_obs[] = false
        last_move_obs[] = nothing
        kifu_obs[] = kifu
        game_obs[] = game

        t = @async run_game!(Ref(game), Ref(kifu))
        current_task[] = t
        return t
    end

    # -----------------------------------------------------------------------
    # Button callbacks
    # -----------------------------------------------------------------------

    # "▶ New Game" in selection bar
    on(btn_start.clicks) do _
        b = _selected_player(black_sel)
        w = _selected_player(white_sel)
        start_game!(b, w)
    end

    # "+ Add Player"
    on(btn_add.clicks) do _
        # menu_options_obs is automatically updated via the on(registry_obs) handler
        _open_add_player_dialog!(registry_obs, () -> nothing)
    end

    # --- Mouse click → send move to GUIPlayer ---
    on(events(fig.scene).mousebutton) do event
        if event.button == Mouse.left && event.action == Mouse.press
            println("[CLICK] left press detected")
            inside = is_mouseinside(ax.scene)
            println("[CLICK] is_mouseinside: ", inside)
            inside || return nothing
            game = game_obs[]
            over = game_over_obs[]
            println("[CLICK] game_over: ", over, "  current_player: ", game.current_player)
            over && return nothing

            # Mouse in window coords (Y from bottom, device-independent)
            mp_win = events(fig.scene).mouseposition[]
            ax_vp = ax.scene.viewport[]
            println(
                "[CLICK] mp_win=",
                mp_win,
                "  ax_vp orig=",
                ax_vp.origin,
                " size=",
                ax_vp.widths,
            )

            # Normalized position within the axis viewport [0, 1]
            nx = (mp_win[1] - ax_vp.origin[1]) / ax_vp.widths[1]
            ny = (mp_win[2] - ax_vp.origin[2]) / ax_vp.widths[2]

            # Map to data space via the axis display limits
            lims = ax.finallimits[]
            data_x = lims.origin[1] + nx * lims.widths[1]
            data_y = lims.origin[2] + ny * lims.widths[2]
            println("[CLICK] data=(", data_x, ", ", data_y, ")")

            col = Int(floor(data_x)) + 1
            row = _BOARD_SIZE - Int(floor(data_y))
            println("[CLICK] row=", row, " col=", col)
            if 1 <= row <= 8 && 1 <= col <= 8
                cp = players[][game.current_player]
                println(
                    "[CLICK] player type: ",
                    typeof(cp),
                    "  channel open: ",
                    isopen(cp.move_channel),
                )
                if cp isa GUIPlayer && isopen(cp.move_channel)
                    println("[CLICK] putting Position(", row, ", ", col, ") into channel")
                    put!(cp.move_channel, Position(row, col))
                    println("[CLICK] put! done")
                end
            else
                println("[CLICK] out of board bounds, ignored")
            end
        end
    end

    # --- Launch ---
    _refresh_kifu!(kifu_ax, Tuple{Int,Int,String}[])
    display(fig)
    start_game!(black, white)

    return fig
end

# ---------------------------------------------------------------------------
# Kifu Replay GUI
# ---------------------------------------------------------------------------

"""
    launch_replay_gui(record::GameRecord; title::String="Game Replay")
    launch_replay_gui(moves::Vector{String}; title::String="Game Replay")

Open a read-only replay window for a recorded game.

Navigation controls:
  - **|◀** — jump to start
  - **◀**  — one move back
  - **▶**  — one move forward
  - **▶|** — jump to end
  - **Slider** — drag to any position
  - **← / →** keyboard arrows — move back / forward

Accepts either a `GameRecord` (from `load_game` or `wthor_game_to_record`)
or a plain `Vector{String}` of move notation strings (e.g. `[\"d3\",\"c4\",…]`).

# Examples
```julia
# From a saved game file
rec = load_game("mygame.txt")
launch_replay_gui(rec)

# From a WTHOR database
_, games = read_wthor("WTH_2001.wtb")
launch_replay_gui(wthor_game_to_record(games[1]); title="WTHOR 2001 #1")

# From a plain move list
launch_replay_gui(["d3","c4","e3","f4"]; title="Custom Game")
```
"""
function launch_replay_gui(record::GameRecord; title::String="Game Replay")
    return launch_replay_gui(record.moves; title=title)
end

function launch_replay_gui(moves::Vector{String}; title::String="Game Replay")
    # ------------------------------------------------------------------
    # Pre-compute board state at every ply (0 = start, N = after move N)
    # ------------------------------------------------------------------
    states = Vector{ReversiGame}(undef, length(moves) + 1)
    move_colors = Vector{Int}(undef, length(moves))

    states[1] = ReversiGame()
    for (i, m) in enumerate(moves)
        g = deepcopy(states[i])
        move_colors[i] = g.current_player
        if m == "pass"
            pass!(g)
        else
            make_move!(g, m)
        end
        states[i + 1] = g
    end
    n_moves = length(moves)

    # ------------------------------------------------------------------
    # Observables
    # ------------------------------------------------------------------
    pos_obs = Observable(0)          # current ply (0..n_moves)
    game_obs = Observable(states[1])  # board at current ply
    show_last_obs = Observable(true)
    last_move_obs = Observable{Union{Position,Nothing}}(nothing)

    # ------------------------------------------------------------------
    # Figure layout
    #  Row 1: title / info bar        (Fixed 36)
    #  Row 2: board Axis              (Relative 1.0)
    #  Row 3: navigation bar          (Fixed 48)
    #  Col 2: kifu panel
    # ------------------------------------------------------------------
    fig = Figure(; size=(720, 680), backgroundcolor=_C_BG)

    # --- Title bar ---
    title_lbl = Label(
        fig[1, 1];
        text=title,
        color=_C_TEXT,
        fontsize=15,
        font=:bold,
        halign=:left,
        tellwidth=false,
    )
    score_lbl = Label(
        fig[1, 1];
        text=@lift(
            begin
                g = $game_obs
                b, w = count_pieces(g)
                "B $b – W $w"
            end
        ),
        color=_C_TEXT_DIM,
        fontsize=14,
        halign=:right,
        tellwidth=false,
    )
    rowsize!(fig.layout, 1, Fixed(36))

    # --- Board Axis ---
    ax = Axis(
        fig[2, 1];
        aspect=DataAspect(),
        limits=(-0.40, 8.32, -0.24, 8.55),
        backgroundcolor=_C_BG,
        xgridvisible=false,
        ygridvisible=false,
        xticksvisible=false,
        yticksvisible=false,
        xticklabelsvisible=false,
        yticklabelsvisible=false,
        leftspinevisible=false,
        rightspinevisible=false,
        topspinevisible=false,
        bottomspinevisible=false,
    )

    # --- Navigation bar ---
    nav = fig[3, 1] = GridLayout()

    btn_first = Button(
        nav[1, 1];
        label="|◀",
        buttoncolor=RGBf(0.22, 0.22, 0.26),
        labelcolor=:white,
        fontsize=14,
        width=44,
    )
    btn_prev = Button(
        nav[1, 2];
        label="◀",
        buttoncolor=RGBf(0.22, 0.22, 0.26),
        labelcolor=:white,
        fontsize=14,
        width=44,
    )
    btn_next = Button(
        nav[1, 3];
        label="▶",
        buttoncolor=RGBf(0.22, 0.22, 0.26),
        labelcolor=:white,
        fontsize=14,
        width=44,
    )
    btn_last = Button(
        nav[1, 4];
        label="▶|",
        buttoncolor=RGBf(0.22, 0.22, 0.26),
        labelcolor=:white,
        fontsize=14,
        width=44,
    )

    slider = Slider(nav[1, 5]; range=0:n_moves, startvalue=0)

    move_lbl = Label(
        nav[1, 6];
        text=@lift("Move $($pos_obs) / $n_moves"),
        color=_C_TEXT_DIM,
        fontsize=13,
        halign=:left,
        tellwidth=false,
    )
    tgl_last = Toggle(nav[1, 7]; active=true)
    Label(nav[1, 8]; text="Last Move", color=_C_TEXT_DIM, fontsize=12)

    rowsize!(fig.layout, 3, Fixed(48))
    colsize!(nav, 5, Relative(1.0))

    # --- Kifu sidebar ---
    kifu_panel = fig[1:3, 2] = GridLayout()
    Label(
        kifu_panel[1, 1];
        text="Move History",
        color=_C_TEXT,
        fontsize=14,
        font=:bold,
        halign=:center,
    )
    kifu_ax = Axis(
        kifu_panel[2, 1];
        backgroundcolor=_C_PANEL,
        xgridvisible=false,
        ygridvisible=false,
        xticksvisible=false,
        yticksvisible=false,
        xticklabelsvisible=false,
        yticklabelsvisible=false,
        leftspinevisible=false,
        rightspinevisible=false,
        topspinevisible=false,
        bottomspinevisible=false,
        yreversed=true,
    )

    colsize!(fig.layout, 1, Relative(0.72))
    colsize!(fig.layout, 2, Relative(0.28))
    rowsize!(fig.layout, 2, Relative(1.0))

    # ------------------------------------------------------------------
    # Dynamic px-per-data-unit scaling (updates on window resize)
    # ------------------------------------------------------------------
    function _px_per_unit_replay()
        area = ax.scene.viewport[]
        return area.widths[1] / 8.0
    end

    # ------------------------------------------------------------------
    # Draw helpers
    # ------------------------------------------------------------------
    function _refresh_board!(p)
        ppu = _px_per_unit_replay()
        empty!(ax)
        _draw_board!(ax)
        lm = if show_last_obs[] && p > 0 && moves[p] != "pass"
            Position(moves[p])
        else
            nothing
        end
        return _draw_pieces!(ax, states[p + 1], ppu, lm)
    end

    function _refresh_replay_kifu!(current_p)
        empty!(kifu_ax)
        n = length(moves)
        if n == 0
            text!(
                kifu_ax,
                0.5,
                0.5;
                text="No moves",
                color=_C_TEXT_DIM,
                fontsize=12,
                align=(:center, :center),
                space=:relative,
            )
            ylims!(kifu_ax, 1, 0)
            return nothing
        end
        for i in 1:n
            color = move_colors[i]
            pc_tag = color == BLACK ? "[B]" : "[W]"
            is_current = (i == current_p)
            row_color = if is_current
                RGBf(1.0, 0.85, 0.2)
            elseif color == BLACK
                _C_ACCENT_B
            else
                _C_TEXT
            end
            text!(
                kifu_ax,
                0.05,
                Float32(i - 1);
                text=lpad(string(i), 3),
                color=_C_TEXT_DIM,
                fontsize=12,
                align=(:left, :top),
            )
            text!(
                kifu_ax,
                0.35,
                Float32(i - 1);
                text="$pc_tag  $(moves[i])",
                color=row_color,
                fontsize=is_current ? 13 : 12,
                align=(:left, :top),
            )
        end
        ylims!(kifu_ax, n + 0.5, -0.5)
        return xlims!(kifu_ax, 0, 1)
    end

    # ------------------------------------------------------------------
    # Sync function (all updates go through here)
    # ------------------------------------------------------------------
    function _goto!(p)
        p = clamp(p, 0, n_moves)
        pos_obs[] = p
        game_obs[] = states[p + 1]
        slider.value[] = p
        _refresh_board!(p)
        return _refresh_replay_kifu!(p)
    end

    # ------------------------------------------------------------------
    # Reactivity
    # ------------------------------------------------------------------
    on(tgl_last.active) do v
        show_last_obs[] = v
        _refresh_board!(pos_obs[])
    end
    # Redraw when the window is resized so piece sizes stay proportional
    on(ax.scene.viewport) do _
        _refresh_board!(pos_obs[])
    end

    on(btn_first.clicks) do _
        _goto!(0)
    end
    on(btn_prev.clicks) do _
        _goto!(pos_obs[] - 1)
    end
    on(btn_next.clicks) do _
        _goto!(pos_obs[] + 1)
    end
    on(btn_last.clicks) do _
        _goto!(n_moves)
    end

    # Slider drag
    on(slider.value) do v
        v == pos_obs[] && return nothing
        _goto!(v)
    end

    # Keyboard: left / right arrows
    on(events(fig.scene).keyboardbutton) do event
        if event.action == Keyboard.press || event.action == Keyboard.repeat
            if event.key == Keyboard.left
                _goto!(pos_obs[] - 1)
            elseif event.key == Keyboard.right
                _goto!(pos_obs[] + 1)
            elseif event.key == Keyboard.home
                _goto!(0)
            elseif event.key == Keyboard.end_
                _goto!(n_moves)
            end
        end
    end

    # ------------------------------------------------------------------
    # Launch at move 0
    # ------------------------------------------------------------------
    _goto!(0)
    display(fig)
    return fig
end
