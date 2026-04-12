import type { OpeningCandidate } from '../../api';

type OpeningBookTableProps = {
  candidates: OpeningCandidate[];
  total: number;
};

export function OpeningBookTable({ candidates, total }: OpeningBookTableProps) {
  if (candidates.length === 0) {
    return (
      <div className="text-xs text-slate-600 italic py-2">No candidate moves recorded.</div>
    );
  }

  const maxCount = Math.max(...candidates.map(c => c.count), 1);

  return (
    <div className="space-y-1">
      {candidates.map(c => {
        const bar = (c.count / maxCount) * 100;
        return (
          <div key={c.move} className="flex items-center gap-3 text-xs font-mono">
            <div className="w-12 font-bold uppercase text-slate-300">{c.move}</div>
            <div className="flex-1 bg-black/30 rounded h-4 relative overflow-hidden border border-white/5">
              <div
                className="h-full bg-emerald-600/50 border-r border-emerald-400/60"
                style={{ width: `${bar}%` }}
              />
              <div className="absolute inset-0 flex items-center px-2 justify-between">
                <span className="text-[10px] font-bold text-white/90">{c.count}</span>
                <span className="text-[10px] text-slate-300">
                  {(c.frequency * 100).toFixed(0)}%
                </span>
              </div>
            </div>
          </div>
        );
      })}
      <div className="pt-2 text-[9px] text-slate-600 font-mono">
        {candidates.length} candidate{candidates.length !== 1 ? 's' : ''} — {total} games in this position
      </div>
    </div>
  );
}
