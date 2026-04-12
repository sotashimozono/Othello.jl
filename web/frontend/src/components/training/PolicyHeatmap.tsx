type PolicyHeatmapProps = {
  policy: number[][];
};

function intensityToColor(value: number, max: number): string {
  if (max === 0) return 'rgba(16, 185, 129, 0)';
  const t = value / max;
  return `rgba(16, 185, 129, ${(t * 0.9 + 0.05).toFixed(2)})`;
}

export function PolicyHeatmap({ policy }: PolicyHeatmapProps) {
  const max = Math.max(...policy.flat(), 0.001);

  return (
    <div className="glass-panel p-6">
      <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-4">Policy Heatmap</h3>

      {/* Coordinates */}
      <div className="flex justify-center">
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
              {policy.map((row, rIdx) =>
                row.map((val, cIdx) => (
                  <div
                    key={`${rIdx}-${cIdx}`}
                    className="w-9 h-9 flex items-center justify-center relative"
                    style={{ backgroundColor: intensityToColor(val, max) }}
                    title={`${String.fromCharCode(97 + cIdx)}${rIdx + 1}: ${(val * 100).toFixed(1)}%`}
                  >
                    {val > max * 0.3 && (
                      <span className="text-[8px] font-mono font-bold text-white/80">
                        {(val * 100).toFixed(0)}
                      </span>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center justify-center gap-3 mt-4">
        <span className="text-[9px] text-slate-600">0%</span>
        <div className="h-2 w-32 rounded-full" style={{
          background: 'linear-gradient(to right, rgba(16,185,129,0.05), rgba(16,185,129,0.95))',
        }}></div>
        <span className="text-[9px] text-slate-600">{(max * 100).toFixed(0)}%</span>
      </div>
    </div>
  );
}
