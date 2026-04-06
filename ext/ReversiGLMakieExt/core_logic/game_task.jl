struct NamedPlayerEntry
    name::String
    factory::Function
end

const _BUILTIN_PLAYERS = [
    NamedPlayerEntry("Human",     () -> HumanPlayer()),
    NamedPlayerEntry("Random AI", () -> RandomPlayer()),
    NamedPlayerEntry("Greedy AI", () -> GreedyPlayer()),
]

function _get_player_by_name(name::String)
    idx = findfirst(e -> e.name == name, _BUILTIN_PLAYERS)
    return isnothing(idx) ? HumanPlayer() : _BUILTIN_PLAYERS[idx].factory()
end

function _selected_player(menu::Menu, registry::Vector{NamedPlayerEntry})
    idx = clamp(menu.i_selected[], 1, length(registry))
    return registry[idx].factory()
end

# ---------------------------------------------------------------------------
# Async game loop
# ---------------------------------------------------------------------------

function run_game!(
    game_ref::Ref{ReversiGame},
    kifu_ref::Ref{Vector{Tuple{Int,Int,String}}},
    players::Ref{Dict{Int,Player}},
    game_obs::Observable,
    kifu_obs::Observable,
    last_move_obs::Observable,
    game_over_obs::Observable{Bool},
)
    try
        game = game_ref[]
        while !is_game_over(game)
            yield()
            color = game.current_player
            move  = get_move(players[][color], game)
            if move === nothing
                push!(kifu_ref[], (length(kifu_ref[])+1, color, "pass"))
                pass!(game)
                last_move_obs[] = nothing
            else
                push!(kifu_ref[], (length(kifu_ref[])+1, color, position_to_string(move)))
                make_move!(game, move.row, move.col)
                last_move_obs[] = move
            end
            kifu_obs[]  = copy(kifu_ref[])
            game_obs[]  = deepcopy(game)
        end
        game_over_obs[] = true
    catch e
        e isa InvalidStateException && return   # channel closed intentionally
        @error "Error in game task" exception=(e, catch_backtrace())
    end
end
