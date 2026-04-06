UI Modernization: Analytical Workbench 2.0 (Requirements)
1. Problem Statement
The current UI has "floating" toggles, confusing labeling for player types, and lacks the ability to hide/show analytical panels based on user preference. This leads to a cluttered experience and occasional state-UI mismatches.

2. Structural Requirements
A. Unified Analysis Toolbar
Grouping: Consolidate "Hints", "Last Move", and "Live/Review" indicators into a single horizontal toolbar.
Visuals: Use icons or clearly labeled button groups instead of scattered toggles.
Context: Show engine statistics (if AI is active) within this toolbar.
B. Reliable Player Identity
State Sync: The "Human/Random" selection in the top bar MUST strictly reflect the config and current PlayerDict at all times.
Clearer Prompts: Ensure Menu prompts match the selected player name.
C. Config-Driven Layout
Visibility Toggles: Add show_eval_panel and show_sidebar to the config and UI.
Dynamic Resize: The board should expand/contract cleanly when the sidebar is hidden.
3. Component Refinements
A. Professional Hints
Dot Style: Use translucent stones or subtle numeric "value" indicators in the playable squares.
Toggle Location: Move the toggle closer to the board or into the new Analysis Toolbar.
B. Interaction Locking
Ensure board clicks are 100% disabled during AI thinking and Review mode to prevent "ghost moves."
4. Implementation Steps
Phase 1: Update GUIConfig and load_config to support new visibility and player defaults.
Phase 2: Implement the AnalysisToolbar component in components/.
Phase 3: Refactor 
game_view.jl
 to use conditional layout (hide/show panels).
Phase 4: Audit and fix the Player selection sync logic (Ensure i_selected is calibrated).
Next Step: Please review these requirements. Once approved, I will begin implementing the AnalysisToolbar.


Comment
⌥⌘M
