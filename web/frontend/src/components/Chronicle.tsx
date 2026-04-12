import { History } from 'lucide-react';

type ChronicleProps = {
  formattedHistory: { black: string; white: string; index: number }[];
  historyLen: number;
  viewingIndex: number | null;
  setViewingIndex: (val: number | null) => void;
};

export function Chronicle({ formattedHistory, historyLen, viewingIndex, setViewingIndex }: ChronicleProps) {
  return (
    <div className="glass-panel p-6 flex-grow flex flex-col overflow-hidden">
      <div className="flex items-center gap-3 mb-6">
        <History className="text-emerald-500" size={20} />
        <h3 className="text-sm font-black uppercase tracking-widest text-slate-400">Chronicle</h3>
      </div>

      <div className="bg-black/30 rounded-xl p-4 overflow-y-auto max-h-[600px] border border-white/5 scrollbar-thin scrollbar-thumb-emerald-900 flex-grow">
        {formattedHistory.length === 0 ? (
          <div className="text-slate-600 text-center py-20 italic font-serif opacity-50">Silencio...</div>
        ) : (
          <div className="space-y-4">
            {formattedHistory.map((entry, idx) => (
              <div key={idx} className="flex flex-col gap-1 group">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-[10px] font-black text-slate-600 uppercase">Turn {idx + 1}</span>
                  <div className="h-[1px] bg-white/5 flex-grow"></div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={() => setViewingIndex(entry.index + 1)}
                    className={`flex items-center gap-2 bg-white/5 rounded-md p-3 border hover:border-emerald-500/50 transition-all ${viewingIndex === entry.index + 1 ? 'border-emerald-500 ring-2 ring-emerald-500/20' : 'border-white/5'}`}
                  >
                    <div className="w-2 h-2 rounded-full bg-black border border-slate-600"></div>
                    <span className="font-mono text-sm uppercase">{entry.black}</span>
                  </button>

                  {entry.white && (
                    <button
                      onClick={() => setViewingIndex(entry.index + 2)}
                      className={`flex items-center gap-2 bg-white/5 rounded-md p-3 border hover:border-emerald-500/50 transition-all ${viewingIndex === entry.index + 2 ? 'border-emerald-500 ring-2 ring-emerald-500/20' : 'border-white/5'}`}
                    >
                      <div className="w-2 h-2 rounded-full bg-white"></div>
                      <span className="font-mono text-sm uppercase">{entry.white}</span>
                    </button>
                  )}
                </div>
              </div>
            ))}
            <div id="history-end"></div>
          </div>
        )}
      </div>

      <div className="mt-4 pt-4 border-t border-white/5 flex justify-between text-[10px] font-black uppercase text-slate-600 tracking-tighter">
        <span>WTHOR ENGINE V2</span>
        <span>{historyLen} MOVES LOGGED</span>
      </div>
    </div>
  );
}
