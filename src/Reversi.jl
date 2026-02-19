module Reversi

# Export main types and functions
export ReversiGame, Player, Position
export make_move!, valid_moves, is_game_over, get_winner, display_board
export HumanPlayer, RandomPlayer, play_game
export next_state, get_piece, count_pieces, pass!
export position_to_string, ZOBRIST_TABLE, compute_full_hash, update_hash

include("core/struct.jl")
include("core/player.jl")
include("core/rules.jl")
include("UI/game.jl")

end # module Reversi
