import { Monitor } from 'lucide-react';
import type { GameState } from '../types';

type BoardProps = {
  gameState: GameState;
  isFancy: boolean;
  isReplaying: boolean;
  onCellClick: (row: number, col: number) => void;
};

export function Board({ gameState, isFancy, isReplaying, onCellClick }: BoardProps) {
  return (
    <div className="relative group">
      <div className={`relative p-8 rounded-xl shadow-[0_20px_50px_rgba(0,0,0,0.5)] transition-all duration-700 ${isFancy ? 'board-felt border-[12px] border-[#124227]' : 'bg-slate-900 border-2 border-slate-800'}`}>

        {/* Coordinates */}
        <div className="absolute top-0 left-8 right-8 h-8 flex items-center justify-around text-[10px] font-black text-slate-500/60 font-mono">
          {['A','B','C','D','E','F','G','H'].map(l => <span key={l} className="w-12 md:w-16 text-center">{l}</span>)}
        </div>
        <div className="absolute left-0 top-8 bottom-8 w-8 flex flex-col items-center justify-around text-[10px] font-black text-slate-500/60 font-mono">
          {[1,2,3,4,5,6,7,8].map(n => <span key={n} className="h-12 md:h-16 flex items-center">{n}</span>)}
        </div>

        <div className={`grid grid-cols-8 gap-0 border-[1px] border-black/40 ${isFancy ? 'bg-black/10' : 'bg-black/40'}`}>
          {gameState.board.map((rowArr, rIdx) => (
            rowArr.map((cell, cIdx) => {
              const r = rIdx + 1;
              const c = cIdx + 1;
              const isValid = !isReplaying && gameState.valid_moves.some((m) => m[0] === r && m[1] === c);
              const isStarPoint = (r === 3 || r === 6) && (c === 3 || c === 6);

              return (
                <div
                  key={`cell-${r}-${c}`}
                  onClick={() => onCellClick(r, c)}
                  className={`relative w-12 h-12 md:w-16 md:h-16 flex items-center justify-center border-[0.5px] border-black/10 transition-colors ${isValid ? 'cursor-pointer hover:bg-white/10' : ''}`}
                >
                  {isFancy && isStarPoint && <div className="star-point" />}
                  {isValid && <div className="absolute w-3 h-3 rounded-full bg-emerald-400/20 animate-pulse border border-emerald-500/30"></div>}

                  {cell !== 0 && (
                    <div className="piece-container">
                      <div className={`piece-inner ${cell === -1 ? 'is-white' : ''}`}>
                        <div className="piece-face piece-black"></div>
                        <div className="piece-face piece-white"></div>
                      </div>
                    </div>
                  )}
                  {!isFancy && <span className="cell-coord bottom-0.5 right-1">{String.fromCharCode(96+c)}{r}</span>}
                </div>
              );
            })
          ))}
        </div>
      </div>

      {/* Replay Overlay */}
      {isReplaying && (
        <div className="absolute inset-0 z-20 pointer-events-none flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
          <div className="bg-amber-500/90 text-black px-4 py-2 rounded-full text-xs font-black shadow-2xl flex items-center gap-2">
            <Monitor size={14} /> REPLAYING HISTORY
          </div>
        </div>
      )}
    </div>
  );
}
