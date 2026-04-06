# ---------------------------------------------------------------------------
# Unified kifu drawing
#
# entries : Vector{Tuple{move_n, color, notation}}
# active_n: highlight this move number (0 = none, used in live mode)
# ---------------------------------------------------------------------------

function _draw_kifu!(
    kifu_ax,
    entries::Vector{Tuple{Int,Int,String}},
    config::GUIConfig;
    active_n::Int = 0,
)
    empty!(kifu_ax)
    c_text     = _get_color(config, "text")
    c_text_dim = _get_color(config, "text_dim")
    c_accent_b = _get_color(config, "accent_black")
    c_active   = RGBf(1.0, 0.85, 0.2)
    fs = config.fontsize - 2

    if isempty(entries)
        text!(kifu_ax, 0.5, 0.5; text="No moves yet", color=c_text_dim,
              fontsize=fs, align=(:center, :center), space=:relative)
        ylims!(kifu_ax, 1, 0)
        return
    end

    for (n, color, notation) in entries
        pc_tag    = color == BLACK ? "[B]" : "[W]"
        is_active = (n == active_n)
        line_color = is_active ? c_active : (color == BLACK ? c_accent_b : c_text)
        text!(kifu_ax, 0.05, Float32(n - 1);
              text=lpad(string(n), 3),
              color=c_text_dim, fontsize=fs, align=(:left, :top))
        text!(kifu_ax, 0.35, Float32(n - 1);
              text="$pc_tag  $notation",
              color=line_color,
              fontsize=is_active ? fs + 1 : fs,
              font=is_active ? :bold : :regular,
              align=(:left, :top))
    end
    ylims!(kifu_ax, length(entries) + 0.5, -0.5)
    xlims!(kifu_ax, 0, 1)
end

# ---------------------------------------------------------------------------
# Coordinate helpers for kifu click detection
#
# kifu_ax has yreversed=true: the top of the viewport shows the first move
# (data_y ≈ 0) and the bottom shows the last move (data_y ≈ n-1).
# The standard Y-flip formula (used for the board) gives norm_y near 1 at
# the physical top. With yreversed we need an additional flip of norm_y.
# ---------------------------------------------------------------------------

function _kifu_move_at(kifu_ax, fig, win_pos)
    fig_vp = fig.scene.viewport[]
    ax_vp  = kifu_ax.scene.viewport[]

    gl_x = win_pos[1] - fig_vp.origin[1]
    gl_y = fig_vp.widths[2] - win_pos[2] - fig_vp.origin[2]

    dx = gl_x - ax_vp.origin[1]
    dy = gl_y - ax_vp.origin[2]
    (0 <= dx <= ax_vp.widths[1] && 0 <= dy <= ax_vp.widths[2]) || return 0

    # Flip norm_y to account for yreversed=true
    norm_y_rev = 1.0 - dy / ax_vp.widths[2]
    lims = kifu_ax.finallimits[]
    data_y = lims.origin[2] + norm_y_rev * lims.widths[2]
    return Int(floor(data_y)) + 1   # caller must clamp to [1, n_moves]
end
