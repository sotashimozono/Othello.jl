import type { TournamentPairResult } from '../../api';

type ResultsMatrixProps = {
  players: string[];
  results: TournamentPairResult[];
};

export function ResultsMatrix({ players, results }: ResultsMatrixProps) {
  // Build a lookup: (black, white) -> result
  const lookup = new Map<string, TournamentPairResult>();
  for (const r of results) {
    lookup.set(`${r.black}__${r.white}`, r);
  }

  const winRate = (r: TournamentPairResult | undefined) => {
    if (!r || r.completed === 0) return null;
    // From BLACK's perspective
    return r.black_wins / r.completed;
  };

  const colorForWinRate = (wr: number | null) => {
    if (wr === null) return 'transparent';
    // 0 = red, 0.5 = gray, 1 = green
    if (wr >= 0.5) {
      const t = (wr - 0.5) * 2;
      return `rgba(16, 185, 129, ${(t * 0.6 + 0.1).toFixed(2)})`;
    } else {
      const t = (0.5 - wr) * 2;
      return `rgba(239, 68, 68, ${(t * 0.6 + 0.1).toFixed(2)})`;
    }
  };

  if (players.length === 0) {
    return (
      <div className="glass-panel p-6 flex items-center justify-center h-48 text-slate-600 italic font-serif">
        No tournament data yet...
      </div>
    );
  }

  return (
    <div className="glass-panel p-6 overflow-x-auto">
      <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-4">
        Results Matrix (Black ↓ wins vs White →)
      </h3>
      <table className="w-full border-collapse text-xs">
        <thead>
          <tr>
            <th className="p-2 text-slate-600"></th>
            {players.map(p => (
              <th key={`h-${p}`} className="p-2 font-mono font-bold text-slate-400 text-[10px] uppercase">
                {p}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {players.map((black, rIdx) => (
            <tr key={`r-${black}`}>
              <td className="p-2 font-mono font-bold text-slate-400 text-[10px] uppercase text-right border-r border-white/5">
                {black}
              </td>
              {players.map((white, cIdx) => {
                if (rIdx === cIdx) {
                  return (
                    <td key={`c-${white}`} className="p-3 text-center text-slate-700">
                      —
                    </td>
                  );
                }
                const r = lookup.get(`${black}__${white}`);
                const wr = winRate(r);
                return (
                  <td
                    key={`c-${white}`}
                    className="p-3 text-center font-mono font-bold border border-white/5"
                    style={{ backgroundColor: colorForWinRate(wr) }}
                  >
                    {r && r.completed > 0 ? (
                      <div>
                        <div className="text-sm">{wr !== null ? `${(wr * 100).toFixed(0)}%` : '—'}</div>
                        <div className="text-[9px] text-slate-400 font-normal">
                          {r.black_wins}-{r.white_wins}-{r.draws}
                        </div>
                      </div>
                    ) : (
                      <span className="text-slate-700">—</span>
                    )}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
      <div className="mt-4 text-[9px] text-slate-600 font-mono">
        Each cell: black's win rate as black vs the column player. Below: B-W-Draw counts.
      </div>
    </div>
  );
}
