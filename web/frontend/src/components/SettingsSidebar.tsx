import { Settings, X, RefreshCw, Zap, Brain } from 'lucide-react';
import type { PlayerType } from '../types';
import { useConfig } from '../contexts/ConfigContext';
import { ConfigTab } from './ConfigTab';

type SettingsSidebarProps = {
  showMenu: boolean;
  setShowMenu: (v: boolean) => void;
  blackPlayer: PlayerType;
  setBlackPlayer: (v: PlayerType) => void;
  whitePlayer: PlayerType;
  setWhitePlayer: (v: PlayerType) => void;
  isAutoPlay: boolean;
  setIsAutoPlay: (v: boolean) => void;
  onReset: () => void;
};

export function SettingsSidebar({
  showMenu, setShowMenu,
  blackPlayer, setBlackPlayer,
  whitePlayer, setWhitePlayer,
  isAutoPlay, setIsAutoPlay,
  onReset,
}: SettingsSidebarProps) {
  const { isFancy, setIsFancy } = useConfig();

  return (
    <>
      <div className={`sidebar-overlay ${showMenu ? 'is-open' : ''}`} onClick={() => setShowMenu(false)}></div>

      <aside className={`sidebar flex flex-col p-8 ${showMenu ? 'is-open' : ''}`}>
        <div className="flex justify-between items-center mb-10">
          <h2 className="text-xl font-black tracking-tighter flex items-center gap-3">
            <Settings className="text-emerald-500" />
            CONFIG
          </h2>
          <button onClick={() => setShowMenu(false)} className="p-2 hover:bg-white/5 rounded-full transition-colors">
            <X size={20} />
          </button>
        </div>

        <div className="space-y-8 flex-grow overflow-y-auto">
          {/* Player Selection */}
          <div className="space-y-4">
            <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Opponents</label>
            <div className="space-y-3">
              <div className="flex flex-col gap-2">
                <span className="text-xs font-bold text-slate-400 flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-black border border-white/20"></div> Black Player
                </span>
                <select
                  value={blackPlayer}
                  onChange={(e) => setBlackPlayer(e.target.value as PlayerType)}
                  className="w-full bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-emerald-500 outline-none"
                >
                  <option value="human">Human (User)</option>
                  <option value="random">Random AI</option>
                  <option value="greedy">Greedy AI</option>
                </select>
              </div>
              <div className="flex flex-col gap-2">
                <span className="text-xs font-bold text-slate-400 flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-white"></div> White Player
                </span>
                <select
                  value={whitePlayer}
                  onChange={(e) => setWhitePlayer(e.target.value as PlayerType)}
                  className="w-full bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-emerald-500 outline-none"
                >
                  <option value="human">Human (User)</option>
                  <option value="random">Random AI</option>
                  <option value="greedy">Greedy AI</option>
                </select>
              </div>
            </div>
          </div>

          {/* Automation */}
          <div className="space-y-4">
            <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Automation</label>
            <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5 group hover:bg-white/10 transition-colors cursor-pointer" onClick={() => setIsAutoPlay(!isAutoPlay)}>
              <div className="flex items-center gap-3">
                <Zap className={isAutoPlay ? 'text-yellow-400' : 'text-slate-600'} size={20} />
                <span className="text-sm font-bold">Auto-Play Engine</span>
              </div>
              <div className={`w-10 h-5 rounded-full transition-colors relative ${isAutoPlay ? 'bg-emerald-600' : 'bg-slate-700'}`}>
                <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${isAutoPlay ? 'left-6' : 'left-1'}`}></div>
              </div>
            </div>
          </div>

          {/* Visuals */}
          <div className="space-y-4">
            <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Visuals</label>
            <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5 group hover:bg-white/10 transition-colors cursor-pointer" onClick={() => setIsFancy(!isFancy)}>
              <div className="flex items-center gap-3">
                <Brain className={isFancy ? 'text-emerald-400' : 'text-slate-600'} size={20} />
                <span className="text-sm font-bold">Fancy Mode (Felt)</span>
              </div>
              <div className={`w-10 h-5 rounded-full transition-colors relative ${isFancy ? 'bg-emerald-600' : 'bg-slate-700'}`}>
                <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${isFancy ? 'left-6' : 'left-1'}`}></div>
              </div>
            </div>
          </div>

          {/* Panel Toggles */}
          <ConfigTab />
        </div>

        <div className="pt-6 border-t border-white/5">
          <button
            onClick={onReset}
            className="w-full px-6 py-4 bg-red-950/30 hover:bg-red-900/50 text-red-500 rounded-xl font-bold flex items-center justify-center gap-3 transition-all active:scale-95"
          >
            <RefreshCw size={18} />
            <span>NEW REVERSION</span>
          </button>
        </div>
      </aside>
    </>
  );
}
