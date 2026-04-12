import { useState } from 'react';
import { Menu } from 'lucide-react';
import type { PlayerType } from '../types';
import { useConfig } from '../contexts/ConfigContext';
import { useGameState } from '../hooks/useGameState';
import { Board } from '../components/Board';
import { Header } from '../components/Header';
import { EvaluationBar } from '../components/EvaluationBar';
import { Chronicle } from '../components/Chronicle';
import { ReplayControls } from '../components/ReplayControls';
import { SettingsSidebar } from '../components/SettingsSidebar';
import { AnalysisPanel } from '../components/analysis/AnalysisPanel';

export function GamePage() {
  const { panelVisible, isFancy } = useConfig();

  const [showMenu, setShowMenu] = useState(false);
  const [blackPlayer, setBlackPlayer] = useState<PlayerType>('human');
  const [whitePlayer, setWhitePlayer] = useState<PlayerType>('greedy');
  const [isAutoPlay, setIsAutoPlay] = useState(true);

  const {
    gameState,
    liveState,
    viewingIndex,
    setViewingIndex,
    handleCellClick,
    handleReset,
    isReplaying,
    historyLen,
    formattedHistory,
  } = useGameState(blackPlayer, whitePlayer, isAutoPlay);

  if (!gameState || !liveState) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-950 text-emerald-500 font-mono animate-pulse uppercase tracking-widest text-sm gap-4">
        <div className="w-12 h-12 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
        Booting Reversi.jl Engine...
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0d0f14] text-slate-200 flex items-center justify-center p-2 md:p-8 font-['Inter'] selection:bg-emerald-500/30 overflow-x-hidden">

      <SettingsSidebar
        showMenu={showMenu}
        setShowMenu={setShowMenu}
        blackPlayer={blackPlayer}
        setBlackPlayer={setBlackPlayer}
        whitePlayer={whitePlayer}
        setWhitePlayer={setWhitePlayer}
        isAutoPlay={isAutoPlay}
        setIsAutoPlay={setIsAutoPlay}
        onReset={handleReset}
      />

      {/* Hamburger */}
      <button
        onClick={() => setShowMenu(true)}
        className="fixed top-6 left-6 p-4 glass-panel hover:bg-white/10 rounded-2xl transition-all active:scale-90 z-50 text-emerald-500 shadow-xl"
      >
        <Menu size={24} />
      </button>

      <div className="max-w-7xl w-full grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">

        {/* Main Board Area */}
        <div className="lg:col-span-8 flex flex-col items-center">

          <Header
            liveState={liveState}
            blackPlayer={blackPlayer}
            whitePlayer={whitePlayer}
            isReplaying={isReplaying}
            viewingIndex={viewingIndex}
            historyLen={historyLen}
          />

          {panelVisible('evaluation') && (
            <EvaluationBar black={liveState.black_score} white={liveState.white_score} />
          )}

          <Board
            gameState={gameState}
            isFancy={isFancy}
            isReplaying={isReplaying}
            onCellClick={handleCellClick}
          />

          {panelVisible('replay') && (
            <ReplayControls
              isReplaying={isReplaying}
              historyLen={historyLen}
              setViewingIndex={setViewingIndex}
            />
          )}

          {panelVisible('analysis') && (
            <AnalysisPanel historyLen={historyLen} viewingIndex={viewingIndex} />
          )}

          {/* Winner Message */}
          {liveState.status === 'finished' && !isReplaying && (
            <div className="mt-8 px-10 py-4 glass-panel text-2xl font-black bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent animate-bounce">
              {liveState.winner === 1 ? 'BLACK DOMINATION!' : liveState.winner === -1 ? 'WHITE DOMINATION!' : 'HONORABLE DRAW!'}
            </div>
          )}
        </div>

        {/* Sidebar */}
        {panelVisible('chronicle') && (
          <div className="lg:col-span-4 flex flex-col gap-6 h-full min-h-[500px]">
            <Chronicle
              formattedHistory={formattedHistory}
              historyLen={historyLen}
              viewingIndex={viewingIndex}
              setViewingIndex={setViewingIndex}
            />
          </div>
        )}
      </div>
    </div>
  );
}
