module Reversi

# Export main types and functions
export ReversiGame, Player, Position
export make_move!, valid_moves, is_game_over, get_winner, display_board
export HumanPlayer, RandomPlayer, play_game
export next_state, get_piece, count_pieces, pass!
export position_to_string, ZOBRIST_TABLE, compute_full_hash, update_hash
export GameRecord, save_game, load_game, replay_game
export GUIPlayer, launch_gui, launch_replay_gui
export WThorHeader, WThorGame, read_wthor, write_wthor
export wthor_game_to_record, verify_wthor_game

include("core/struct.jl")
include("core/player.jl")
include("core/rules.jl")
include("core/wthor.jl")
include("UI/game.jl")
include("UI/data.jl")
include("UI/gui.jl")

end # module Reversi
