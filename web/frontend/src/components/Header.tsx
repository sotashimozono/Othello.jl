import { Brain } from 'lucide-react';
import type { GameState, PlayerType } from '../types';

type HeaderProps = {
  liveState: GameState;
  blackPlayer: PlayerType;
  whitePlayer: PlayerType;
  isReplaying: boolean;
  viewingIndex: number | null;
  historyLen: number;
};

export function Header({ liveState, blackPlayer, whitePlayer, isReplaying, viewingIndex, historyLen }: HeaderProps) {
  return (
    <div className="w-full flex justify-between items-center mb-6 glass-panel px-8 py-5 relative overflow-hidden">
      <div className={`flex items-center gap-4 transition-all duration-500 ${liveState.current_player === 1 ? 'scale-110' : 'opacity-40 filter grayscale'}`}>
        <div className="relative">
          <div className="w-12 h-12 rounded-full bg-black border-2 border-slate-700 shadow-[0_0_15px_rgba(0,0,0,0.5)]"></div>
          {blackPlayer !== 'human' && <div className="absolute -bottom-1 -right-1 bg-emerald-500 rounded-full p-1"><Brain size={12} className="text-black" /></div>}
        </div>
        <div>
          <div className="text-[10px] uppercase tracking-widest text-slate-500 font-extrabold">Black</div>
          <div className="text-3xl font-black font-mono leading-none">{liveState.black_score}</div>
        </div>
      </div>

      <div className="text-center">
        <h1 className="text-2xl font-black tracking-tighter text-white opacity-90 mb-1">Reversi.jl</h1>
        <div className={`text-[9px] font-black uppercase tracking-[0.2em] px-2 py-0.5 rounded transition-all ${isReplaying ? 'bg-amber-500 text-black' : 'text-emerald-500'}`}>
          {isReplaying ? `REPLAY: ${viewingIndex} / ${historyLen}` : 'Live Play'}
        </div>
      </div>

      <div className={`flex items-center gap-4 transition-all duration-500 text-right ${liveState.current_player === -1 ? 'scale-110' : 'opacity-40 filter grayscale'}`}>
        <div className="order-2 relative">
          <div className="w-12 h-12 rounded-full bg-white border-2 border-slate-200 shadow-[0_0_15px_rgba(255,255,255,0.2)]"></div>
          {whitePlayer !== 'human' && <div className="absolute -bottom-1 -left-1 bg-emerald-500 rounded-full p-1"><Brain size={12} className="text-black" /></div>}
        </div>
        <div className="order-1">
          <div className="text-[10px] uppercase tracking-widest text-slate-500 font-extrabold">White</div>
          <div className="text-3xl font-black font-mono leading-none">{liveState.white_score}</div>
        </div>
      </div>

      <div className={`absolute bottom-0 left-0 h-1 bg-emerald-500 transition-all duration-1000 ${liveState.current_player === 1 ? 'w-1/3' : 'w-1/3 translate-x-[200%]'}`}></div>
    </div>
  );
}
