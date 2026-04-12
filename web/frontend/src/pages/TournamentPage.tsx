import { useEffect, useState, useCallback, useRef } from 'react';
import type { TournamentStatus } from '../api';
import { startTournament, stopTournament, fetchTournamentStatus } from '../api';
import { TournamentControls } from '../components/tournament/TournamentControls';
import { ResultsMatrix } from '../components/tournament/ResultsMatrix';
import { TournamentProgress } from '../components/tournament/TournamentProgress';

const EMPTY_STATUS: TournamentStatus = {
  is_running: false,
  players: [],
  num_games: 0,
  total_pairs: 0,
  completed_pairs: 0,
  total_games: 0,
  completed_games: 0,
  results: [],
};

export function TournamentPage() {
  const [status, setStatus] = useState<TournamentStatus>(EMPTY_STATUS);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const poll = useCallback(async () => {
    try {
      const s = await fetchTournamentStatus();
      setStatus(s);
    } catch (err) {
      console.error('Tournament poll error:', err);
    }
  }, []);

  useEffect(() => {
    poll();
    if (status.is_running) {
      pollingRef.current = setInterval(poll, 1000);
      return () => {
        if (pollingRef.current) clearInterval(pollingRef.current);
      };
    }
  }, [status.is_running, poll]);

  const handleStart = useCallback(async (players: string[], numGames: number) => {
    try {
      await startTournament(players, numGames);
      setStatus(prev => ({ ...prev, is_running: true, players, num_games: numGames }));
      pollingRef.current = setInterval(poll, 1000);
    } catch (err) {
      console.error('Failed to start tournament:', err);
    }
  }, [poll]);

  const handleStop = useCallback(async () => {
    try {
      await stopTournament();
      if (pollingRef.current) clearInterval(pollingRef.current);
      await poll();
    } catch (err) {
      console.error('Failed to stop tournament:', err);
    }
  }, [poll]);

  return (
    <div className="min-h-screen bg-[#0d0f14] text-slate-200 p-4 md:p-8 pt-16 font-['Inter']">
      <div className="max-w-7xl mx-auto space-y-6">

        <div className="mb-2">
          <h1 className="text-2xl font-black tracking-tighter">Tournament</h1>
          <p className="text-sm text-slate-500 font-mono">Round-robin matches between classical players</p>
        </div>

        <TournamentControls
          isRunning={status.is_running}
          onStart={handleStart}
          onStop={handleStop}
        />

        <TournamentProgress status={status} />

        <ResultsMatrix players={status.players} results={status.results} />
      </div>
    </div>
  );
}
