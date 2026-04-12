import { useEffect, useState, useMemo, useRef } from 'react';
import { 
  RefreshCw, Play, Settings, History, Menu, X, 
  ChevronFirst, ChevronLeft, ChevronRight, ChevronLast,
  Zap, Brain, Monitor
} from 'lucide-react';
import './index.css';

const API_BASE = import.meta.env.VITE_API_URL || (window.location.origin + '/api');

type PlayerType = 'human' | 'random' | 'greedy';

type Config = {
  colors: Record<string, string>;
  ui: {
    show_hints: boolean;
    show_last_move: boolean;
    show_kifu: boolean;
    show_eval: boolean;
  };
  web?: {
    fancy_mode: boolean;
    animate_flips: boolean;
    animation_delay: number;
    history_format: string;
  };
};

type GameState = {
  board: number[][];
  current_player: number;
  black_score: number;
  white_score: number;
  status: string;
  winner: number;
  valid_moves: number[][];
  history: string[];
  viewing_index?: number;
};

// --- Components ---

const EvaluationBar = ({ black, white }: { black: number; white: number }) => {
  const total = black + white || 1;
  const blackPct = (black / total) * 100;
  
  return (
    <div className="w-full mb-6">
      <div className="flex justify-between text-[10px] font-black uppercase tracking-tighter text-slate-500 mb-1 px-1">
        <span>Black {Math.round(blackPct)}%</span>
        <span>White {Math.round(100 - blackPct)}%</span>
      </div>
      <div className="eval-bar-container">
        <div className="eval-bar-black" style={{ width: `${blackPct}%` }}></div>
        <div className="eval-bar-marker" style={{ left: `${blackPct}%` }}></div>
        <div className="eval-bar-white" style={{ width: `${100 - blackPct}%` }}></div>
      </div>
    </div>
  );
};

// --- Main App ---

