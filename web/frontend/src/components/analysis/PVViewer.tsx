import { useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import type { PVResult } from '../../api';

type PVViewerProps = {
  result: PVResult;
};

function MiniBoard({ board, highlight }: { board: number[][]; highlight: { row: number; col: number } | null }) {
  return (
    <div className="grid grid-cols-8 gap-[1px] bg-black/40 p-1 rounded-md">
      {board.map((row, rIdx) =>
        row.map((cell, cIdx) => {
          const isHighlight = highlight && highlight.row === rIdx + 1 && highlight.col === cIdx + 1;
          return (
            <div
              key={`${rIdx}-${cIdx}`}
              className={`w-4 h-4 flex items-center justify-center ${
                isHighlight ? 'bg-amber-500/40 ring-1 ring-amber-400' : 'bg-emerald-900/40'
              }`}
            >
              {cell === 1 && <div className="w-2.5 h-2.5 rounded-full bg-black border border-slate-600"></div>}
              {cell === -1 && <div className="w-2.5 h-2.5 rounded-full bg-white"></div>}
            </div>
          );
        }),
      )}
    </div>
  );
}

export function PVViewer({ result }: PVViewerProps) {
  const [step, setStep] = useState(result.moves.length);

  // Clamp step if moves change
  const currentStep = Math.min(step, result.moves.length);

  const shownBoard = currentStep === 0 ? null : result.boards[currentStep - 1];
  const shownMove = currentStep === 0 ? null : result.moves[currentStep - 1];

  return (
    <div className="glass-panel p-4 mt-4">
      <div className="flex items-center justify-between mb-3">
        <div className="text-[10px] font-black uppercase tracking-widest text-slate-500">
          Principal Variation ({result.depth} plies)
        </div>
        <div className="text-[10px] font-mono text-slate-400">
          Final: <span className="text-black">{result.final_score.black}</span>
          {' — '}
          <span className="text-white">{result.final_score.white}</span>
        </div>
      </div>

      <div className="flex flex-wrap gap-3 items-start">
        {/* Move list */}
        <div className="flex-1 min-w-[200px]">
          <div className="grid grid-cols-4 md:grid-cols-6 gap-1.5">
            {result.moves.map((m, i) => (
              <button
                key={i}
                onClick={() => setStep(i + 1)}
                className={`px-2 py-1.5 rounded text-[10px] font-mono font-bold text-left border transition-all ${
                  currentStep === i + 1
                    ? 'bg-emerald-600 text-white border-emerald-500'
                    : 'bg-white/5 text-slate-400 border-white/5 hover:bg-white/10'
                }`}
              >
                <div className="flex items-center gap-1">
                  <div className={`w-1.5 h-1.5 rounded-full ${m.player === 1 ? 'bg-black border border-slate-500' : 'bg-white'}`}></div>
                  <span>{i + 1}. {m.notation}</span>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Mini board */}
        {shownBoard && (
          <div className="flex flex-col items-center gap-2">
            <MiniBoard
              board={shownBoard}
              highlight={shownMove && shownMove.row > 0 ? { row: shownMove.row, col: shownMove.col } : null}
            />
            <div className="flex items-center gap-1">
              <button
                onClick={() => setStep(Math.max(1, currentStep - 1))}
                disabled={currentStep <= 1}
                className="p-1 rounded hover:bg-white/10 disabled:opacity-30"
              >
                <ChevronLeft size={14} />
              </button>
              <span className="text-[10px] font-mono text-slate-500 w-14 text-center">
                {currentStep} / {result.depth}
              </span>
              <button
                onClick={() => setStep(Math.min(result.depth, currentStep + 1))}
                disabled={currentStep >= result.depth}
                className="p-1 rounded hover:bg-white/10 disabled:opacity-30"
              >
                <ChevronRight size={14} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
