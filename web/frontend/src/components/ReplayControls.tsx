import { ChevronFirst, ChevronLeft, ChevronRight, ChevronLast, Play } from 'lucide-react';

type ReplayControlsProps = {
  isReplaying: boolean;
  historyLen: number;
  setViewingIndex: (val: number | null | ((prev: number | null) => number | null)) => void;
};

export function ReplayControls({ isReplaying, historyLen, setViewingIndex }: ReplayControlsProps) {
  return (
    <div className="mt-8 flex gap-2 glass-panel p-2">
      <button onClick={() => setViewingIndex(0)} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="Start">
        <ChevronFirst size={20} />
      </button>
      <button onClick={() => setViewingIndex(idx => idx === null ? historyLen - 1 : Math.max(0, idx - 1))} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="Back">
        <ChevronLeft size={20} />
      </button>

      {isReplaying ? (
        <button onClick={() => setViewingIndex(null)} className="flex items-center gap-2 px-6 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-xs font-black transition-all">
          <Play size={14} fill="white" /> RESUME LIVE
        </button>
      ) : (
        <div className="px-6 py-2 flex items-center text-[10px] font-black uppercase text-slate-500 border-x border-white/5">
          LIVE SESSION
        </div>
      )}

      <button onClick={() => setViewingIndex(idx => idx === null ? null : Math.min(historyLen, idx + 1))} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="Forward">
        <ChevronRight size={20} />
      </button>
      <button onClick={() => setViewingIndex(null)} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="End">
        <ChevronLast size={20} />
      </button>
    </div>
  );
}
