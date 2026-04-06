module ReversiGLMakieExt

using Reversi
using Reversi:
    BLACK,
    WHITE,
    Position,
    ReversiGame,
    Player,
    HumanPlayer,
    RandomPlayer,
    GreedyPlayer,
    GameRecord
using Reversi:
    valid_moves,
    make_move!,
    is_game_over,
    get_winner,
    count_pieces,
    pass!,
    get_move,
    position_to_string
using GLMakie

# ---------------------------------------------------------------------------
# Dynamic settings helper
# ---------------------------------------------------------------------------

function _get_color(config::GUIConfig, key::String)
    hex = get(config.colors, key, "#000000")
    c = Reversi.parse_color(hex)
    return length(c) == 3 ? RGBf(c...) : RGBAf(c...)
end

# ---------------------------------------------------------------------------
# Board constants
# ---------------------------------------------------------------------------

const _BOARD_SIZE = 8

_board_to_xy(row, col) = (col - 0.5, _BOARD_SIZE - row + 0.5)

# ---------------------------------------------------------------------------
# Board drawing helpers
# ---------------------------------------------------------------------------

function _draw_board!(ax, config::GUIConfig)
    c_board = _get_color(config, "board")
    c_grid = _get_color(config, "grid")
    c_text = _get_color(config, "text")

    poly!(ax, Point2f[(0, 0), (8, 0), (8, 8), (0, 8)]; color=c_board, strokewidth=0)
    for i in 0:_BOARD_SIZE
        lines!(ax, [i, i], [0, 8]; color=c_grid, linewidth=1.0)
        lines!(ax, [0, 8], [i, i]; color=c_grid, linewidth=1.0)
    end
    for (r, c) in [(3, 3), (3, 6), (6, 3), (6, 6)]
        x, y = _board_to_xy(r, c)
        scatter!(ax, [x], [y]; color=c_grid, markersize=8)
    end
    for (i, ch) in enumerate('a':'h')
        text!(
            ax,
            i - 0.5,
            8.18;
            text=string(ch),
            color=c_text,
            fontsize=config.fontsize + 1,
            align=(:center, :bottom),
        )
    end
    for r in 1:8
        text!(
            ax,
            -0.18,
            8 - r + 0.5;
            text=string(r),
            color=c_text,
            fontsize=config.fontsize + 1,
            align=(:right, :center),
        )
    end
end

function _draw_pieces!(
    ax,
    game::ReversiGame,
    px_per_unit::Real,
    config::GUIConfig,
    last_move::Union{Position,Nothing}=nothing,
)
    c_black = _get_color(config, "black_piece")
    c_white = _get_color(config, "white_piece")
    c_last = _get_color(config, "last_move")

    black_pts = Point2f[]
    white_pts = Point2f[]
    for row in 1:8, col in 1:8
        piece = Reversi.get_piece(game, row, col)
        x, y = _board_to_xy(row, col)
        if piece == BLACK
            push!(black_pts, Point2f(x, y))
        elseif piece == WHITE
            push!(white_pts, Point2f(x, y))
        end
    end
    r = 0.44
    ms = r * 2 * px_per_unit
    isempty(black_pts) || scatter!(
        ax,
        black_pts;
        color=c_black,
        markersize=ms,
        strokecolor=_get_color(config, "text_dim"),
        strokewidth=2.0,
    )
    isempty(white_pts) || scatter!(
        ax,
        white_pts;
        color=c_white,
        markersize=ms,
        strokecolor=_get_color(config, "text_dim"),
        strokewidth=2.0,
    )
    if last_move !== nothing
        c0 = last_move.col - 1
        r0 = _BOARD_SIZE - last_move.row
        lines!(
            ax,
            [c0, c0 + 1, c0 + 1, c0, c0],
            [r0, r0, r0 + 1, r0 + 1, r0];
            color=c_last,
            linewidth=3.5,
        )
    end
end

function _draw_hints!(ax, game::ReversiGame, px_per_unit::Real, config::GUIConfig)
    moves = valid_moves(game)
    isempty(moves) && return nothing
    pts = [Point2f(_board_to_xy(m.row, m.col)...) for m in moves]
    c_hint = _get_color(config, "hint")
    return scatter!(ax, pts; color=c_hint, markersize=0.18 * 2 * px_per_unit, strokewidth=0)
end

# ---------------------------------------------------------------------------
# Player name helper
# ---------------------------------------------------------------------------

