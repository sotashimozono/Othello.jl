# Othello.jl Documentation

```@meta
CurrentModule = Othello
```

A high-performance Othello (Reversi) implementation in Julia, built on StaticArrays.jl for efficient board representation. Designed with flexibility for machine learning research and reinforcement learning applications.

## Features

- **Efficient Implementation**: Uses StaticArrays.jl for fast, stack-allocated board representation
- **Terminal Gameplay**: Play interactively in the terminal
- **Flexible Player System**: Easy to integrate custom AI players and ML models
- **Clean API**: Simple, well-documented interface for programmatic control
- **Extensible**: Abstract player interface allows easy implementation of new strategies

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/sotashimozono/Othello.jl")
```

## Quick Start

### Play in Terminal

```julia
using Othello

# Human vs Random AI
play_game(HumanPlayer(), RandomPlayer())
```

### Create Custom AI Players

```julia
using Othello

# Define a custom player type
struct MyAIPlayer <: Player end

# Implement the get_move function
function Othello.get_move(player::MyAIPlayer, game::OthelloGame)
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

## API Reference

```@autodocs
Modules = [Othello]
```
