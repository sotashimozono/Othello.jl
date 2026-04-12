import type { TrainingStatus } from '../../api';

type TrainingStatsProps = {
  status: TrainingStatus;
};

export function TrainingStats({ status }: TrainingStatsProps) {
  const progress = status.total_episodes > 0
    ? (status.completed_episodes / status.total_episodes) * 100
    : 0;

  const stats = [
    { label: 'Episodes', value: `${status.completed_episodes} / ${status.total_episodes}` },
    { label: 'Status', value: status.is_running ? 'Running' : status.completed_episodes > 0 ? 'Stopped' : 'Idle' },
    { label: 'Last Winner', value: status.latest ? (status.latest.winner === 1 ? 'Black' : status.latest.winner === -1 ? 'White' : 'Draw') : '-' },
    { label: 'Last Score', value: status.latest ? `${status.latest.black_score} - ${status.latest.white_score}` : '-' },
  ];

  return (
    <div className="glass-panel p-6">
      <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-4">Training Stats</h3>

      {/* Progress bar */}
      <div className="mb-6">
        <div className="flex justify-between text-[10px] font-black text-slate-500 mb-1">
          <span>Progress</span>
          <span>{progress.toFixed(0)}%</span>
        </div>
        <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
          <div
            className="h-full bg-emerald-500 rounded-full transition-all duration-500"
            style={{ width: `${progress}%` }}
          ></div>
        </div>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 gap-4">
        {stats.map(({ label, value }) => (
          <div key={label} className="bg-white/5 rounded-xl p-4 border border-white/5">
            <div className="text-[9px] font-black uppercase tracking-widest text-slate-600 mb-1">{label}</div>
            <div className="text-lg font-black font-mono">{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
