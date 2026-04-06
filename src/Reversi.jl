module Reversi

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

# Core types & constants
export ReversiGame, Player, Position
export EMPTY, BLACK, WHITE, IN_PROGRESS

# Core game functions
export make_move!, valid_moves, is_game_over, get_winner
export HumanPlayer, RandomPlayer, GreedyPlayer
export next_state, get_piece, count_pieces, pass!, mobility
export position_to_string, ZOBRIST_TABLE, compute_full_hash, update_hash

# CUI
export display_board

# Game session
export play_game, game_loop!

# Game record & replay (io)
export GameRecord, save_game, load_game, replay_game, validate_record

# GUI (requires GLMakie)
export GUIConfig, load_config, save_session_config
export launch_gui, launch_replay_gui

# WTHOR format (io)
export WThorHeader, WThorGame, read_wthor, write_wthor
export wthor_game_to_record, verify_wthor_game

# ---------------------------------------------------------------------------
# Include order:
#   core/   – pure game state and rules, no I/O, no rendering
#   io/     – serialisation and file formats (depends on core/)
#   ui/     – user interfaces (depends on core/ and io/)
# ---------------------------------------------------------------------------

include("core/struct.jl")   # ReversiGame, Position, constants, Zobrist
include("core/rules.jl")    # make_move!, valid_moves, pass!, …
include("core/player.jl")   # Player interface, HumanPlayer, RandomPlayer

include("io/wthor.jl")      # WTHOR binary format (.wtb)
include("io/record.jl")     # GameRecord, save_game, load_game, replay_game

include("ui/cui.jl")        # display_board (terminal rendering)
include("ui/game.jl")       # play_game (CUI game loop)
include("ui/config.jl")     # GUI configuration loader
include("ui/gui.jl")        # GUI stubs; GLMakie implementation lives in ext/

end # module Reversi