function App() {
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [liveState, setLiveState] = useState<GameState | null>(null);
  const [config, setConfig] = useState<Config | null>(null);
  
  // UI State
  const [showMenu, setShowMenu] = useState(false);
  const [viewingIndex, _setViewingIndex] = useState<number | null>(null);
  const viewingIndexRef = useRef<number | null>(null);
  
  const setViewingIndex = (val: number | null | ((prev: number | null) => number | null)) => {
    _setViewingIndex((prev) => {
      const next = typeof val === 'function' ? val(prev) : val;
      viewingIndexRef.current = next;
      return next;
    });
  };

  const [blackPlayer, setBlackPlayer] = useState<PlayerType>('human');
  const [whitePlayer, setWhitePlayer] = useState<PlayerType>('greedy');
  const [isAutoPlay, setIsAutoPlay] = useState(true);
  const [isFancy, setIsFancy] = useState(true);

  const fetchConfig = async () => {
    try {
      const res = await fetch(`${API_BASE}/config`);
      const data = await res.json();
      setConfig(data);
      if (data.web) setIsFancy(data.web.fancy_mode);
    } catch (err) {
      console.error('Failed to fetch config:', err);
    }
  };

  const fetchState = async (index: number | null = null) => {
    try {
      const url = index !== null ? `${API_BASE}/game/state?index=${index}` : `${API_BASE}/game/state`;
      const res = await fetch(url);
      const data = await res.json();
      
      if (index === null) {
        setLiveState(data);
        // CRITICAL: Only update gameState if we are NOT currently replaying
        if (viewingIndexRef.current === null) {
          setGameState(data);
        }
      } else {
        setGameState(data);
      }
    } catch (err) {
      console.error('Failed to fetch state:', err);
    } finally {
      // No-op
    }
  };

  // Initial loads
  useEffect(() => {
    fetchConfig();
    fetchState();
    const interval = setInterval(() => {
      // We pass null to fetch just the live state
      fetchState(null);
    }, 1500);
    return () => clearInterval(interval);
  }, []);

  // Sync game state when viewingIndex changes
  useEffect(() => {
    if (viewingIndex === null) {
      if (liveState) setGameState(liveState);
    } else {
      fetchState(viewingIndex);
    }
  }, [viewingIndex, liveState?.history.length]);

  // Handle Auto-Play logic
  useEffect(() => {
    if (!liveState || !isAutoPlay || gameState?.status === 'finished' || viewingIndex !== null) return;
    
    const currentPlayerType = liveState.current_player === 1 ? blackPlayer : whitePlayer;
    if (currentPlayerType !== 'human') {
      const timer = setTimeout(() => {
        handleAIMove(currentPlayerType);
      }, 800);
      return () => clearTimeout(timer);
    }
  }, [liveState?.current_player, isAutoPlay, viewingIndex]);

  useEffect(() => {
    if (config) {
      const root = document.documentElement;
      const c = config.colors;
      if (c) {
        root.style.setProperty('--color-board', c.board || '#0d6b24');
        root.style.setProperty('--color-grid', c.grid || '#054712');
        root.style.setProperty('--color-black-piece', c.black_piece || '#121217');
        root.style.setProperty('--color-white-piece', c.white_piece || '#f0f0f4');
        root.style.setProperty('--color-board-light', (c.board || '#0d6b24') + 'cc');
      }
    }
  }, [config]);

  const handleCellClick = async (row: number, col: number) => {
    if (!liveState || viewingIndex !== null || liveState.status === 'finished') return;
    const currentPlayerType = liveState.current_player === 1 ? blackPlayer : whitePlayer;
    if (currentPlayerType !== 'human') return;

    const isValid = liveState.valid_moves.some((m) => m[0] === row && m[1] === col);
    if (!isValid) return;

    try {
      await fetch(`${API_BASE}/game/move`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ row, col }),
      });
      fetchState(null);
    } catch (err) {
      console.error('Failed to move:', err);
    }
  };

  const handleAIMove = async (type: PlayerType) => {
    try {
      await fetch(`${API_BASE}/game/ai_move?type=${type}`);
      fetchState(null);
    } catch (err) {
      console.error('Failed AI move:', err);
    }
  };

  const handleReset = async () => {
    try {
      await fetch(`${API_BASE}/game/reset`, { method: 'POST' });
      setViewingIndex(null);
      fetchState(null);
    } catch (err) {
      console.error('Failed reset:', err);
    }
  };

  const formattedHistory = useMemo(() => {
    if (!liveState) return [];
    const pairs: { black: string; white: string; index: number }[] = [];
    for (let i = 0; i < liveState.history.length; i += 2) {
      pairs.push({
        black: liveState.history[i],
        white: liveState.history[i + 1] || '',
        index: i
      });
    }
    return pairs;
  }, [liveState?.history]);

  if (!gameState || !config || !liveState) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-950 text-emerald-500 font-mono animate-pulse uppercase tracking-widest text-sm gap-4">
        <div className="w-12 h-12 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
        Booting Reversi.jl Engine...
      </div>
    );
  }

  const isReplaying = viewingIndex !== null;
  const displayBoard = gameState.board;
  const historyLen = liveState.history.length;

  return (
    <div className="min-h-screen bg-[#0d0f14] text-slate-200 flex items-center justify-center p-2 md:p-8 font-['Inter'] selection:bg-emerald-500/30 overflow-x-hidden">
      
      {/* Sidebar Overlay */}
      <div className={`sidebar-overlay ${showMenu ? 'is-open' : ''}`} onClick={() => setShowMenu(false)}></div>
      
      {/* Settings Sidebar */}
      <aside className={`sidebar flex flex-col p-8 ${showMenu ? 'is-open' : ''}`}>
        <div className="flex justify-between items-center mb-10">
           <h2 className="text-xl font-black tracking-tighter flex items-center gap-3">
             <Settings className="text-emerald-500" />
             CONFIG
           </h2>
           <button onClick={() => setShowMenu(false)} className="p-2 hover:bg-white/5 rounded-full transition-colors">
             <X size={20} />
           </button>
        </div>

        <div className="space-y-8 flex-grow">
           {/* Player Selection */}
           <div className="space-y-4">
              <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Opponents</label>
              
              <div className="space-y-3">
                <div className="flex flex-col gap-2">
                  <span className="text-xs font-bold text-slate-400 flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-black border border-white/20"></div> Black Player
                  </span>
                  <select 
                    value={blackPlayer} 
                    onChange={(e) => setBlackPlayer(e.target.value as PlayerType)}
                    className="w-full bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-emerald-500 outline-none"
                  >
                    <option value="human">Human (User)</option>
                    <option value="random">Random AI</option>
                    <option value="greedy">Greedy AI</option>
                  </select>
                </div>

                <div className="flex flex-col gap-2">
                  <span className="text-xs font-bold text-slate-400 flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full bg-white"></div> White Player
                  </span>
                  <select 
                    value={whitePlayer} 
                    onChange={(e) => setWhitePlayer(e.target.value as PlayerType)}
                    className="w-full bg-slate-900 border border-white/10 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-emerald-500 outline-none"
                  >
                    <option value="human">Human (User)</option>
                    <option value="random">Random AI</option>
                    <option value="greedy">Greedy AI</option>
                  </select>
                </div>
              </div>
           </div>

           {/* Features */}
           <div className="space-y-4">
              <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Automation</label>
              <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5 group hover:bg-white/10 transition-colors cursor-pointer" onClick={() => setIsAutoPlay(!isAutoPlay)}>
                 <div className="flex items-center gap-3">
                    <Zap className={isAutoPlay ? 'text-yellow-400' : 'text-slate-600'} size={20} />
                    <span className="text-sm font-bold">Auto-Play Engine</span>
                 </div>
                 <div className={`w-10 h-5 rounded-full transition-colors relative ${isAutoPlay ? 'bg-emerald-600' : 'bg-slate-700'}`}>
                    <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${isAutoPlay ? 'left-6' : 'left-1'}`}></div>
                 </div>
              </div>
           </div>

           <div className="space-y-4">
              <label className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Visuals</label>
              <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/5 group hover:bg-white/10 transition-colors cursor-pointer" onClick={() => setIsFancy(!isFancy)}>
                 <div className="flex items-center gap-3">
                    <Brain className={isFancy ? 'text-emerald-400' : 'text-slate-600'} size={20} />
                    <span className="text-sm font-bold">Fancy Mode (Felt)</span>
                 </div>
                 <div className={`w-10 h-5 rounded-full transition-colors relative ${isFancy ? 'bg-emerald-600' : 'bg-slate-700'}`}>
                    <div className={`absolute top-1 w-3 h-3 rounded-full bg-white transition-all ${isFancy ? 'left-6' : 'left-1'}`}></div>
                 </div>
              </div>
           </div>
        </div>

        <div className="pt-6 border-t border-white/5">
           <button 
             onClick={handleReset}
             className="w-full px-6 py-4 bg-red-950/30 hover:bg-red-900/50 text-red-500 rounded-xl font-bold flex items-center justify-center gap-3 transition-all active:scale-95"
           >
             <RefreshCw size={18} />
             <span>NEW REVERSION</span>
           </button>
        </div>
      </aside>

      {/* Header Menu Button */}
      <button 
        onClick={() => setShowMenu(true)}
        className="fixed top-6 left-6 p-4 glass-panel hover:bg-white/10 rounded-2xl transition-all active:scale-90 z-50 text-emerald-500 shadow-xl"
      >
        <Menu size={24} />
      </button>

      <div className="max-w-7xl w-full grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        
        {/* Main Board Area */}
        <div className="lg:col-span-8 flex flex-col items-center">
          
          {/* Header / Scores */}
          <div className="w-full flex justify-between items-center mb-6 glass-panel px-8 py-5 relative overflow-hidden">
            <div className={`flex items-center gap-4 transition-all duration-500 ${liveState.current_player === 1 ? 'scale-110' : 'opacity-40 filter grayscale'}`}>
              <div className="relative">
                <div className="w-12 h-12 rounded-full bg-black border-2 border-slate-700 shadow-[0_0_15px_rgba(0,0,0,0.5)]"></div>
                {blackPlayer !== 'human' && <div className="absolute -bottom-1 -right-1 bg-emerald-500 rounded-full p-1"><Brain size={12} className="text-black" /></div>}
              </div>
              <div>
                <div className="text-[10px] uppercase tracking-widest text-slate-500 font-extrabold">Black</div>
                <div className="text-3xl font-black font-mono leading-none">{liveState.black_score}</div>
              </div>
            </div>

            <div className="text-center">
              <h1 className="text-2xl font-black tracking-tighter text-white opacity-90 mb-1">Reversi.jl</h1>
              <div className={`text-[9px] font-black uppercase tracking-[0.2em] px-2 py-0.5 rounded transition-all ${isReplaying ? 'bg-amber-500 text-black' : 'text-emerald-500'}`}>
                {isReplaying ? `REPLAY: ${viewingIndex} / ${historyLen}` : 'Live Play'}
              </div>
            </div>

            <div className={`flex items-center gap-4 transition-all duration-500 text-right ${liveState.current_player === -1 ? 'scale-110' : 'opacity-40 filter grayscale'}`}>
              <div className="order-2 relative">
                <div className="w-12 h-12 rounded-full bg-white border-2 border-slate-200 shadow-[0_0_15px_rgba(255,255,255,0.2)]"></div>
                {whitePlayer !== 'human' && <div className="absolute -bottom-1 -left-1 bg-emerald-500 rounded-full p-1"><Brain size={12} className="text-black" /></div>}
              </div>
              <div className="order-1">
                <div className="text-[10px] uppercase tracking-widest text-slate-500 font-extrabold">White</div>
                <div className="text-3xl font-black font-mono leading-none">{liveState.white_score}</div>
              </div>
            </div>

            {/* Background current turn indicator bar */}
            <div className={`absolute bottom-0 left-0 h-1 bg-emerald-500 transition-all duration-1000 ${liveState.current_player === 1 ? 'w-1/3' : 'w-1/3 translate-x-[200%]'}`}></div>
          </div>

          <EvaluationBar black={liveState.black_score} white={liveState.white_score} />

          {/* The Board */}
          <div className="relative group">
            <div className={`relative p-8 rounded-xl shadow-[0_20px_50px_rgba(0,0,0,0.5)] transition-all duration-700 ${isFancy ? 'board-felt border-[12px] border-[#124227]' : 'bg-slate-900 border-2 border-slate-800'}`}>
              
              {/* Coordinates */}
              <div className="absolute top-0 left-8 right-8 h-8 flex items-center justify-around text-[10px] font-black text-slate-500/60 font-mono">
                {['A','B','C','D','E','F','G','H'].map(l => <span key={l} className="w-12 md:w-16 text-center">{l}</span>)}
              </div>
              <div className="absolute left-0 top-8 bottom-8 w-8 flex flex-col items-center justify-around text-[10px] font-black text-slate-500/60 font-mono">
                {[1,2,3,4,5,6,7,8].map(n => <span key={n} className="h-12 md:h-16 flex items-center">{n}</span>)}
              </div>

              <div className={`grid grid-cols-8 gap-0 border-[1px] border-black/40 ${isFancy ? 'bg-black/10' : 'bg-black/40'}`}>
                {displayBoard.map((rowArr, rIdx) => (
                  rowArr.map((cell, cIdx) => {
                    const r = rIdx + 1;
                    const c = cIdx + 1;
                    const isValid = !isReplaying && gameState.valid_moves.some((m) => m[0] === r && m[1] === c);
                    const isStarPoint = (r === 3 || r === 6) && (c === 3 || c === 6);
                    
                    return (
                      <div
                        key={`cell-${r}-${c}`}
                        onClick={() => handleCellClick(r, c)}
                        className={`relative w-12 h-12 md:w-16 md:h-16 flex items-center justify-center border-[0.5px] border-black/10 transition-colors ${isValid ? 'cursor-pointer hover:bg-white/10' : ''}`}
                      >
                        {isFancy && isStarPoint && <div className="star-point" />}
                        {isValid && <div className="absolute w-3 h-3 rounded-full bg-emerald-400/20 animate-pulse border border-emerald-500/30"></div>}
                        
                        {cell !== 0 && (
                          <div className="piece-container">
                            <div className={`piece-inner ${cell === -1 ? 'is-white' : ''}`}>
                               <div className="piece-face piece-black"></div>
                               <div className="piece-face piece-white"></div>
                            </div>
                          </div>
                        )}
                        {!isFancy && <span className="cell-coord bottom-0.5 right-1">{String.fromCharCode(96+c)}{r}</span>}
                      </div>
                    );
                  })
                ))}
              </div>
            </div>

            {/* Replay Overlay Message */}
            {isReplaying && (
              <div className="absolute inset-0 z-20 pointer-events-none flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                 <div className="bg-amber-500/90 text-black px-4 py-2 rounded-full text-xs font-black shadow-2xl flex items-center gap-2">
                   <Monitor size={14} /> REPLAYING HISTORY
                 </div>
              </div>
            )}
          </div>

          {/* Navigation Controls */}
          <div className="mt-8 flex gap-2 glass-panel p-2">
            <button onClick={() => setViewingIndex(0)} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="Start">
              <ChevronFirst size={20} />
            </button>
            <button onClick={() => setViewingIndex(idx => idx === null ? historyLen - 1 : Math.max(0, idx - 1))} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="Back">
              <ChevronLeft size={20} />
            </button>
            
            {isReplaying ? (
              <button onClick={() => setViewingIndex(null)} className="flex items-center gap-2 px-6 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-xs font-black transition-all">
                <Play size={14} fill="white" /> RESUME LIVE
              </button>
            ) : (
              <div className="px-6 py-2 flex items-center text-[10px] font-black uppercase text-slate-500 border-x border-white/5">
                LIVE SESSION
              </div>
            )}

            <button onClick={() => setViewingIndex(idx => idx === null ? null : Math.min(historyLen, idx + 1))} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="Forward">
              <ChevronRight size={20} />
            </button>
            <button onClick={() => setViewingIndex(null)} className="nav-btn p-3 hover:bg-white/10 rounded-lg transition-all" title="End">
              <ChevronLast size={20} />
            </button>
          </div>

          {/* Winner Message */}
          {liveState.status === 'finished' && !isReplaying && (
            <div className="mt-8 px-10 py-4 glass-panel text-2xl font-black bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent animate-bounce">
              {liveState.winner === 1 ? 'BLACK DOMINATION!' : liveState.winner === -1 ? 'WHITE DOMINATION!' : 'HONORABLE DRAW!'}
            </div>
          )}
        </div>

        {/* Sidebar Data: Chronicle */}
        <div className="lg:col-span-4 flex flex-col gap-6 h-full min-h-[500px]">
          <div className="glass-panel p-6 flex-grow flex flex-col overflow-hidden">
             <div className="flex items-center gap-3 mb-6">
               <History className="text-emerald-500" size={20} />
               <h3 className="text-sm font-black uppercase tracking-widest text-slate-400">Chronicle</h3>
             </div>

             <div className="bg-black/30 rounded-xl p-4 overflow-y-auto max-h-[600px] border border-white/5 scrollbar-thin scrollbar-thumb-emerald-900 flex-grow">
               {formattedHistory.length === 0 ? (
                 <div className="text-slate-600 text-center py-20 italic font-serif opacity-50">Silencio...</div>
               ) : (
                 <div className="space-y-4">
                   {formattedHistory.map((entry, idx) => (
                     <div key={idx} className="flex flex-col gap-1 group">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-[10px] font-black text-slate-600 uppercase">Turn {idx + 1}</span>
                          <div className="h-[1px] bg-white/5 flex-grow"></div>
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                          <button 
                            onClick={() => setViewingIndex(entry.index + 1)}
                            className={`flex items-center gap-2 bg-white/5 rounded-md p-3 border hover:border-emerald-500/50 transition-all ${viewingIndex === entry.index + 1 ? 'border-emerald-500 ring-2 ring-emerald-500/20' : 'border-white/5'}`}
                          >
                            <div className="w-2 h-2 rounded-full bg-black border border-slate-600"></div>
                            <span className="font-mono text-sm uppercase">{entry.black}</span>
                          </button>

                          {entry.white && (
                            <button 
                              onClick={() => setViewingIndex(entry.index + 2)}
                              className={`flex items-center gap-2 bg-white/5 rounded-md p-3 border hover:border-emerald-500/50 transition-all ${viewingIndex === entry.index + 2 ? 'border-emerald-500 ring-2 ring-emerald-500/20' : 'border-white/5'}`}
                            >
                              <div className="w-2 h-2 rounded-full bg-white"></div>
                              <span className="font-mono text-sm uppercase">{entry.white}</span>
                            </button>
                          )}
                        </div>
                     </div>
                   ))}
                   <div id="history-end"></div>
                 </div>
               )}
             </div>
             
             <div className="mt-4 pt-4 border-t border-white/5 flex justify-between text-[10px] font-black uppercase text-slate-600 tracking-tighter">
               <span>WTHOR ENGINE V2</span>
               <span>{liveState.history.length} MOVES LOGGED</span>
             </div>
          </div>
        </div>

      </div>
    </div>
  );
}

export default App;
