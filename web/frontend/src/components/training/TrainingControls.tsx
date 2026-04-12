import { useState } from 'react';
import { Play, Square } from 'lucide-react';

type TrainingControlsProps = {
  isRunning: boolean;
  onStart: (numEpisodes: number, trainerType: string) => void;
  onStop: () => void;
};

export function TrainingControls({ isRunning, onStart, onStop }: TrainingControlsProps) {
  const [numEpisodes, setNumEpisodes] = useState(200);
  const [trainerType, setTrainerType] = useState('random');

  return (
    <div className="glass-panel p-6 flex flex-wrap items-end gap-6">
      <div className="flex flex-col gap-2">
        <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Episodes</label>
        <input
          type="number"
          min={1}
          max={10000}
          value={numEpisodes}
          onChange={(e) => setNumEpisodes(Math.max(1, parseInt(e.target.value) || 1))}
          disabled={isRunning}
          className="bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-mono font-bold w-32 focus:ring-2 focus:ring-emerald-500 outline-none disabled:opacity-40"
        />
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Trainer</label>
        <select
          value={trainerType}
          onChange={(e) => setTrainerType(e.target.value)}
          disabled={isRunning}
          className="bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-emerald-500 outline-none disabled:opacity-40"
        >
          <option value="random">Random (Baseline)</option>
        </select>
      </div>

      {isRunning ? (
        <button
          onClick={onStop}
          className="px-8 py-3 bg-red-950/50 hover:bg-red-900/60 text-red-400 rounded-xl font-black flex items-center gap-3 transition-all active:scale-95"
        >
          <Square size={16} fill="currentColor" /> STOP
        </button>
      ) : (
        <button
          onClick={() => onStart(numEpisodes, trainerType)}
          className="px-8 py-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-black flex items-center gap-3 transition-all active:scale-95 shadow-lg shadow-emerald-500/20"
        >
          <Play size={16} fill="white" /> START
        </button>
      )}
    </div>
  );
}