_player_name(::HumanPlayer) = "Human"
_player_name(::RandomPlayer) = "Random AI"
_player_name(::GreedyPlayer) = "Greedy AI"
_player_name(p::Player) = string(typeof(p))

# ---------------------------------------------------------------------------
# Player registry
# ---------------------------------------------------------------------------

struct NamedPlayerEntry
    name::String
    factory::Function
end

const _BUILTIN_PLAYERS = [
    NamedPlayerEntry("Human", () -> HumanPlayer()),
    NamedPlayerEntry("Random AI", () -> RandomPlayer()),
    NamedPlayerEntry("Greedy AI", () -> GreedyPlayer()),
]

function _get_player_by_name(name::String)
    idx = findfirst(e -> e.name == name, _BUILTIN_PLAYERS)
    return isnothing(idx) ? HumanPlayer() : _BUILTIN_PLAYERS[idx].factory()
end

# ---------------------------------------------------------------------------
# Add-Player dialog
# ---------------------------------------------------------------------------

function _open_add_player_dialog!(
    registry_obs::Observable, update_cb::Function, config::GUIConfig
)
    dlg = Figure(; size=(480, 240), backgroundcolor=_get_color(config, "background"))

    c_text = _get_color(config, "text")
    c_text_dim = _get_color(config, "text_dim")
    c_panel = _get_color(config, "panel")
    c_accent = _get_color(config, "accent_black")
    fs = config.fontsize

    Label(
        dlg[1, 1:2];
        text="Register Custom Player",
        color=c_text,
        fontsize=fs + 2,
        font=:bold,
        halign=:center,
    )

    Label(dlg[2, 1]; text="Name:", color=c_text_dim, fontsize=fs, halign=:right)
    name_tb = Textbox(dlg[2, 2]; placeholder="e.g. My AI", fontsize=fs, width=300)

    Label(dlg[3, 1]; text="Expression:", color=c_text_dim, fontsize=fs, halign=:right)
    expr_tb = Textbox(dlg[3, 2]; placeholder="e.g. MyPlayer()", fontsize=fs, width=300)

    msg_lbl = Label(
        dlg[4, 1:2]; text="", color=_get_color(config, "last_move"), fontsize=fs - 2
    )

    btn_row = dlg[5, 1:2] = GridLayout()
    btn_cancel = Button(
        btn_row[1, 1];
        label="Cancel",
        buttoncolor=c_panel,
        labelcolor=c_text_dim,
        fontsize=fs,
    )
    btn_reg = Button(
        btn_row[1, 2];
        label="✔ Register",
        buttoncolor=c_panel,
        labelcolor=c_accent,
        fontsize=fs,
    )

    on(btn_cancel.clicks) do _
        close(dlg.scene)
    end

    on(btn_reg.clicks) do _
        raw_name = strip(name_tb.stored_string[])
        raw_expr = strip(expr_tb.stored_string[])
        isempty(raw_name) && (msg_lbl.text[] = "⚠ Please enter a name."; return nothing)
        isempty(raw_expr) &&
            (msg_lbl.text[] = "⚠ Please enter a Julia expression."; return nothing)

        local player_instance
        try
            # Evaluate in Main for custom types defined by user
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

        # Capture the expression for factory
        expr_str = raw_expr
        entry = NamedPlayerEntry(String(raw_name), () -> Main.eval(Meta.parse(expr_str)))
        registry_obs[] = vcat(registry_obs[], [entry])
        update_cb()
        close(dlg.scene)
    end

    display(dlg)
    return dlg
end

# ---------------------------------------------------------------------------
# launch_gui
# ---------------------------------------------------------------------------

