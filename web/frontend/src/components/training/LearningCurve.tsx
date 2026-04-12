import { useMemo } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';
import type { TrainingHistoryEntry } from '../../api';

type LearningCurveProps = {
  history: TrainingHistoryEntry[];
};

export function LearningCurve({ history }: LearningCurveProps) {
  const chartData = useMemo(() => {
    if (history.length === 0) return [];
    // Compute rolling win rate (window of 20)
    const window = 20;
    let wins = 0;
    return history.map((entry, i) => {
      if (entry.winner === 1) wins++;
      const start = Math.max(0, i - window + 1);
      const windowWins = history.slice(start, i + 1).filter(e => e.winner === 1).length;
      const windowSize = i - start + 1;
      return {
        episode: entry.episode,
        winRate: wins / (i + 1),
        rollingWinRate: windowWins / windowSize,
        blackScore: entry.black_score,
        whiteScore: entry.white_score,
      };
    });
  }, [history]);

  if (chartData.length === 0) {
    return (
      <div className="glass-panel p-6 flex items-center justify-center h-64 text-slate-600 italic font-serif">
        No training data yet...
      </div>
    );
  }

  return (
    <div className="glass-panel p-6">
      <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-4">Win Rate (Black)</h3>
      <ResponsiveContainer width="100%" height={280}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
          <XAxis
            dataKey="episode"
            stroke="#475569"
            tick={{ fontSize: 10, fill: '#64748b' }}
            label={{ value: 'Episode', position: 'insideBottom', offset: -5, style: { fontSize: 10, fill: '#64748b' } }}
          />
          <YAxis
            domain={[0, 1]}
            stroke="#475569"
            tick={{ fontSize: 10, fill: '#64748b' }}
            tickFormatter={(v: number) => `${(v * 100).toFixed(0)}%`}
          />
          <Tooltip
            contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: 8, fontSize: 12 }}
            labelStyle={{ color: '#94a3b8' }}
            formatter={(value, name) => [
              `${(Number(value) * 100).toFixed(1)}%`,
              name === 'rollingWinRate' ? 'Rolling (20)' : 'Cumulative',
            ]}
          />
          <ReferenceLine y={0.5} stroke="#475569" strokeDasharray="6 3" />
          <Line type="monotone" dataKey="winRate" stroke="#334155" strokeWidth={1} dot={false} />
          <Line type="monotone" dataKey="rollingWinRate" stroke="#10b981" strokeWidth={2} dot={false} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
