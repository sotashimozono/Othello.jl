# Reversi GUI: Architecture & Modularization Plan

To support high-quality analytical tools and future extensions (Graphs, Animations, Multi-engine support), we will refactor `ext/ReversiGLMakieExt.jl` into a clear **4-Layer Architecture**.

## 1. Directory Structure
```
ReversiGLMakieExt/
├── ReversiGLMakieExt.jl  # Module Entry (Includes & Top-level Exports)
├── constants.jl          # Theme system, Colors, Layout constants
├── components/           # Reusable Graphic Components
│   ├── board.jl          # Board logic (drawing, clicking, piece placement)
│   ├── sidebar.jl        # Unified analytical sidebar (Score, Status, Graphs)
│   ├── kifu.jl           # Move history presentation and jump logic
│   └── dialogs.jl        # Config dialogs (Add Player, Settings)
├── views/                # Specific Application Modes
│   ├── game_view.jl      # Implementation of launch_gui (Live Game)
│   └── replay_view.jl    # Implementation of launch_replay_gui (History)
└── core_logic/           # State Management (GUI-specific)
    └── game_task.jl      # Async game loop and player interaction
```

---

## 2. Key Refactoring Goals

### A. Centralized Theme System (`constants.jl`)
Move all color lookups, font sizes, and layout fixed measurements to a shared constant or a theme accessor based on `GUIConfig`. This allows for easy dark/light mode switching and consistent aesthetics across `game_view` and `replay_view`.

### B. Decoupled Drawing Logic (`components/board.jl`)
Separating `_draw_board!`, `_draw_pieces!`, and `_draw_hints!` from the main GUI setup. These functions should take an `Axis` as an argument and be purely responsible for rendering state, not managing it.

### C. Unified Sidebar (`components/sidebar.jl`)
Instead of scattered labels, create a single `Sidebar` component that handles:
- Real-time score display.
- Turn indicator.
- **New**: Evaluation graph (integrated line plot).
- **New**: Player selection menus (clustered).

### D. Replay Synchronization
Refactor the move history (`kifu.jl`) to be an interactive component. When a row is clicked, it should trigger an event that update the `game_obs::Observable` in the main view.

---

## 3. High-Concurrency & Async Design

### A. Decoupled AI Worker Tasks
Heavy computations (evaluation, search) are executed in dedicated `Task` objects. Communications use `Channel{Move}` and `Channel{EngineProgress}` to keep the GLMakie rendering loop completely non-blocking.
- **Progress Tracking**: The engine emits periodic metadata (NPS, depth) to the progress channel, which update a dashboard in the sidebar.

### B. UI Locking & State Machine
To prevent "move collision" (e.g., clicking while an animation is playing), a central `UIStatus` observable tracks the current lock state:
- `:IDLE`: All inputs accepted.
- `:ANIMATING`: Stone flip in progress. Board clicks ignored. Jump/Navigation cancels the animation.
- `:THINKING`: AI engine active. Board clicks ignored. "Cancel" button available in sidebar.

### C. Keyboard Shortcut Handling
Using Makie's `events(fig.scene).keyboardbutton`, we implement a global handler for:
- `Keyboard.left/right`: Incremental navigation.
- `Keyboard.home/end`: Boundary navigation.
- `Keyboard.space`: Toggling the `UIStatus` between `:RUNNING` and `:PAUSED`.

---

## 4. Advanced Feature Implementation Strategy

### Evaluation Graphs
We will use Makie's `Lines` and `Stairs` on a small dedicated `Axis` within the sidebar. This axis will be reactive to a `history_ref` to show the full trend of the game.

### Performance & Stability (macOS)
- Maintain the **500ms delay** for OpenGL initialization.
- Use `render_loop` optimizations to ensure smooth 60fps animations even during complex UI updates.

---

## 5. Configuration System & Persistence (`config/`)

To ensure a robust and user-friendly experience, the system uses a **Layered Configuration Architecture**.

### A. Variable Categories
Settings in `config/default_config.toml` are grouped into:
1. **[UI.Theme]**: 
    - `background`, `board`, `grid`, `text`, `accent_black`, `accent_white`, `hint`.
    - These are the only source of truth for colors in `components/`.
2. **[UI.Layout]**: 
    - `window_width`, `window_height`, `sidebar_width`.
    - `fontsize`, `icon_size`.
3. **[App]**:
    - `init_delay_ms` (Crucial for macOS OpenGL stability).
    - `fps_limit`.
4. **[Game]**:
    - `default_black`, `default_white` (Player names).
    - `show_hints`, `show_last_move`.
5. **[Engine] (Future)**:
    - `search_depth`, `time_limit`, `evaluation_fn`.

### B. Hierarchical Loading Priority
The configuration is merged in the following order (Last one wins):
1. **Bundled Defaults**: `config/default_config.toml` (Read-only).
2. **User Overrides**: `~/.reversirc.toml` (Persistent user preferences).
3. **Session Cache**: `/tmp/reversi_session.toml` (Last window size, toggles).
4. **Environment Variables**: `REVERSI_UI_THEME_BOARD` (Critical for CI/Custom scripts).

### C. Type Safety & Validation
The `src/UI/config.jl` module will use a typed `GUIConfig` struct (via `Base.@kwdef` or a validation library) to ensure that invalid colors or sizes are caught at launch rather than during rendering.

---

## 6. Migration Timeline
1.  **Phase 1**: Initial splitting of constants and board drawing helpers.
2.  **Phase 2**: Refactoring `launch_gui` move history into its own modular component.
3.  **Phase 3**: Implementing the side-by-side Analytical Sidebar (Score + Graph).
4.  **Phase 4**: Integrating smooth transitions for stone flips.
