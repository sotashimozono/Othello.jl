type ScoreEntry = { row: number; col: number; score: number };

type ScoreHeatmapProps = {
  scores: ScoreEntry[];
  best: { row: number; col: number; score: number } | null;
};

function colorForScore(value: number, min: number, max: number): string {
  if (max === min) return 'rgba(16, 185, 129, 0.25)';
  const t = (value - min) / (max - min);
  return `rgba(16, 185, 129, ${(t * 0.85 + 0.15).toFixed(2)})`;
}

export function ScoreHeatmap({ scores, best }: ScoreHeatmapProps) {
  const grid: (ScoreEntry | null)[][] = Array.from({ length: 8 }, () => new Array(8).fill(null));
  for (const s of scores) {
    grid[s.row - 1][s.col - 1] = s;
  }

  const values = scores.map(s => s.score);
  const min = values.length ? Math.min(...values) : 0;
  const max = values.length ? Math.max(...values) : 1;

  return (
    <div>
      <div className="flex ml-8">
        {['A','B','C','D','E','F','G','H'].map(l => (
          <div key={l} className="w-9 text-center text-[9px] font-mono text-slate-600">{l}</div>
        ))}
      </div>

      <div className="flex">
        <div className="flex flex-col mr-1">
          {[1,2,3,4,5,6,7,8].map(n => (
            <div key={n} className="h-9 flex items-center justify-center w-7 text-[9px] font-mono text-slate-600">{n}</div>
          ))}
        </div>

        <div className="grid grid-cols-8 gap-[1px] bg-black/30 border border-white/5 rounded-lg overflow-hidden">
          {grid.map((row, rIdx) =>
            row.map((cell, cIdx) => {
              const isBest = best && best.row === rIdx + 1 && best.col === cIdx + 1;
              return (
                <div
                  key={`${rIdx}-${cIdx}`}
                  className={`w-9 h-9 flex items-center justify-center relative ${isBest ? 'ring-2 ring-amber-400 z-10' : ''}`}
                  style={{
                    backgroundColor: cell ? colorForScore(cell.score, min, max) : 'transparent',
                  }}
                  title={cell ? `(${rIdx + 1},${cIdx + 1}) score=${cell.score.toFixed(2)}` : ''}
                >
                  {cell && (
                    <span className="text-[8px] font-mono font-bold text-white/80">
                      {cell.score.toFixed(0)}
                    </span>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
