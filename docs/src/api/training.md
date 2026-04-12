```@meta
CurrentModule = Reversi
```

# Training (`src/training/`)

Trainer-agnostic training pipeline. Concrete trainers (e.g. neural-network or
tensor-network agents) implement the [`train_episode!`](@ref) interface; the
`TrainingSession` machinery handles background scheduling, metrics collection,
and persistence.

## Types and core interface (`types.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["training/types.jl"]
```

## Session lifecycle (`session.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["training/session.jl"]
```

## Built-in trainers (`random_trainer.jl`)

```@autodocs
Modules = [Reversi]
Pages   = ["training/random_trainer.jl"]
```

---

## Notes

### Implementing a custom trainer

```julia
struct MyTrainer <: AbstractTrainer
    model           # your Flux / MPS / ... model
    learning_rate::Float64
end

function Reversi.train_episode!(trainer::MyTrainer, episode::Int)
    # ... run a self-play game, update model, return TrainingMetrics
end

# Optional overrides
Reversi.predict_value(trainer::MyTrainer, game) = ...
Reversi.hyperparameters(trainer::MyTrainer) = Dict("lr" => trainer.learning_rate)
Reversi.batch_size(trainer::MyTrainer) = 16
```

### Persistence

`save_trainer` / `load_trainer` use Julia's `Serialization` stdlib by default.
Trainers with framework-specific state (GPU buffers, etc.) should override these
with format-appropriate writers.
