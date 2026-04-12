import { useEffect, useState, useRef, useCallback, useMemo } from 'react';
import type { GameState, PlayerType } from '../types';
import { fetchGameState, postMove, requestAIMove, resetGame } from '../api';

type UseGameStateReturn = {
  gameState: GameState | null;
  liveState: GameState | null;
  viewingIndex: number | null;
  setViewingIndex: (val: number | null | ((prev: number | null) => number | null)) => void;
  handleCellClick: (row: number, col: number) => void;
  handleAIMove: (type: PlayerType) => void;
  handleReset: () => void;
  isReplaying: boolean;
  historyLen: number;
  formattedHistory: { black: string; white: string; index: number }[];
};

export function useGameState(
  blackPlayer: PlayerType,
  whitePlayer: PlayerType,
  isAutoPlay: boolean,
): UseGameStateReturn {
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [liveState, setLiveState] = useState<GameState | null>(null);
  const [viewingIndex, _setViewingIndex] = useState<number | null>(null);
  const viewingIndexRef = useRef<number | null>(null);

  const setViewingIndex = useCallback(
    (val: number | null | ((prev: number | null) => number | null)) => {
      _setViewingIndex((prev) => {
        const next = typeof val === 'function' ? val(prev) : val;
        viewingIndexRef.current = next;
        return next;
      });
    },
    [],
  );

  const fetchLive = useCallback(async () => {
    try {
      const data = await fetchGameState(null);
      setLiveState(data);
      if (viewingIndexRef.current === null) {
        setGameState(data);
      }
    } catch (err) {
      console.error('Failed to fetch state:', err);
    }
  }, []);

  // Polling
  useEffect(() => {
    fetchLive();
    const interval = setInterval(fetchLive, 1500);
    return () => clearInterval(interval);
  }, [fetchLive]);

  // Sync game state when viewingIndex changes
  useEffect(() => {
    if (viewingIndex === null) {
      if (liveState) setGameState(liveState);
    } else {
      fetchGameState(viewingIndex)
        .then(setGameState)
        .catch((err) => console.error('Failed to fetch replay state:', err));
    }
  }, [viewingIndex, liveState?.history.length]);

  // Auto-play AI
  useEffect(() => {
    if (!liveState || !isAutoPlay || liveState.status === 'finished' || viewingIndex !== null) return;
    const currentPlayerType = liveState.current_player === 1 ? blackPlayer : whitePlayer;
    if (currentPlayerType !== 'human') {
      const timer = setTimeout(() => {
        handleAIMove(currentPlayerType);
      }, 800);
      return () => clearTimeout(timer);
    }
  }, [liveState?.current_player, isAutoPlay, viewingIndex]);

  const handleCellClick = useCallback(
    (row: number, col: number) => {
      if (!liveState || viewingIndex !== null || liveState.status === 'finished') return;
      const currentPlayerType = liveState.current_player === 1 ? blackPlayer : whitePlayer;
      if (currentPlayerType !== 'human') return;
      const isValid = liveState.valid_moves.some((m) => m[0] === row && m[1] === col);
      if (!isValid) return;
      postMove(row, col).then(() => fetchLive()).catch((err) => console.error('Failed to move:', err));
    },
    [liveState, viewingIndex, blackPlayer, whitePlayer, fetchLive],
  );

  const handleAIMove = useCallback(
    (type: PlayerType) => {
      requestAIMove(type).then(() => fetchLive()).catch((err) => console.error('Failed AI move:', err));
    },
    [fetchLive],
  );

  const handleReset = useCallback(() => {
    resetGame()
      .then(() => {
        setViewingIndex(null);
        fetchLive();
      })
      .catch((err) => console.error('Failed reset:', err));
  }, [fetchLive, setViewingIndex]);

  const formattedHistory = useMemo(() => {
    if (!liveState) return [];
    const pairs: { black: string; white: string; index: number }[] = [];
    for (let i = 0; i < liveState.history.length; i += 2) {
      pairs.push({
        black: liveState.history[i],
        white: liveState.history[i + 1] || '',
        index: i,
      });
    }
    return pairs;
  }, [liveState?.history]);

  return {
    gameState,
    liveState,
    viewingIndex,
    setViewingIndex,
    handleCellClick,
    handleAIMove,
    handleReset,
    isReplaying: viewingIndex !== null,
    historyLen: liveState?.history.length ?? 0,
    formattedHistory,
  };
}
