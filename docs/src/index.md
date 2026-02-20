# Reversi.jl Documentation

```@meta
CurrentModule = Reversi
```

A high-performance Reversi (Othello) implementation in Julia, built on StaticArrays.jl for efficient board representation. Designed with flexibility for machine learning research and reinforcement learning applications.

## Features

- **Efficient Implementation**: Uses StaticArrays.jl for fast, stack-allocated board representation
- **Terminal Gameplay**: Play interactively in the terminal
- **Flexible Player System**: Easy to integrate custom AI players and ML models
- **Clean API**: Simple, well-documented interface for programmatic control
- **Extensible**: Abstract player interface allows easy implementation of new strategies

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/sotashimozono/Reversi.jl")
```

## Quick Start

### Play in Terminal

```julia
using Reversi

# Human vs Random AI
play_game(HumanPlayer(), RandomPlayer())
```

### Create Custom AI Players

```julia
using Reversi

# Define a custom player type
struct MyAIPlayer <: Player end

# Implement the get_move function
function Reversi.get_move(player::MyAIPlayer, game::ReversiGame)
    moves = valid_moves(game)
    
    if isempty(moves)
        return nothing  # Pass turn
    end
    
    # Your AI logic here
    return moves[1]  # Example: pick first valid move
end

# Play a game
play_game(MyAIPlayer(), RandomPlayer())
```
