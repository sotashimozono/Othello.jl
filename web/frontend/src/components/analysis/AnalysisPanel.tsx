import { useEffect, useState } from 'react';
import { Activity } from 'lucide-react';
import type { AnalysisResult, PVResult } from '../../api';
import { fetchAnalysis, fetchPrincipalVariation } from '../../api';
import { ScoreHeatmap } from './ScoreHeatmap';
import { PVViewer } from './PVViewer';

type AnalysisPanelProps = {
  historyLen: number;
  viewingIndex: number | null;
};

const EVALUATORS = [
  { value: 'heuristic', label: 'Heuristic (weights)' },
  { value: 'corner', label: 'Corner-first' },
  { value: 'mobility', label: 'Mobility' },
  { value: 'greedy', label: 'Greedy (flips)' },
  { value: 'minimax-3', label: 'Minimax-3' },
  { value: 'minimax-4', label: 'Minimax-4' },
  { value: 'mcts-50', label: 'MCTS-50' },
];

export function AnalysisPanel({ historyLen, viewingIndex }: AnalysisPanelProps) {
  const [evaluator, setEvaluator] = useState('heuristic');
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [depth, setDepth] = useState(6);
  const [pv, setPv] = useState<PVResult | null>(null);
  const [pvLoading, setPvLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetchAnalysis(evaluator, viewingIndex)
      .then(setResult)
      .catch(err => {
        console.error('Analysis error:', err);
        setResult(null);
      })
      .finally(() => setLoading(false));
  }, [evaluator, viewingIndex, historyLen]);

  const handleFetchPV = () => {
    setPvLoading(true);
    fetchPrincipalVariation(evaluator, depth, viewingIndex)
      .then(setPv)
      .catch(err => {
        console.error('PV error:', err);
        setPv(null);
      })
      .finally(() => setPvLoading(false));
  };

  return (
    <div className="glass-panel p-6 mt-6 w-full">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <Activity className="text-emerald-500" size={18} />
          <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400">Analysis</h3>
        </div>
        <select
          value={evaluator}
          onChange={e => setEvaluator(e.target.value)}
          className="bg-slate-900 border border-white/10 rounded-lg px-3 py-1.5 text-xs font-bold focus:ring-2 focus:ring-emerald-500 outline-none"
        >
          {EVALUATORS.map(e => (
            <option key={e.value} value={e.value}>{e.label}</option>
          ))}
        </select>
      </div>

      {loading && (
        <div className="text-xs text-slate-600 italic">Evaluating...</div>
      )}

      {!loading && result && result.scores.length > 0 && (
        <div className="flex flex-col md:flex-row gap-6 items-center justify-center">
          <ScoreHeatmap scores={result.scores} best={result.best} />
          <div className="flex flex-col gap-3 min-w-[140px]">
            <div>
              <div className="text-[9px] font-black uppercase text-slate-600 tracking-widest">Best</div>
              <div className="text-lg font-mono font-bold text-amber-400">
                {result.best
                  ? `${String.fromCharCode(96 + result.best.col)}${result.best.row}`
                  : '—'}
              </div>
            </div>
            <div>
              <div className="text-[9px] font-black uppercase text-slate-600 tracking-widest">Score</div>
              <div className="text-lg font-mono font-bold text-emerald-400">
                {result.best ? result.best.score.toFixed(2) : '—'}
              </div>
            </div>
            <div>
              <div className="text-[9px] font-black uppercase text-slate-600 tracking-widest">Moves</div>
              <div className="text-lg font-mono font-bold">{result.scores.length}</div>
            </div>
          </div>
        </div>
      )}

      {!loading && result && result.scores.length === 0 && (
        <div className="text-xs text-slate-600 italic text-center py-8">No legal moves to evaluate.</div>
      )}

      {/* Principal Variation controls */}
      <div className="mt-6 pt-4 border-t border-white/5">
        <div className="flex flex-wrap items-end gap-4">
          <div className="flex flex-col gap-1">
            <label className="text-[9px] font-black uppercase text-slate-600 tracking-widest">Look-ahead depth</label>
            <input
              type="number"
              min={1}
              max={20}
              value={depth}
              onChange={e => setDepth(Math.max(1, Math.min(20, parseInt(e.target.value) || 1)))}
              className="bg-slate-900 border border-white/10 rounded-lg px-3 py-1.5 text-xs font-mono font-bold w-20 focus:ring-2 focus:ring-emerald-500 outline-none"
            />
          </div>
          <button
            onClick={handleFetchPV}
            disabled={pvLoading}
            className="px-5 py-2 bg-emerald-950/50 hover:bg-emerald-900/60 text-emerald-400 rounded-lg text-xs font-black transition-all active:scale-95 disabled:opacity-40"
          >
            {pvLoading ? 'Thinking…' : 'Show Principal Variation'}
          </button>
        </div>

        {pv && pv.moves.length > 0 && <PVViewer result={pv} />}
      </div>
    </div>
  );
}
