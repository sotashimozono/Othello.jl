import { Brain } from 'lucide-react';

export function TrainingPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-6 text-slate-500">
      <Brain size={48} className="text-emerald-500/30" />
      <div className="text-center">
        <h2 className="text-2xl font-black tracking-tighter text-slate-300 mb-2">Training Monitor</h2>
        <p className="text-sm font-mono">Coming soon — RL agent learning curves, policy heatmaps, self-play streaming</p>
      </div>
    </div>
  );
}
