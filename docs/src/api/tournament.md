```@meta
CurrentModule = Reversi
```

# Tournament (`src/tournament/`)

Round-robin tournaments between a fixed list of named players. Every ordered
pair `(black, white)` plays `num_games` games using the existing
[`play_game`](@ref) loop. Results are aggregated per pair and exposed via a
JSON-friendly status snapshot.

## Types (`types.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["tournament/types.jl"]
```

## Session lifecycle (`session.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["tournament/session.jl"]
```

---

## Notes

### Construction

```julia
players = [HeuristicPlayer(), MobilityPlayer(), MinimaxPlayer(3)]
names   = ["heuristic", "mobility", "minimax-3"]
session = TournamentSession(names, players; num_games=5)
start_tournament!(session)

# poll for progress
while tournament_status(session)["is_running"]
    sleep(0.5)
end

results = tournament_status(session)["results"]
```

### Pair count

For `n` players, the round-robin runs `n * (n - 1)` ordered pairs (each player
plays both colours against every other player), with `num_games` games per
pair, for a total of `n * (n - 1) * num_games` games.
