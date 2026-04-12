import { useConfig } from '../contexts/ConfigContext';
import type { PanelName } from '../types';

const PANEL_LABELS: { name: PanelName; label: string }[] = [
  { name: 'chronicle', label: 'Chronicle (Move History)' },
  { name: 'evaluation', label: 'Evaluation Bar' },
  { name: 'replay', label: 'Replay Controls' },
  { name: 'training', label: 'Training Monitor' },
  { name: 'analysis', label: 'Game Analysis' },
  { name: 'tournament', label: 'Tournament' },
];

export function ConfigTab() {
  const { panelVisible, setPanelVisible } = useConfig();

  return (
    <div className="space-y-4">
      <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Panels</label>
      <div className="space-y-2">
        {PANEL_LABELS.map(({ name, label }) => (
          <div
            key={name}
            className="flex items-center justify-between p-3 bg-white/5 rounded-xl border border-white/5 hover:bg-white/10 transition-colors cursor-pointer"
            onClick={() => setPanelVisible(name, !panelVisible(name))}
          >
            <span className="text-sm font-bold">{label}</span>
            <div className={`w-10 h-5 rounded-full transition-colors relative ${panelVisible(name) ? 'bg-emerald-600' : 'bg-slate-700'}`}>
              <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${panelVisible(name) ? 'left-6' : 'left-1'}`}></div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
