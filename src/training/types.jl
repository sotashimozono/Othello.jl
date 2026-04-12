"""
    AbstractTrainer

Abstract type for all trainer implementations.
Subtype and implement `train_episode!(trainer, game) -> TrainingMetrics`.
"""
abstract type AbstractTrainer end

"""
    TrainingMetrics

Metrics collected from a single training episode (one game).
"""
struct TrainingMetrics
    episode::Int
    winner::Int                     # BLACK, WHITE, or EMPTY (draw)
    black_score::Int
    white_score::Int
    win_rate::Float64               # cumulative win rate up to this episode
    policy::Matrix{Float32}         # 8×8 move frequency / probability
end

"""
    TrainingSession

Manages the lifecycle of a training run: background task, metrics history, locking.
"""
mutable struct TrainingSession
    trainer::AbstractTrainer
    num_episodes::Int
    metrics_history::Vector{TrainingMetrics}
    is_running::Bool
    task::Union{Task,Nothing}
    lock::ReentrantLock

    function TrainingSession(trainer::AbstractTrainer; num_episodes::Int=100)
        new(trainer, num_episodes, TrainingMetrics[], false, nothing, ReentrantLock())
    end
end

"""
    train_episode!(trainer::AbstractTrainer, episode::Int) -> TrainingMetrics

Run one training episode and return the collected metrics.
Must be implemented by every concrete `AbstractTrainer` subtype.
"""
function train_episode! end
