import { useEffect, useState } from 'react';
import { BookOpen } from 'lucide-react';
import type { OpeningBookStatus, OpeningLookup } from '../../api';
import { fetchOpeningStatus, fetchOpeningLookup } from '../../api';
import { OpeningBookTable } from './OpeningBookTable';

type OpeningBookPanelProps = {
  historyLen: number;
  viewingIndex: number | null;
};

export function OpeningBookPanel({ historyLen, viewingIndex }: OpeningBookPanelProps) {
  const [status, setStatus] = useState<OpeningBookStatus | null>(null);
  const [lookup, setLookup] = useState<OpeningLookup | null>(null);

  useEffect(() => {
    fetchOpeningStatus().then(setStatus).catch(err => console.error('Opening status error:', err));
  }, []);

  useEffect(() => {
    if (!status?.loaded) {
      setLookup(null);
      return;
    }
    fetchOpeningLookup(viewingIndex)
      .then(setLookup)
      .catch(err => {
        console.error('Opening lookup error:', err);
        setLookup(null);
      });
  }, [viewingIndex, historyLen, status?.loaded]);

  return (
    <div className="glass-panel p-6 mt-6 w-full">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <BookOpen className="text-emerald-500" size={18} />
          <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400">Opening Book</h3>
        </div>
        {status?.loaded && (
          <div className="text-[9px] font-mono text-slate-500">
            {status.game_count} games · {status.entry_count} positions
          </div>
        )}
      </div>

      {!status && (
        <div className="text-xs text-slate-600 italic">Checking opening book status…</div>
      )}

      {status && !status.loaded && (
        <div className="text-xs text-slate-500 space-y-2">
          <p>No opening book loaded.</p>
          <p className="text-slate-600 font-mono text-[10px]">
            Set <code>[web.opening] wthor_path</code> in <code>config/default_config.toml</code>
            {' '}or POST to <code>/api/opening/build</code> with a WTHOR <code>.wtb</code> file path.
          </p>
        </div>
      )}

      {status?.loaded && lookup && !lookup.found && (
        <div className="text-xs text-slate-600 italic py-2">
          Position not in book (out of opening range, hash: <span className="font-mono">{lookup.hash?.slice(0, 8)}…</span>)
        </div>
      )}

      {status?.loaded && lookup && lookup.found && (
        <div className="space-y-4">
          <div className="grid grid-cols-4 gap-3 text-xs">
            <Stat label="Games" value={String(lookup.total)} />
            <Stat label="Black wins" value={`${lookup.black_wins} (${pct(lookup.black_wins, lookup.total)}%)`} color="text-slate-200" />
            <Stat label="White wins" value={`${lookup.white_wins} (${pct(lookup.white_wins, lookup.total)}%)`} color="text-slate-200" />
            <Stat label="Draws" value={String(lookup.draws)} />
          </div>
          <OpeningBookTable candidates={lookup.candidates ?? []} total={lookup.total ?? 0} />
        </div>
      )}
    </div>
  );
}

function Stat({ label, value, color = 'text-emerald-400' }: { label: string; value: string; color?: string }) {
  return (
    <div className="bg-white/5 rounded-xl p-3 border border-white/5">
      <div className="text-[9px] font-black uppercase tracking-widest text-slate-600">{label}</div>
      <div className={`text-sm font-mono font-bold ${color}`}>{value}</div>
    </div>
  );
}

function pct(n: number | undefined, total: number | undefined): string {
  if (!n || !total) return '0';
  return ((n / total) * 100).toFixed(0);
}
