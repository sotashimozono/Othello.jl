import { useState } from 'react';
import { Play, Square } from 'lucide-react';

const AVAILABLE_PLAYERS: { value: string; label: string }[] = [
  { value: 'random', label: 'Random' },
  { value: 'greedy', label: 'Greedy' },
  { value: 'heuristic', label: 'Heuristic' },
  { value: 'corner', label: 'Corner-first' },
  { value: 'mobility', label: 'Mobility' },
  { value: 'minimax-2', label: 'Minimax-2' },
  { value: 'minimax-3', label: 'Minimax-3' },
  { value: 'minimax-4', label: 'Minimax-4' },
  { value: 'mcts-50', label: 'MCTS-50' },
  { value: 'mcts-100', label: 'MCTS-100' },
];

type TournamentControlsProps = {
  isRunning: boolean;
  onStart: (players: string[], numGames: number) => void;
  onStop: () => void;
};

export function TournamentControls({ isRunning, onStart, onStop }: TournamentControlsProps) {
  const [selected, setSelected] = useState<string[]>(['random', 'greedy', 'heuristic']);
  const [numGames, setNumGames] = useState(5);

  const toggle = (value: string) => {
    setSelected(prev =>
      prev.includes(value) ? prev.filter(p => p !== value) : [...prev, value],
    );
  };

  const canStart = selected.length >= 2 && !isRunning;

  return (
    <div className="glass-panel p-6 space-y-6">
      <div>
        <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest block mb-3">
          Players ({selected.length} selected)
        </label>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
          {AVAILABLE_PLAYERS.map(({ value, label }) => {
            const active = selected.includes(value);
            return (
              <button
                key={value}
                onClick={() => !isRunning && toggle(value)}
                disabled={isRunning}
                className={`px-3 py-2 rounded-lg text-xs font-bold transition-all border ${
                  active
                    ? 'bg-emerald-600 text-white border-emerald-500 shadow-lg shadow-emerald-500/20'
                    : 'bg-white/5 text-slate-400 border-white/5 hover:bg-white/10'
                } disabled:opacity-40 disabled:cursor-not-allowed`}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>

      <div className="flex flex-wrap items-end gap-6">
        <div className="flex flex-col gap-2">
          <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Games per pair</label>
          <input
            type="number"
            min={1}
            max={50}
            value={numGames}
            onChange={e => setNumGames(Math.max(1, parseInt(e.target.value) || 1))}
            disabled={isRunning}
            className="bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-mono font-bold w-28 focus:ring-2 focus:ring-emerald-500 outline-none disabled:opacity-40"
          />
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
            onClick={() => canStart && onStart(selected, numGames)}
            disabled={!canStart}
            className="px-8 py-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-black flex items-center gap-3 transition-all active:scale-95 shadow-lg shadow-emerald-500/20 disabled:opacity-40 disabled:cursor-not-allowed disabled:shadow-none"
          >
            <Play size={16} fill="white" /> START
          </button>
        )}

        <div className="text-[10px] font-mono text-slate-500">
          Total games: <span className="font-bold text-slate-300">{selected.length * (selected.length - 1) * numGames}</span>
        </div>
      </div>
    </div>
  );
}
