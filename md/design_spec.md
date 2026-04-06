# Analytical Reversi Workbench: Universal Design Specification

## 1. Vision & Core Objectives
The Reversi GUI is not just a game player; it is an **analytical workbench** for studying game strategy and AI behavior. It must feel professional, responsive, and data-rich.

### Key Objectives:
- **Visual Hierarchy**: A board-centric layout where the most critical information (Current Player, Score, Evolution) is immediately scannable.
- **Analytical Depth**: Real-time evaluation of board states using graphs and evaluation bars.
- **Premium Interaction**: Smooth transitions, translucent hovers, and intuitive navigation.

---

## 2. Layout Architecture (The "Side-by-Side" Paradigm)
To achieve maximum focus and eliminate "floating" elements, we adopt a unified **3-Zone Structure**.

### Zone A: Header (Global Actions) [Compact, Fixed Height]
- **Actions Menu**: A single discrete menu containing "New Game", "Reset", and "Add Player".
- **Global Stats**: FPS indicator and session timer.

### Zone B: Main (Board & Interaction) [Relative 1.0]
- **The Board**: Centered, high-contrast 8x8 grid.
- **Hover Preview**: Translucent ghost-stones showing the result of a potential move.
- **Legal Move Highlights**: Suble dots in playable cells (Togglable).
- **Last Move Indicator**: A subtle, high-contrast dot or ring on the most recent piece.

### Zone C: Analytical Sidebar [Fixed Width, Right]
- **Top: Game Status**: 
    - Large, bold indicators for "Black's Turn" / "White's Turn".
    - Score bar: A horizontal progress bar showing the dominance of Black vs White.
- **Middle: Analytical Tools**:
    - **Evaluation Graph**: A real-time line chart showing the player's advantage (e.g., +10 for Black) over time.
    - **Progress Feedback**: A small status indicator (e.g., "AI thinking: 100k nodes/s") during engine computation.
    - **Player Config**: Collapsible section for selecting Human/AI for both roles.
- **Bottom: Move History (Kifu)**:
    - Vertically packed list with top-alignment.
    - **Interactivity**: Clicking a move in the list jumps the board to that state (Replay Sync).

---

## 3. Interaction & State Machine

### A. Operational Modes
- **Live Mode**: The default state for active play. The board shows the current game state and waits for user/AI moves.
- **Review Mode**: Triggered when the user clicks a past move in the Kifu or uses navigation shortcuts. 
    - The "Live" game is paused or remains in background.
    - The board switches to a read-only historical view.
    - A "Return to Live" button appears prominently to exit review mode.

### B. Input Locking & Concurrency
- **Action Blocking**: During stone flipping animations (0.2s) or while the AI is "thinking" in its own task, user clicks on the board are ignored to prevent inconsistent states.
- **Animation Cancellation**: If a user performs a "Jump" (e.g., Home/End) while an animation is playing, the animation is immediately terminated, and the board state is snapped to the target state.

---

## 4. Keyboard Shortcuts & Navigation
For a professional feel, the workbench supports full keyboard navigation:
- **Left / Right Arrow**: Step backward/forward in move history (Switches to Review Mode).
- **Home / End**: Jump to the beginning (initial state) or end (current state).
- **Space**: Pause/Resume AI thinking or animations.
- **N**: Trigger "New Game".

---

## 5. Responsiveness & Layout Rules
- **Aspect Ratio**: The board (Zone B) always maintains a `DataAspect()`正方形. Excess space is allocated to Zone C (Sidebar) or Zone A's horizontal margins.
- **Sidebar Constraints**: Zone C has a `Fixed` minimum width (e.g., 200px) to ensure graphs and Kifu labels remain readable.
- **Window Min-Size**: The application window will have a hard-coded minimum size (e.g., 800x600) to prevent UI collapse.

---

## 6. Feedback & Animation
- **Piece Transitions**: When pieces are flipped, they should not simply switch colors. A 0.2s fade or scaling animation in Makie will significantly improve the "feel".
- **Turn Prompts**: The background or sidebar color shifts subtly to match the current player's color.

---

## 4. Technical Feasibility (Makie Stack)
- **High Performance**: GLMakie is perfectly suited for real-time evaluation graphs (using `Lines` or `Stairs`).
- **Observables**: The entire UI is reactive to the `game_obs::Observable{ReversiGame}`.
- **Custom Shaders**: Potential for high-quality stone textures and lighting in future iterations.

---

## 5. Future Extensibility
- **Database Integration**: Loading/Saving games directly from the GUI.
- **Engine Analysis**: Deep integration with external engines (e.g., through a standardized protocol).
