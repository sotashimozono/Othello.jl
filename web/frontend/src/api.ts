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
