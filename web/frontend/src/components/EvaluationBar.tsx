export function EvaluationBar({ black, white }: { black: number; white: number }) {
  const total = black + white || 1;
  const blackPct = (black / total) * 100;

  return (
    <div className="w-full mb-6">
      <div className="flex justify-between text-[10px] font-black uppercase tracking-tighter text-slate-500 mb-1 px-1">
        <span>Black {Math.round(blackPct)}%</span>
        <span>White {Math.round(100 - blackPct)}%</span>
      </div>
      <div className="eval-bar-container">
        <div className="eval-bar-black" style={{ width: `${blackPct}%` }}></div>
        <div className="eval-bar-marker" style={{ left: `${blackPct}%` }}></div>
        <div className="eval-bar-white" style={{ width: `${100 - blackPct}%` }}></div>
      </div>
    </div>
  );
}
