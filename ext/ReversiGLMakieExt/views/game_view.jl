function Reversi.launch_gui(
    black::Union{Player,Nothing}=nothing,
    white::Union{Player,Nothing}=nothing;
    show_hints::Union{Bool,Nothing}=nothing,
)
    config = load_config()
    b_player = isnothing(black) ? _get_player_by_name(config.black_player) : black
    w_player = isnothing(white) ? _get_player_by_name(config.white_player) : white
    sh = isnothing(show_hints) ? config.show_hints : show_hints

    # ---------------------------------------------------------------------------
    # Observables
    # ---------------------------------------------------------------------------
    game_obs = Observable(ReversiGame())
    hints_obs = Observable(sh)
    game_over_obs = Observable(false)
    last_move_obs = Observable{Union{Position,Nothing}}(nothing)
    show_last_obs = Observable(config.show_last_move)
    kifu_obs = Observable(Tuple{Int,Int,String}[])
    registry_obs = Observable(copy(_BUILTIN_PLAYERS))
    players = Ref{Dict{Int,Player}}(Dict(BLACK => b_player, WHITE => w_player))

    # ---------------------------------------------------------------------------
    # Figure & layout
    # ---------------------------------------------------------------------------
    fig = Figure(;
        size=(config.window_width, config.window_height),
        backgroundcolor=_get_color(config, "background"),
    )
    content_grid = fig[1, 1] = GridLayout(; halign=:center, tellwidth=false)

    # -- Menu bar (row 1) --
    menu_bar = content_grid[1, 1:2] = GridLayout(; valign=:top)
    action_menu = Menu(
        menu_bar[1, 1];
        options=["▶ New Game", "+ Add Player"],
        textcolor=_get_color(config, "text"),
        fontsize=(config.fontsize - 2),
        width=100,
        height=24,
        prompt="Actions",
        selection_cell_color_inactive=_get_color(config, "panel"),
    )
    colsize!(menu_bar, 1, Fixed(120))
    rowsize!(content_grid, 1, Fixed(30))

    # -- Main content area (row 2) --
    main_row = content_grid[2, 1:2] = GridLayout(; valign=:center)
    main_col = main_row[1, 1] = GridLayout()
    rsb = main_row[1, 2] = GridLayout(; valign=:top)
    colsize!(main_row, 1, Fixed(550))
    colsize!(main_row, 2, Fixed(200))
    rowsize!(content_grid, 2, Relative(1.0))

    # -- Player selection menus --
    menu_options_obs = Observable([e.name for e in registry_obs[]])
    on(registry_obs) do reg
        menu_options_obs[] = [e.name for e in reg]
    end

    function _find_idx(reg, p)
        p isa HumanPlayer && return 1
        idx = findfirst(e -> e.name == "Random AI", reg)
        p isa RandomPlayer && return something(idx, 1)
        return 1
    end

    menu_row = main_col[1, 1] = GridLayout()
    Label(
        menu_row[1, 2:3],
        "BLACK";
        color=_get_color(config, "accent_black"),
        font=:bold,
        fontsize=10,
        halign=:center,
    )
    black_sel = Menu(
        menu_row[2, 2:3];
        options=menu_options_obs,
        i_selected=_find_idx(registry_obs[], b_player),
        fontsize=11,
        width=100,
        prompt="Human",
        selection_cell_color_inactive=_get_color(config, "accent_black"),
    )

    Label(
        menu_row[1, 6:7],
        "WHITE";
        color=_get_color(config, "accent_white"),
        font=:bold,
        fontsize=10,
        halign=:center,
    )
    white_sel = Menu(
        menu_row[2, 6:7];
        options=menu_options_obs,
        i_selected=_find_idx(registry_obs[], w_player),
        fontsize=11,
        width=100,
        prompt="Human",
        selection_cell_color_inactive=_get_color(config, "accent_white"),
    )
    rowsize!(main_col, 1, Fixed(48))

    # -- Board axis --
    ax = Axis(
        main_col[2, 1];
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

    # -- Score / status bar (row 3) --
    status_bar = main_col[3, 1] = GridLayout()
    Label(
        status_bar[1, 1];
        text=@lift("$(count_pieces($game_obs)[2])"),
        color=_get_color(config, "accent_white"),
        fontsize=(config.fontsize + 8),
        font=:bold,
        halign=:center,
    )
    Label(
        status_bar[1, 2];
        text=@lift("$(count_pieces($game_obs)[1])"),
        color=_get_color(config, "accent_black"),
        fontsize=(config.fontsize + 8),
        font=:bold,
        halign=:center,
    )
    Label(
        status_bar[1, 3];
        text=@lift(
            if $game_over_obs
                "Game Over"
            else
                ($game_obs.current_player == BLACK ? "Black's Turn" : "White's Turn")
            end
        ),
        color=_get_color(config, "text_dim"),
        fontsize=config.fontsize,
        halign=:center,
    )
    rowsize!(main_col, 3, Fixed(48))
    for c in 1:3
        colsize!(status_bar, c, Relative(1 / 3))
    end

    # -- Control toggles (row 4) --
    ctrl = main_col[4, 1] = GridLayout()
    tgl_hints = Toggle(ctrl[1, 1]; active=sh)
    Label(
        ctrl[1, 2];
        text="Hints",
        color=_get_color(config, "text_dim"),
        fontsize=(config.fontsize - 1),
    )
    tgl_last = Toggle(ctrl[1, 3]; active=config.show_last_move)
    Label(
        ctrl[1, 4];
        text="Last Move",
        color=_get_color(config, "text_dim"),
        fontsize=(config.fontsize - 1),
    )
    rowsize!(main_col, 2, Relative(1.0))
    rowsize!(main_col, 4, Fixed(40))
    colsize!(ctrl, 4, Relative(1.0))

    # -- Kifu sidebar --
    kifu_panel = rsb[1, 1] = GridLayout(; valign=:top)
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
        height=450,
        valign=:top,
    )
    rowsize!(rsb, 1, Fixed(500))

    # ---------------------------------------------------------------------------
    # Reactive updates
    # ---------------------------------------------------------------------------
    on(game_obs) do game
        _refresh_board!(
            ax, game, hints_obs[], show_last_obs[], last_move_obs[], game_over_obs[], config
        )
    end
    on(kifu_obs) do kifu
        _refresh_kifu!(kifu_ax, kifu, config)
    end
    on(tgl_hints.active) do v
        hints_obs[] = v
        config.show_hints = v
        save_session_config(config)
        _refresh_board!(
            ax, game_obs[], v, show_last_obs[], last_move_obs[], game_over_obs[], config
        )
    end
    on(tgl_last.active) do v
        show_last_obs[] = v
        config.show_last_move = v
        save_session_config(config)
        _refresh_board!(
            ax, game_obs[], hints_obs[], v, last_move_obs[], game_over_obs[], config
        )
    end
    on(ax.scene.viewport) do _
        _refresh_board!(
            ax,
            game_obs[],
            hints_obs[],
            show_last_obs[],
            last_move_obs[],
            game_over_obs[],
            config,
        )
    end

    # ---------------------------------------------------------------------------
    # Game session management
    # ---------------------------------------------------------------------------
    function start_game!(new_black::Player, new_white::Player)
        for p in values(players[])
            if p isa HumanPlayer &&
                isopen(p.move_channel) &&
                p !== new_black &&
                p !== new_white
                close(p.move_channel)
            end
        end
        players[] = Dict{Int,Player}(BLACK => new_black, WHITE => new_white)
        kifu_ref = Ref(Tuple{Int,Int,String}[])
        game_ref = Ref(ReversiGame())
        game_over_obs[] = false
        last_move_obs[] = nothing
        kifu_obs[] = kifu_ref[]
        game_obs[] = game_ref[]
        @async run_game!(
            game_ref, kifu_ref, players, game_obs, kifu_obs, last_move_obs, game_over_obs
        )
    end

    on(action_menu.selection) do sel
        if sel == "▶ New Game"
            start_game!(
                _selected_player(black_sel, registry_obs[]),
                _selected_player(white_sel, registry_obs[]),
            )
        elseif sel == "+ Add Player"
            _open_add_player_dialog!(registry_obs, () -> nothing, config)
        end
    end

    # ---------------------------------------------------------------------------
    # Interaction (Board Clicks)
    # ---------------------------------------------------------------------------
    register_interaction!(ax, :board_click) do event::MouseEvent, _
        event.type == MouseEventTypes.leftclick || return nothing
        game = game_obs[]
        game_over_obs[] && return nothing

        data_pos = event.data
        (0.0 <= data_pos[1] <= 8.0 && 0.0 <= data_pos[2] <= 8.0) || return nothing

        col = clamp(Int(floor(data_pos[1])) + 1, 1, 8)
        row = clamp(_BOARD_SIZE - Int(floor(data_pos[2])), 1, 8)

        cp = players[][game.current_player]
        if cp isa HumanPlayer && isopen(cp.move_channel)
            put!(cp.move_channel, Position(row, col))
        end
    end

    # ---------------------------------------------------------------------------
    # Initial render & game start
    # ---------------------------------------------------------------------------
    _refresh_kifu!(kifu_ax, Tuple{Int,Int,String}[], config)
    _refresh_board!(ax, game_obs[], sh, false, nothing, false, config)

    # Force display and wait for GL context to stabilize (macOS stability)
    display(fig)
    Timer(1.0) do _
        start_game!(b_player, w_player)
    end
    return fig
end
