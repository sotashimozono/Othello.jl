import type { TournamentStatus } from '../../api';

type TournamentProgressProps = {
  status: TournamentStatus;
};

export function TournamentProgress({ status }: TournamentProgressProps) {
  const progress = status.total_games > 0
    ? (status.completed_games / status.total_games) * 100
    : 0;

  return (
    <div className="glass-panel p-6">
      <div className="flex items-end justify-between mb-3">
        <div>
          <div className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Progress</div>
          <div className="text-2xl font-black font-mono mt-1">
            {status.completed_games} <span className="text-slate-600">/</span> {status.total_games}
          </div>
        </div>
        <div className="text-right">
          <div className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Status</div>
          <div className={`text-sm font-black mt-1 ${status.is_running ? 'text-emerald-400' : 'text-slate-400'}`}>
            {status.is_running ? 'Running' : (status.completed_games > 0 ? 'Complete' : 'Idle')}
          </div>
        </div>
      </div>
      <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
        <div
          className="h-full bg-emerald-500 rounded-full transition-all duration-500"
          style={{ width: `${progress}%` }}
        ></div>
      </div>
      <div className="mt-2 text-[10px] text-slate-500 font-mono">
        {status.completed_pairs} / {status.total_pairs} pairs · {progress.toFixed(0)}%
      </div>
    </div>
  );
}
