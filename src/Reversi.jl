module Reversi

using StaticArrays

# Export main types and functions
export ReversiGame, Player, Position
export make_move!, valid_moves, is_game_over, get_winner, display_board
export HumanPlayer, RandomPlayer, play_game

include("core/struct.jl")
include("core/player.jl")
include("core/rules.jl")
include("UI/game.jl")

end # module Reversi
