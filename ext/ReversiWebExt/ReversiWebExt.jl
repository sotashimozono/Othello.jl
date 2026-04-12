module ReversiWebExt

using Reversi
using Oxygen
using HTTP
using JSON3
using DefaultApplication
using TOML

# Import necessary types/functions from Reversi (or use qualified names)
import Reversi: launch_gui, Position, ReversiGame, count_pieces, valid_moves, 
                is_game_over, get_winner, board_to_matrix, make_move!, pass!, 
                position_to_string, RandomPlayer, GreedyPlayer, get_move, EMPTY

"""
    launch_gui(:web; port=8080, open_browser=true)

Implementation of the web UI launcher under the unified launch_gui API.
"""
function Reversi.launch_gui(::Val{:web}; port::Int=8080, open_browser::Bool=true)
    # 1. State initialization (using Ref to allow resetting from closures)
    game_ref = Ref(ReversiGame())
    history = String[]
    
    # Path to frontend public build
    # Assuming the app is installed, we find the project root
    pkg_root = joinpath(@__DIR__, "..", "..")
    frontend_dir = joinpath(pkg_root, "web", "frontend", "dist")
    config_path = joinpath(pkg_root, "config", "default_config.toml")

    # 2. API Endpoints
    @get "/api/config" function(req::HTTP.Request)
        if isfile(config_path)
            return TOML.parsefile(config_path)
        else
            return Dict()
        end
    end

    @get "/api/game/state" function(req::HTTP.Request)
        params = queryparams(req)
        index_str = get(params, "index", nothing)
        
        target_game = game_ref[]
        is_replay = false
        
        if index_str !== nothing
            idx = tryparse(Int, index_str)
            if idx !== nothing && 0 <= idx <= length(history)
                # Reconstruct game state for replay
                target_game = ReversiGame()
                for i in 1:idx
                    move_str = history[i]
                    if move_str == "pass"
                        pass!(target_game; force=true)
                    else
                        pos = Position(move_str)
                        make_move!(target_game, pos.row, pos.col)
                    end
                end
                is_replay = true
            end
        end

        b_count, w_count = count_pieces(target_game)
        v_moves = is_replay ? Position[] : valid_moves(target_game)
        
        game_status = is_game_over(target_game) ? "finished" : "playing"
        winner = game_status == "finished" ? get_winner(target_game) : EMPTY
        
        return Dict(
            "board" => board_to_matrix(target_game, flip_for_current=false),
            "current_player" => target_game.current_player,
            "black_score" => b_count,
            "white_score" => w_count,
            "status" => game_status,
            "winner" => winner,
            "valid_moves" => [[m.row, m.col] for m in v_moves],
            "history" => history,
            "viewing_index" => index_str === nothing ? length(history) : parse(Int, index_str)
        )
    end

    @post "/api/game/move" function(req::HTTP.Request)
        game = game_ref[]
        body = JSON3.read(req.body)
        row = Int(body.row)
        col = Int(body.col)
        
        if make_move!(game, row, col)
            push!(history, position_to_string(Position(row, col)))
            
            # Auto-pass logic
            _handle_auto_passes!(game, history)
            
            return Dict("status" => "success")
        else
            return HTTP.Response(400, "Invalid move")
        end
    end

    @get "/api/game/ai_move" function(req::HTTP.Request)
        params = queryparams(req)
        ai_type = get(params, "type", "greedy")
        
        game = game_ref[]
        player = ai_type == "random" ? RandomPlayer() : GreedyPlayer()
        
        move = get_move(player, game)
        
        if move === nothing
            if !is_game_over(game)
                pass!(game; force=false)
                push!(history, "pass")
            end
        else
            make_move!(game, move.row, move.col)
            push!(history, position_to_string(move))
        end
        
        _handle_auto_passes!(game, history)
            
        return Dict("status" => "success")
    end

    @post "/api/game/reset" function(req::HTTP.Request)
        game_ref[] = ReversiGame()
        empty!(history)
        return Dict("status" => "success")
    end

    # 3. CORS & Response Middleware
    function cors_middleware(handler)
        return function(req::HTTP.Request)
            if HTTP.method(req) == "OPTIONS"
                return HTTP.Response(200, [
                    "Access-Control-Allow-Origin" => "*",
                    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
                    "Access-Control-Allow-Headers" => "*",
                    "Access-Control-Max-Age" => "86400"
                ])
            end
            response = handler(req)
            res = response isa HTTP.Response ? response : HTTP.Response(200, JSON3.write(response))
            HTTP.setheader(res, "Access-Control-Allow-Origin" => "*")
            if !(response isa HTTP.Response)
                HTTP.setheader(res, "Content-Type" => "application/json")
            end
            return res
        end
    end

    # 4. Starting the server
    @info "Starting local Reversi Server on http://localhost:$port"
    
    if open_browser
        @async begin
            sleep(1.0)
            try
                DefaultApplication.open("http://localhost:$port")
            catch e
                @warn "Could not automatically open browser: $e"
            end
        end
    end

    # Static file serving
    if isdir(frontend_dir)
        Oxygen.staticfiles(frontend_dir, "/")
    else
        @warn "Frontend build not found at $frontend_dir. API-only mode."
        @get "/" function(req::HTTP.Request)
            return "<h1>Reversi.jl API Server</h1><p>Frontend build not found. Please run <code>npm run build</code> in <code>web/frontend/</code>.</p>"
        end
    end

    serve(host="0.0.0.0", port=port, middleware=[cors_middleware])
end

# Internal helper for auto-passing
function _handle_auto_passes!(game, history)
    while !is_game_over(game) && isempty(valid_moves(game))
        pass!(game; force=false)
        push!(history, "pass")
    end
end

end # module
