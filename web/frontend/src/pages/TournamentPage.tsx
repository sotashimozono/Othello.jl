import { RefreshCw } from 'lucide-react';

export function TournamentPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-6 text-slate-500">
      <RefreshCw size={48} className="text-emerald-500/30" />
      <div className="text-center">
        <h2 className="text-2xl font-black tracking-tighter text-slate-300 mb-2">Tournament</h2>
        <p className="text-sm font-mono">Coming soon — round-robin matches, Elo ratings, result dashboards</p>
      </div>
    </div>
  );
}