function Reversi.launch_gui(
    black::Union{Player,Nothing}=nothing,
    white::Union{Player,Nothing}=nothing;
    show_hints::Union{Bool,Nothing}=nothing,
)
    config = load_config()

    # Resolve players from config if not provided
    b_player = isnothing(black) ? _get_player_by_name(config.black_player) : black
    w_player = isnothing(white) ? _get_player_by_name(config.white_player) : white

    # Overrides from arguments if provided
    sh = isnothing(show_hints) ? config.show_hints : show_hints

    game_obs = Observable(ReversiGame())
    hints_obs = Observable(sh)
    game_over_obs = Observable(false)
    last_move_obs = Observable{Union{Position,Nothing}}(nothing)
    show_last_obs = Observable(config.show_last_move)
    kifu_obs = Observable(Tuple{Int,Int,String}[])
    registry_obs = Observable(copy(_BUILTIN_PLAYERS))

    fig = Figure(;
        size=(config.window_width, config.window_height),
        backgroundcolor=_get_color(config, "background"),
    )

    # Row 1: player selection bar
    sel_bar = fig[1, 1] = GridLayout()
    _names(reg) = [e.name for e in reg]
    function _find_idx(reg, p)
        p isa HumanPlayer && return 1
        p isa RandomPlayer &&
            return something(findfirst(e -> e.name == "Random AI", reg), 1)
        return 1
    end

    init_reg = registry_obs[]
    menu_options_obs = Observable(_names(init_reg))
    on(registry_obs) do reg
        menu_options_obs[] = _names(reg)
    end

    black_sel = Menu(
        sel_bar[1, 2];
        options=menu_options_obs,
        i_selected=_find_idx(init_reg, b_player),
        fontsize=13,
        width=160,
    )
    white_sel = Menu(
        sel_bar[1, 4];
        options=menu_options_obs,
        i_selected=_find_idx(init_reg, w_player),
        fontsize=13,
        width=160,
    )

    Label(
        sel_bar[1, 1];
        text="Black:",
        color=_get_color(config, "accent_black"),
        fontsize=config.fontsize - 1,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    Label(
        sel_bar[1, 3];
        text="White:",
        color=_get_color(config, "accent_white"),
        fontsize=config.fontsize - 1,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    btn_add = Button(
        sel_bar[1, 5];
        label="+ Add Player",
        buttoncolor=_get_color(config, "panel"),
        labelcolor=_get_color(config, "text"),
        fontsize=config.fontsize - 1,
    )
    btn_start = Button(
        sel_bar[1, 6];
        label="▶ New Game",
        buttoncolor=_get_color(config, "panel"),
        labelcolor=_get_color(config, "text"),
        fontsize=config.fontsize - 1,
    )
    rowsize!(fig.layout, 1, Fixed(44))
    colgap!(sel_bar, 6)
    colsize!(sel_bar, 1, Fixed(50))
    colsize!(sel_bar, 3, Fixed(50))

    # Row 2: white player info
    white_card = fig[2, 1] = GridLayout()
    white_name_lbl = Label(
        white_card[1, 1];
        text="[W]  White: $(_player_name(w_player))",
        color=_get_color(config, "accent_white"),
        fontsize=config.fontsize + 1,
        halign=:left,
        tellwidth=false,
    )
    white_score_lbl = Label(
        white_card[1, 2];
        text=@lift("$(count_pieces($game_obs)[2])"),
        color=_get_color(config, "text"),
        fontsize=config.fontsize + 6,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    white_turn_lbl = Label(
        white_card[1, 3];
        text=@lift((!$game_over_obs && $game_obs.current_player == WHITE) ? "< Turn" : ""),
        color=_get_color(config, "accent_white"),
        fontsize=config.fontsize - 1,
        halign=:left,
        tellwidth=false,
    )
    rowsize!(fig.layout, 2, Fixed(40))

    # Row 3: board
    ax = Axis(
        fig[3, 1];
        aspect=DataAspect(),
        limits=(-0.40, 8.32, -0.24, 8.55),
        backgroundcolor=_get_color(config, "background"),
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

    # Row 4: black player info
    black_card = fig[4, 1] = GridLayout()
    black_name_lbl = Label(
        black_card[1, 1];
        text="[B]  Black: $(_player_name(b_player))",
        color=_get_color(config, "accent_black"),
        fontsize=config.fontsize + 1,
        halign=:left,
        tellwidth=false,
    )
    black_score_lbl = Label(
        black_card[1, 2];
        text=@lift("$(count_pieces($game_obs)[1])"),
        color=_get_color(config, "text"),
        fontsize=config.fontsize + 6,
        font=:bold,
        halign=:right,
        tellwidth=false,
    )
    black_turn_lbl = Label(
        black_card[1, 3];
        text=@lift((!$game_over_obs && $game_obs.current_player == BLACK) ? "< Turn" : ""),
        color=_get_color(config, "accent_black"),
        fontsize=config.fontsize - 1,
        halign=:left,
        tellwidth=false,
    )
    rowsize!(fig.layout, 4, Fixed(40))

    # Row 5: control bar
    ctrl = fig[5, 1] = GridLayout()
    tgl_hints = Toggle(ctrl[1, 1]; active=sh)
    Label(
        ctrl[1, 2];
        text="Hints",
        color=_get_color(config, "text_dim"),
        fontsize=config.fontsize - 1,
    )
    tgl_last = Toggle(ctrl[1, 3]; active=config.show_last_move)
    Label(
        ctrl[1, 4];
        text="Last Move",
        color=_get_color(config, "text_dim"),
        fontsize=config.fontsize - 1,
    )
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
        color=@lift(
            if $game_over_obs
                _get_color(config, "last_move")
            else
                _get_color(config, "text_dim")
            end
        ),
        fontsize=config.fontsize,
        halign=:left,
        tellwidth=false,
    )
    rowsize!(fig.layout, 5, Fixed(44))
    colsize!(ctrl, 5, Relative(1.0))

    # Kifu sidebar
    kifu_panel = fig[1:5, 2] = GridLayout()
    Label(
        kifu_panel[1, 1];
        text="Move History",
        color=_get_color(config, "text"),
        fontsize=config.fontsize,
        font=:bold,
        halign=:center,
    )
    kifu_ax = Axis(
        kifu_panel[2, 1];
        backgroundcolor=_get_color(config, "panel"),
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

    colsize!(fig.layout, 1, Relative(1.0))
    if config.show_kifu
        colsize!(fig.layout, 2, Fixed(config.sidebar_width))
    else
        colsize!(fig.layout, 2, Fixed(0))
        # Hide the kifu panel entirely
        kifu_panel.visible = false
    end
    rowsize!(fig.layout, 3, Relative(1.0))

    _px_per_unit() = begin
        v = ax.scene.viewport[]
        return max(1.0, v.widths[1] / 8.0)
    end

    function _refresh!(ax, game, show_h, last_move)
        ppu = _px_per_unit()
        empty!(ax)
        _draw_board!(ax, config)
        _draw_pieces!(ax, game, ppu, config, (show_last_obs[] ? last_move : nothing))
        return show_h && !game_over_obs[] && _draw_hints!(ax, game, ppu, config)
    end

    function _refresh_kifu!(kifu_ax, kifu)
        empty!(kifu_ax)
        c_text = _get_color(config, "text")
        c_text_dim = _get_color(config, "text_dim")
        c_accent_b = _get_color(config, "accent_black")

        if isempty(kifu)
            text!(
                kifu_ax,
                0.5,
                0.5;
                text="No moves yet",
                color=c_text_dim,
                fontsize=config.fontsize - 2,
                align=(:center, :center),
                space=:relative,
            )
            ylims!(kifu_ax, 1, 0)
            return nothing
        end
        for (n, color, notation) in kifu
            pc_tag = color == BLACK ? "[B]" : "[W]"
            line_color = color == BLACK ? c_accent_b : c_text
            text!(
                kifu_ax,
                0.05,
                Float32(n - 1);
                text=lpad(string(n), 3),
                color=c_text_dim,
                fontsize=config.fontsize - 2,
                align=(:left, :top),
            )
            text!(
                kifu_ax,
                0.35,
                Float32(n - 1);
                text="$pc_tag  $notation",
                color=line_color,
                fontsize=config.fontsize - 2,
                align=(:left, :top),
            )
        end
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
        # Save to session config
        config.show_hints = v
        save_session_config(config)
        _refresh!(ax, game_obs[], v, last_move_obs[])
    end
    on(tgl_last.active) do v
        show_last_obs[] = v
        # Save to session config
        config.show_last_move = v
        save_session_config(config)
        _refresh!(ax, game_obs[], hints_obs[], last_move_obs[])
    end
    on(ax.scene.viewport) do _
        _refresh!(ax, game_obs[], hints_obs[], last_move_obs[])
    end

    players = Ref{Dict{Int,Player}}(Dict(BLACK => b_player, WHITE => w_player))

    function _selected_player(menu::Menu)
        reg = registry_obs[]
        idx = clamp(menu.i_selected[], 1, length(reg))
        return reg[idx].factory()
    end

    function run_game!(game_ref, kifu_ref)
        try
            game = game_ref[]
            while !is_game_over(game)
                yield()
                color = game.current_player
                move = get_move(players[][color], game)
                if move === nothing
                    push!(kifu_ref[], (length(kifu_ref[]) + 1, color, "pass"))
                    pass!(game)
                    last_move_obs[] = nothing
                else
                    push!(
                        kifu_ref[],
                        (length(kifu_ref[]) + 1, color, position_to_string(move)),
                    )
                    make_move!(game, move.row, move.col)
                    last_move_obs[] = move
                end
                kifu_obs[] = copy(kifu_ref[])
                game_obs[] = deepcopy(game)
            end
            game_over_obs[] = true
            _refresh!(ax, game, false, last_move_obs[])
            _refresh_kifu!(kifu_ax, kifu_obs[])
        catch e
            if !(e isa InvalidStateException) # Ignore if channel was closed intentionally
                @error "Error in Reversi game task" exception = (e, catch_backtrace())
            end
        end
    end

    current_task = Ref{Union{Task,Nothing}}(nothing)

    function start_game!(new_black::Player, new_white::Player)

        # Close channels of OLD players that are no longer in use
        old_players = players[]
        for p in values(old_players)
            if p isa HumanPlayer && isopen(p.move_channel)
                # Only close if it's NOT one of the new players
                if p !== new_black && p !== new_white
                    close(p.move_channel)
                end
            end
        end

        players[] = Dict{Int,Player}(BLACK => new_black, WHITE => new_white)
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

    on(btn_start.clicks) do _
        start_game!(_selected_player(black_sel), _selected_player(white_sel))
    end
    on(btn_add.clicks) do _
        _open_add_player_dialog!(registry_obs, () -> nothing, config)
    end

    register_interaction!(ax, :board_click) do event::MouseEvent, _
        event.type == MouseEventTypes.leftclick || return nothing
        game = game_obs[]
        game_over_obs[] && return nothing

        # Ensure we are within board bounds (0 to 8 in data coords)
        x, y = event.data
        (0 <= x <= 8 && 0 <= y <= 8) || return nothing

        col = Int(floor(x)) + 1
        row = _BOARD_SIZE - Int(floor(y))
        # Extra safety for the upper bound (exactly 8.0)
        col = clamp(col, 1, 8)
        row = clamp(row, 1, 8)

        cp = players[][game.current_player]
        if cp isa HumanPlayer && isopen(cp.move_channel)
            put!(cp.move_channel, Position(row, col))
        end
    end

    _refresh_kifu!(kifu_ax, Tuple{Int,Int,String}[])
    _refresh!(ax, game_obs[], sh, nothing)

    if !isinteractive()
        display(fig)
    end

    # Give the GUI a moment to initialize before starting the game
    Timer(0.1) do _
        start_game!(b_player, w_player)
    end

    return fig
end

# ---------------------------------------------------------------------------
# launch_replay_gui
# ---------------------------------------------------------------------------

function Reversi.launch_replay_gui(record::GameRecord; title::String="Game Replay")
    return Reversi.launch_replay_gui(record.moves; title=title)
end

function Reversi.launch_replay_gui(moves::Vector{String}; title::String="Game Replay")
    # Pre-compute all board states
    states = Vector{ReversiGame}(undef, length(moves) + 1)
    move_colors = Vector{Int}(undef, length(moves))
    states[1] = ReversiGame()
    for (i, m) in enumerate(moves)
        g = deepcopy(states[i])
        move_colors[i] = g.current_player
        m == "pass" ? pass!(g) : make_move!(g, m)
        states[i + 1] = g
    end
    n_moves = length(moves)

    pos_obs = Observable(0)
    game_obs = Observable(states[1])
    show_last_obs = Observable(true)
    last_move_obs = Observable{Union{Position,Nothing}}(nothing)

    config = load_config()
    fig = Figure(;
        size=(config.window_width, config.window_height),
        backgroundcolor=_get_color(config, "background"),
    )

    # Title bar
    Label(
        fig[1, 1];
        text=title,
        color=_get_color(config, "text"),
        fontsize=config.fontsize + 1,
        font=:bold,
        halign=:left,
        tellwidth=false,
    )
    Label(
        fig[1, 1];
        text=@lift(
            begin
                g = $game_obs
                b, w = count_pieces(g)
                "B $b – W $w"
            end
        ),
        color=_get_color(config, "text_dim"),
        fontsize=config.fontsize,
        halign=:right,
        tellwidth=false,
    )
    rowsize!(fig.layout, 1, Fixed(36))

    # Board
    ax = Axis(
        fig[2, 1];
        aspect=DataAspect(),
        limits=(-0.40, 8.32, -0.24, 8.55),
        backgroundcolor=_get_color(config, "background"),
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

    # Navigation bar
    nav = fig[3, 1] = GridLayout()
    btn_first = Button(
        nav[1, 1];
        label="|◀",
        buttoncolor=_get_color(config, "panel"),
        labelcolor=_get_color(config, "text"),
        fontsize=config.fontsize,
        width=44,
    )
    btn_prev = Button(
        nav[1, 2];
        label="◀",
        buttoncolor=_get_color(config, "panel"),
        labelcolor=_get_color(config, "text"),
        fontsize=config.fontsize,
        width=44,
    )
    btn_next = Button(
        nav[1, 3];
        label="▶",
        buttoncolor=_get_color(config, "panel"),
        labelcolor=_get_color(config, "text"),
        fontsize=config.fontsize,
        width=44,
    )
    btn_last = Button(
        nav[1, 4];
        label="▶|",
        buttoncolor=_get_color(config, "panel"),
        labelcolor=_get_color(config, "text"),
        fontsize=config.fontsize,
        width=44,
    )
    slider = Slider(nav[1, 5]; range=0:n_moves, startvalue=0)
    Label(
        nav[1, 6];
        text=@lift("Move $($pos_obs) / $n_moves"),
        color=_get_color(config, "text_dim"),
        fontsize=config.fontsize - 1,
        halign=:left,
        tellwidth=false,
    )
    tgl_last = Toggle(nav[1, 7]; active=config.show_last_move)
    Label(
        nav[1, 8];
        text="Last Move",
        color=_get_color(config, "text_dim"),
        fontsize=config.fontsize - 2,
    )
    rowsize!(fig.layout, 3, Fixed(48))
    colsize!(nav, 5, Relative(1.0))

    # Kifu sidebar
    kifu_panel = fig[1:3, 2] = GridLayout()
    Label(
        kifu_panel[1, 1];
        text="Move History",
        color=_get_color(config, "text"),
        fontsize=config.fontsize,
        font=:bold,
        halign=:center,
    )
    kifu_ax = Axis(
        kifu_panel[2, 1];
        backgroundcolor=_get_color(config, "panel"),
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
    colsize!(fig.layout, 1, Relative(1.0))
    colsize!(fig.layout, 2, Fixed(config.sidebar_width))
    rowsize!(fig.layout, 2, Relative(1.0))

    _px_per_unit_replay() = ax.scene.viewport[].widths[1] / 8.0

    function _refresh_board!(p)
        ppu = _px_per_unit_replay()
        empty!(ax)
        _draw_board!(ax, config)
        lm = (show_last_obs[] && p > 0 && moves[p] != "pass") ? Position(moves[p]) : nothing
        return _draw_pieces!(ax, states[p + 1], ppu, config, lm)
    end

    function _refresh_replay_kifu!(current_p)
        empty!(kifu_ax)
        c_text = _get_color(config, "text")
        c_text_dim = _get_color(config, "text_dim")
        c_accent_b = _get_color(config, "accent_black")

        n = length(moves)
        if n == 0
            text!(
                kifu_ax,
                0.5,
                0.5;
                text="No moves",
                color=c_text_dim,
                fontsize=config.fontsize - 2,
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
                RGBf(1.0, 0.85, 0.2) # Active move highlight
            elseif color == BLACK
                c_accent_b
            else
                c_text
            end
            text!(
                kifu_ax,
                0.05,
                Float32(i - 1);
                text=lpad(string(i), 3),
                color=c_text_dim,
                fontsize=config.fontsize - 2,
                align=(:left, :top),
            )
            text!(
                kifu_ax,
                0.35,
                Float32(i - 1);
                text="$pc_tag  $(moves[i])",
                color=row_color,
                fontsize=config.fontsize - 2,
                font=is_current ? :bold : :regular,
                align=(:left, :top),
            )
        end
        ylims!(kifu_ax, n + 0.5, -0.5)
        return xlims!(kifu_ax, 0, 1)
    end

    function _goto!(p)
        p = clamp(p, 0, n_moves)
        pos_obs[] = p
        game_obs[] = states[p + 1]
        slider.value[] = p
        _refresh_board!(p)
        return _refresh_replay_kifu!(p)
    end

    on(tgl_last.active) do v
        show_last_obs[] = v
        _refresh_board!(pos_obs[])
    end
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
    on(slider.value) do v
        v == pos_obs[] && return nothing
        _goto!(v)
    end

    on(events(fig.scene).keyboardbutton) do event
        (event.action == Keyboard.press || event.action == Keyboard.repeat) ||
            return nothing
        event.key == Keyboard.left && _goto!(pos_obs[] - 1)
        event.key == Keyboard.right && _goto!(pos_obs[] + 1)
        event.key == Keyboard.home && _goto!(0)
        event.key == Keyboard.end_ && _goto!(n_moves)
    end

    _goto!(0)
    display(fig)
    return fig
end

end # module ReversiGLMakieExt
