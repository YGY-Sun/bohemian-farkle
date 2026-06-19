# Bohemian Tavern Static UI Design

## Goal

Create the first layer of the Bohemian tavern dice table UI for the existing Godot Farkle MVP. This layer should replace the plain prototype interface with a close, immersive tavern tabletop scene while keeping the current game rules and turn flow unchanged.

The player should feel seated at a wooden tavern table with dice, parchment score sheets, candlelight, a cup, and a coin pouch around the play area. Animation, audio, roll physics, and win/loss presentation are intentionally deferred to later layers.

## Scope

Included in this phase:

- A full-screen tavern tabletop composition.
- Parchment-style score and rules panels.
- Dice buttons styled as physical bone or ivory dice.
- Clear selected, disabled, current-turn, and game-over visual states.
- Existing controls for roll, bank, new game, and AI difficulty.
- Small static tavern props such as candle, cup, and coin pouch as decorative Godot UI elements.
- Refactoring UI construction into helper methods if needed to keep `Main.gd` readable.

Deferred to later phases:

- Dice roll animation and table impact.
- Candle flicker, lighting animation, and AI action pacing effects.
- Sound effects and ambient tavern audio.
- Special visual effects for hot dice, busts, banking, and victory.
- High-resolution painted or generated bitmap assets.

## Current Context

The active project is `/Users/ygy/Downloads/vibe_game_dev/farkle`. The main scene is `scenes/Main.tscn`, which attaches `scripts/Main.gd` to a root `Control`. The MVP currently builds all UI dynamically in `_build_ui()` and refreshes dice and labels in `_refresh_ui()`.

Game logic already supports:

- Single-player mode against AI.
- AI difficulty selection.
- Player and AI scores toward a 4000 point target.
- Dice selection and scoring.
- Banking, busts, hot dice, and turn changes.

The UI redesign should preserve this logic and avoid changing scoring or AI behavior.

## Visual Direction

The screen is a close tavern tabletop:

- Background: dark wooden table with subtle planks, scratches, and warm vignette.
- Left panel: parchment score sheet pinned or weighted on the table.
- Center: open rolling space where dice appear as tangible square dice.
- Bottom center: roll and bank controls as carved wood or brass tavern buttons.
- Right panel: parchment rule note or tavern notice.
- Top: compact title, AI difficulty, and new game controls integrated into the tabletop rather than treated as a modern app header.
- Props: candle, cup, and coin pouch stay decorative and should not obscure game controls.

The palette should use dark wood, aged parchment, warm candle amber, bone dice, muted brass, and deep shadows. The UI should avoid a flat modern dashboard feel.

## Layout

Use one root full-screen `Control` with responsive margins. The layout should work at the current configured viewport of 1280x720 and remain usable under Godot's canvas item stretch settings.

Recommended structure:

- `MarginContainer` as the full-screen safe area.
- `VBoxContainer` or layered `Control` for top controls, table content, and bottom actions.
- A main horizontal content area:
  - Left score parchment.
  - Center dice table.
  - Right rules parchment.
- Bottom action row centered beneath the dice area.

The center dice area should stay visually dominant. Text panels should be compact enough that the table still feels like the main subject.

## Components

### Tavern Background

Create a custom full-screen background using Godot controls or draw methods:

- Base dark brown fill.
- Subtle plank bands and table grain lines.
- Warm radial or rectangular light impression near the dice area.
- Dark edge vignette using translucent overlays.

This should be procedural in phase one so the project does not depend on external art assets.

### Score Parchment

The score panel shows:

- Player 1 score and target.
- AI score and difficulty.
- Current turn owner.
- Current turn score.
- A small progress indication toward 4000 if practical with standard controls.

The active player should be visually emphasized with a warm border or darker ink mark.

### Dice Area

Dice remain clickable `Button` controls. Each die should look like a physical die:

- Fixed square size.
- Bone or ivory face color.
- Dark pips instead of plain numeric text if feasible within the implementation.
- Beveled border and soft shadow.
- Selected dice get a warm amber ring, raised tint, or slight offset.
- Disabled AI dice remain readable but less interactive.

If pips would make the first implementation too large, numeric dice are acceptable only as a fallback, but they should still use physical dice styling.

### Action Controls

Roll and Bank remain prominent and centered:

- Large tactile buttons.
- Roll should read as the primary action.
- Bank should be disabled clearly when unavailable.
- Buttons should not shift layout when states change.

New Game and AI Difficulty stay accessible but secondary.

### Rules Parchment

The rules panel keeps the scoring reference from the current MVP, but should be formatted for scanability:

- Short heading.
- Compact rule rows.
- No long paragraph block.

### Status Text

Status messages should appear as a short tavern-table notice near the dice area. It should remain readable and should not push the dice layout around.

## Data Flow

No game-state model changes are required.

Existing state values should map into the redesigned UI:

- `banked_scores` updates score parchment.
- `turn_score` updates current-turn score.
- `current_player` controls active-player emphasis.
- `dice_values` rebuilds dice controls.
- `held_indices` controls selected dice style.
- `can_bank`, `game_over`, and `_is_human_turn()` control button enabled states.
- `ai_difficulty` updates the AI label and difficulty option.
- `status_label.text` remains the source of status feedback.

## Error Handling

The UI should preserve existing validation behavior:

- Invalid selections still show the current status messages.
- Busts still clear the turn score and pass the turn.
- Game-over still disables play actions.
- AI turns still disable human dice and controls.

No new error paths are expected in this phase.

## Testing And Verification

Manual verification is sufficient for this UI-only phase:

- Open the Godot project and run the main scene.
- Confirm the scene starts at 1280x720 with no overlapping text or controls.
- Roll dice, select scoring and non-scoring dice, bank points, and start a new game.
- Confirm AI turns leave dice visible but non-clickable.
- Confirm Easy, Normal, and Hard AI labels display correctly.
- Confirm disabled Roll and Bank states are visually distinct.
- Confirm the rules panel is readable without scrolling.

If command-line Godot is available, also run the project once from the terminal to catch script errors.

## Approval Criteria

This phase is complete when the playable MVP has the static appearance of a close Bohemian tavern dice table, all existing interactions still work, and the layout is clear enough for review before adding animation and effects in later layers.
