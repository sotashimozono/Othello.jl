import type { Config, GameState, PlayerType } from './types';

const API_BASE = import.meta.env.VITE_API_URL || (window.location.origin + '/api');

export async function fetchConfig(): Promise<Config> {
  const res = await fetch(`${API_BASE}/config`);
  return res.json();
}

export async function fetchGameState(index: number | null = null): Promise<GameState> {
  const url = index !== null
    ? `${API_BASE}/game/state?index=${index}`
    : `${API_BASE}/game/state`;
  const res = await fetch(url);
  return res.json();
}

export async function postMove(row: number, col: number): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/game/move`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ row, col }),
  });
  if (!res.ok) throw new Error('Invalid move');
  return res.json();
}

export async function requestAIMove(type: PlayerType): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/game/ai_move?type=${type}`);
  return res.json();
}

export async function resetGame(): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/game/reset`, { method: 'POST' });
  return res.json();
}

// --- Training API ---

export type TrainingMetricsDict = {
  episode: number;
  winner: number;
  black_score: number;
  white_score: number;
  win_rate: number;
  value: number;
  loss: number | null;
};

export type TrainingStatus = {
  is_running: boolean;
  total_episodes: number;
  completed_episodes: number;
  latest: TrainingMetricsDict | null;
};

export type TrainingHistoryEntry = TrainingMetricsDict;

export async function startTraining(numEpisodes: number, trainerType: string = 'random'): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/training/start`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ num_episodes: numEpisodes, trainer_type: trainerType }),
  });
  return res.json();
}

export async function stopTraining(): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/training/stop`, { method: 'POST' });
  return res.json();
}

export async function fetchTrainingStatus(): Promise<TrainingStatus> {
  const res = await fetch(`${API_BASE}/training/status`);
  return res.json();
}

export async function fetchTrainingHistory(): Promise<TrainingHistoryEntry[]> {
  const res = await fetch(`${API_BASE}/training/history`);
  return res.json();
}

export async function fetchTrainingPolicy(): Promise<{ policy: number[][] }> {
  const res = await fetch(`${API_BASE}/training/policy`);
  return res.json();
}

export async function fetchTrainingHyperparameters(): Promise<Record<string, unknown>> {
  const res = await fetch(`${API_BASE}/training/hyperparameters`);
  return res.json();
}

// --- Analysis API ---

export type AnalysisScore = {
  row: number;
  col: number;
  score: number;
};

export type AnalysisResult = {
  scores: AnalysisScore[];
  best: AnalysisScore | null;
  player: number;
  heatmap: number[][];
};

export async function fetchAnalysis(player: string, index: number | null = null): Promise<AnalysisResult> {
  const url = index !== null
    ? `${API_BASE}/analysis/evaluate?player=${encodeURIComponent(player)}&index=${index}`
    : `${API_BASE}/analysis/evaluate?player=${encodeURIComponent(player)}`;
  const res = await fetch(url);
  return res.json();
}

export type PVMove = {
  row: number;
  col: number;
  notation: string;
  player: number;
  step: number;
};

export type PVResult = {
  moves: PVMove[];
  boards: number[][][];
  final_score: { black: number; white: number };
  depth: number;
};

export async function fetchPrincipalVariation(player: string, depth: number, index: number | null = null): Promise<PVResult> {
  const base = `${API_BASE}/analysis/line?player=${encodeURIComponent(player)}&depth=${depth}`;
  const url = index !== null ? `${base}&index=${index}` : base;
  const res = await fetch(url);
  return res.json();
}

// --- Tournament API ---

export type TournamentPlayerSpec = string;

export type TournamentPairResult = {
  black: string;
  white: string;
  black_wins: number;
  white_wins: number;
  draws: number;
  completed: number;
  total: number;
};

export type TournamentStatus = {
  is_running: boolean;
  players: string[];
  num_games: number;
  total_pairs: number;
  completed_pairs: number;
  total_games: number;
  completed_games: number;
  results: TournamentPairResult[];
};

export async function startTournament(players: TournamentPlayerSpec[], numGames: number): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/tournament/start`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ players, num_games: numGames }),
  });
  return res.json();
}

export async function stopTournament(): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/tournament/stop`, { method: 'POST' });
  return res.json();
}

export async function fetchTournamentStatus(): Promise<TournamentStatus> {
  const res = await fetch(`${API_BASE}/tournament/status`);
  return res.json();
}
