import { useEffect, useState, useCallback, useRef } from 'react';
import type { TrainingStatus, TrainingHistoryEntry } from '../api';
import { startTraining, stopTraining, fetchTrainingStatus, fetchTrainingHistory, fetchTrainingPolicy } from '../api';
import { TrainingControls } from '../components/training/TrainingControls';
import { LearningCurve } from '../components/training/LearningCurve';
import { PolicyHeatmap } from '../components/training/PolicyHeatmap';
import { TrainingStats } from '../components/training/TrainingStats';

const EMPTY_POLICY = Array.from({ length: 8 }, () => new Array(8).fill(0));

export function TrainingPage() {
  const [status, setStatus] = useState<TrainingStatus>({
    is_running: false,
    total_episodes: 0,
    completed_episodes: 0,
    latest: null,
  });
  const [history, setHistory] = useState<TrainingHistoryEntry[]>([]);
  const [policy, setPolicy] = useState<number[][]>(EMPTY_POLICY);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const poll = useCallback(async () => {
    try {
      const [s, h, p] = await Promise.all([
        fetchTrainingStatus(),
        fetchTrainingHistory(),
        fetchTrainingPolicy(),
      ]);
      setStatus(s);
      setHistory(h);
      setPolicy(p.policy);
    } catch (err) {
      console.error('Training poll error:', err);
    }
  }, []);

  // Start polling when running, stop when not
  useEffect(() => {
    // Initial fetch
    poll();

    if (status.is_running) {
      pollingRef.current = setInterval(poll, 1000);
      return () => {
        if (pollingRef.current) clearInterval(pollingRef.current);
      };
    }
  }, [status.is_running, poll]);

  const handleStart = useCallback(async (numEpisodes: number, trainerType: string) => {
    try {
      await startTraining(numEpisodes, trainerType);
      // Immediately update status to show running
      setStatus(prev => ({ ...prev, is_running: true, total_episodes: numEpisodes, completed_episodes: 0, latest: null }));
      setHistory([]);
      setPolicy(EMPTY_POLICY);
      // Start polling
      pollingRef.current = setInterval(poll, 1000);
    } catch (err) {
      console.error('Failed to start training:', err);
    }
  }, [poll]);

  const handleStop = useCallback(async () => {
    try {
      await stopTraining();
      if (pollingRef.current) clearInterval(pollingRef.current);
      // Final fetch
      await poll();
    } catch (err) {
      console.error('Failed to stop training:', err);
    }
  }, [poll]);

  return (
    <div className="min-h-screen bg-[#0d0f14] text-slate-200 p-4 md:p-8 pt-16 font-['Inter']">
      <div className="max-w-7xl mx-auto space-y-6">

        {/* Header */}
        <div className="mb-2">
          <h1 className="text-2xl font-black tracking-tighter">Training Monitor</h1>
          <p className="text-sm text-slate-500 font-mono">RL agent training visualization</p>
        </div>

        {/* Controls */}
        <TrainingControls
          isRunning={status.is_running}
          onStart={handleStart}
          onStop={handleStop}
        />

        {/* Main content grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Learning Curve — 2/3 width */}
          <div className="lg:col-span-2">
            <LearningCurve history={history} />
          </div>

          {/* Policy Heatmap — 1/3 width */}
          <div>
            <PolicyHeatmap policy={policy} />
          </div>
        </div>

        {/* Stats */}
        <TrainingStats status={status} />
      </div>
    </div>
  );
}
