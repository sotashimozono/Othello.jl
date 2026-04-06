```@meta
CurrentModule = Reversi
```

# UI (`src/ui/`)

User-interface layer.  Depends on `core/` and `io/`.

## Terminal rendering (`cui.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["ui/cui.jl"]
```

### Example output

```
  a b c d e f g h
1 · · · · · · · ·
2 · · · · · · · ·
3 · · · * · · · ·
4 · · * ○ ● · · ·
5 · · · ● ○ * · ·
6 · · · · · · · ·
7 · · · · · · · ·
8 · · · · · · · ·
Black (●): 2  White (○): 2
Current player: Black (●)
```

Green `*` marks show valid moves (requires `hints` argument).

---

## CUI game loop (`game.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["ui/game.jl"]
```

### Quick reference

```julia
# Human (Black) vs Random AI (White), verbose output, auto-save record
play_game(HumanPlayer(), RandomPlayer();
          verbose=true, save_record=true, record_path="game.txt")

# Silent batch play (e.g. self-play data generation)
winner = play_game(MyAI(), MyAI(); verbose=false)
```

---

## GLMakie GUI (`gui.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["ui/gui.jl"]
```

### Launching the GUI

```julia
# Default: Human (Black) vs Random AI (White)
launch_gui()

# Fully custom
launch_gui(MyMLPlayer(model), GUIPlayer(); show_hints=false)

# Replay a saved game record
rec = load_game("game.txt")
launch_replay_gui(rec; title="My game")

# Replay a WTHOR game
_, games = read_wthor("WTH_2001.wtb")
launch_replay_gui(wthor_game_to_record(games[1]))
```

The GUI provides:
- Player-selection menus (Human / Random AI / custom)
- Live move-history (kifu) panel
- Optional move hints and last-move highlight toggles
- Custom player registration via Julia expression (`+ Add Player` button)
