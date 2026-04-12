export type PlayerType = 'human' | 'random' | 'greedy';

export type PanelName =
  | 'chronicle'
  | 'evaluation'
  | 'replay'
  | 'training'
  | 'analysis'
  | 'tournament'
  | 'opening';

export type Config = {
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
    panels?: Partial<Record<PanelName, boolean>>;
  };
};

export type GameState = {
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
