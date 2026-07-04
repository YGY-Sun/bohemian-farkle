# Bohemian Farkle Development Roadmap

## Product Vision

Bohemian Farkle is not just a direct Farkle clone. It is a tavern dice battle game built around progression, opponents, equipment, and risk.

The intended core loop is:

1. Enter a tavern.
2. Choose a table or opponent.
3. Equip dice and badges.
4. Play a dice match.
5. Win coins, reputation, or unlock progress.
6. Unlock stronger opponents, better tables, new dice, and new badge options.

The game should keep the fast, readable tension of Farkle while gradually growing into a richer tavern gambling experience.

## Current State

The project currently has a playable Godot MVP with the M1 gameplay core and M2 tavern tabletop UI merged into `main`:

- Single-player match against AI.
- Target score of 4000.
- Easy, Normal, and Hard AI difficulty.
- Dice rolling, dice selection, banking, busts, hot dice, and win detection.
- Farkle scoring rules including singles, sets, straights, short straights, and three pairs.
- A command-style gameplay core in `scripts/core/`.
- A tavern tabletop UI with background art, parchment score/rules panels, and physical dice art.
- UI wired to the gameplay core instead of calculating match outcomes directly.
- Bust turn-transition feedback has been clarified after the M1/M2 merge.

The next priority is M2.1 integration stabilization: verify the merged core/UI experience in Godot, close any feedback gaps, and decide how to handle generated Godot `.uid` files before starting M3 progression systems.

## Guiding Principles

### Build A Game Kernel, Not A Screen Script

The gameplay rules should not live inside the UI layer. UI should display state and send player intent. The gameplay core should decide what happens.

`Main.gd` should eventually become a Godot UI adapter, not the owner of scoring, turns, AI decisions, and match rules.

### Command-Based Player Actions

All player actions should become commands:

- `RollRequested`
- `DiceSelected`
- `BankRequested`
- `TurnEnded`

In single-player, commands come from local UI buttons and AI logic.

In local multiplayer, commands come from two local players.

In online multiplayer, commands come from network messages.

This keeps the future networking model from forcing a rewrite of the game rules.

### MatchConfig Drives Each Match

Each match should be created from a configuration object.

Initial fields:

- Target score.
- Player types: human, AI, or network player.
- AI difficulty.
- Special dice enabled or disabled.
- Badge effects enabled or disabled.
- Reward multiplier.

Future fields may include:

- Table rules.
- Tavern ID.
- Opponent ID.
- Entry fee.
- Reward profile.
- Allowed dice or badge restrictions.

### Tests Protect The Foundation

The rules must be tested before the project grows more UI, AI, economy, and networking features.

Priority test areas:

- Scoring rules.
- Bust detection.
- Hot dice behavior.
- Turn transitions.
- Banking.
- AI keep and bank decisions.
- Match configuration behavior.

A stable test suite is especially important because special dice, badge effects, and online sync will all depend on deterministic gameplay behavior.

### Long-Term Systems Should Be Designed Before Fully Built

The project should reserve structure for long-term progression systems without implementing all of them immediately.

Long-term systems:

- Coins.
- Reputation.
- Dice collection.
- Badge inventory.
- Badge equipment.
- NPC opponents.
- Tavern and table unlocks.
- Match history and statistics.
- Save data.

The goal is to avoid boxing the project into a one-off dice screen while still staying focused on the next milestone.

## Architecture Direction

### Gameplay Core

The gameplay core owns rules and state transitions.

Responsibilities:

- Match setup.
- Dice rolling.
- Dice selection validation.
- Scoring.
- Bust detection.
- Hot dice handling.
- Banking.
- Turn transitions.
- Win detection.
- Command processing.

The gameplay core should not depend on Godot UI nodes.

### UI Layer

The UI layer owns presentation and input capture.

Responsibilities:

- Render score, dice, controls, status, and match progress.
- Show selected, disabled, current-turn, and game-over states.
- Convert button clicks into gameplay commands.
- Display gameplay results returned by the core.

The UI should not calculate final game results directly.

### AI Layer

The AI layer decides which commands to send during an AI turn.

Responsibilities:

- Choose scoring dice.
- Decide whether to bank or continue rolling.
- Apply difficulty-specific risk profiles.
- Eventually support NPC personalities and table-specific strategies.

The AI should use the same gameplay command API as a human player.

### Progression Layer

The progression layer owns persistent player growth.

Responsibilities:

- Coins.
- Reputation.
- Unlocks.
- Dice collection.
- Badge collection.
- Equipped loadout.
- Match rewards.
- Match history.

This layer should not be required for the first gameplay-core refactor, but the data shape should be considered early.

### Networking Layer

The networking layer should eventually transmit commands and authoritative state.

Responsibilities:

- Room creation.
- Player connection.
- Command sync.
- State reconciliation.
- Disconnect handling.
- Rejoin or forfeit behavior.

Networking should not own gameplay rules. It should move commands and state between players.

## Development Progress Tracker

This table tracks each milestone, its working branch, current progress, and merge status. It should be updated whenever a milestone branch is created, merged, paused, or superseded.

| Milestone | Purpose | Branch | Status | Progress | Notes |
| --- | --- | --- | --- | ---: | --- |
| M0: Playable Prototype | Establish the first playable Godot Farkle MVP. | `main` | Complete | 100% | Initial single-player AI match, scoring, banking, busts, hot dice, and prototype UI. |
| M1: Stable Gameplay Core | Extract scoring, match state, config, commands, and AI policy into a tested gameplay core. | `codex/gameplay-core-refactor` | Complete | 100% | Merged into `main`. Added `FarkleScorer`, `FarkleMatch`, `MatchConfig`, `AiPolicy`, and core tests. |
| M2: Tavern Table UI Integration | Replace the prototype UI with a playable Bohemian tavern tabletop interface. | `bohemian-tavern-static-ui` | Complete | 100% | Merged into `main`. Added tavern table visuals, dice art, parchment panels, and connected UI to the gameplay core. |
| M2.1: Integration Stabilization | Stabilize M1+M2 merged gameplay/UI behavior. | `main` | In Progress | 60% | Bust turn-transition feedback has been fixed. Needs Godot editor verification, visual QA, and a `.uid` file policy. |
| M3: NPC, Coins, Dice, And Badges | Add first progression systems: NPCs, rewards, dice collection, badges, and loadouts. | `TBD` | Not Started | 0% | Should start after M2.1 verification. |
| M4: Local Multiplayer, Settings, And Save Data | Add local two-player mode, setup screens, settings, persistence, and match history. | `TBD` | Not Started | 0% | Depends on stable command flow and initial progression data. |
| M5: Online Rooms And Synchronization | Add online rooms, network player commands, state sync, and disconnect handling. | `TBD` | Not Started | 0% | Requires deterministic/authoritative match handling decisions. |
| M6: Content Polish And Release Preparation | Add animation, sound, ambience, content depth, export builds, and QA. | `TBD` | Not Started | 0% | Final polish phase after the core game loop, progression, and multiplayer foundations are stable. |

## Branch Coordination Rules

- `main` should remain the stable baseline.
- Feature work should happen on milestone or task branches.
- UI work and gameplay-core work should stay isolated until a stable gameplay API exists.
- M2 should avoid reimplementing gameplay rules in UI code.
- M1 should avoid making visual UI redesign decisions.
- When merging parallel feature tracks, resolve API boundaries deliberately rather than letting one branch overwrite the other.
- Branches should be merged only after their tests or manual verification criteria are satisfied.

## Recently Completed Integration

Two major tracks were completed and merged into `main`:

1. `codex/gameplay-core-refactor`
   - Owns M1 gameplay architecture.
   - Added scoring tests, match config, command flow, AI policy, and a UI adapter flow.

2. `bohemian-tavern-static-ui`
   - Owns M2 visual/interface direction.
   - Replaced the plain prototype interface with the tavern tabletop experience.

Integration notes:

- The UI should only render state and send commands.
- The gameplay core should remain the source of truth for scoring, turn transitions, busts, banking, and win detection.
- Bust feedback was corrected after integration so rolls such as `2-3-3-4-6-6` visibly pass the turn.
- The merged build still needs Godot editor verification because command-line Godot is not available in the current automation environment.

## Milestones

## M1: Stable Single-Player Gameplay Core

Goal: Turn the current prototype rules into a tested, extensible gameplay kernel.

Scope:

- Extract scoring from `Main.gd`.
- Extract match configuration.
- Extract turn and match state.
- Extract command-style player actions.
- Extract AI decision policy.
- Add tests for scoring, busts, hot dice, banking, turn flow, and AI decisions.
- Keep the existing UI playable if practical, but prioritize core correctness.

Success criteria:

- Core gameplay can be tested without manually clicking the UI.
- `Main.gd` no longer owns the rule system.
- Existing single-player match still works through the new gameplay API.
- Tests cover the rules most likely to break during future expansion.

## M2: Tavern Table UI Integration

Goal: Replace the plain prototype interface with a playable tavern tabletop experience.

Scope:

- Build the static tavern table UI.
- Add parchment score/rules panels.
- Style dice as physical table dice.
- Preserve current controls: roll, bank, new game, AI difficulty.
- Connect UI to the gameplay core command API.
- Keep animation and sound deferred unless very small.

Success criteria:

- The first screen feels like a tavern dice table, not a debug UI.
- The UI does not directly calculate game outcomes.
- The match remains fully playable.
- Layout is readable at the configured viewport.

## M2.1: Integration Stabilization

Goal: Stabilize the merged M1 gameplay core and M2 tavern UI before adding progression systems.

Scope:

- Verify bust rolls such as `2-3-3-4-6-6` visibly pass the turn.
- Confirm AI turns start, select dice, bank, bust, and return control clearly.
- Confirm dice selection, banking, hot dice, and win detection still work through the tavern UI.
- Confirm layout readability at the configured viewport.
- Decide whether generated Godot `.uid` files should be committed or ignored.
- Add focused regression tests for any gameplay/UI integration bug found during manual verification.

Success criteria:

- The merged M1+M2 build plays cleanly in the Godot editor.
- The player can always tell whose turn it is and why control changed.
- No known scoring, bust, hot dice, or banking regressions remain.
- Generated Godot metadata policy is documented and the working tree can stay clean.

## M3: NPC, Coins, Dice, And Badges

Goal: Add the first progression layer.

Scope:

- Add player wallet and basic rewards.
- Add NPC opponent definitions.
- Add dice collection data.
- Add badge collection and equipment data.
- Add first simple badge effects.
- Add first simple special dice effects.
- Add reward multiplier support.

Success criteria:

- Player can win coins or reputation from matches.
- Opponents can differ by difficulty and reward profile.
- Loadout data exists and affects match setup.
- Special dice and badges are integrated through the gameplay core, not hardcoded into UI.

## M4: Local Multiplayer, Settings, And Save Data

Goal: Make the game feel like a durable local product.

Scope:

- Add local two-player mode.
- Add match setup screen.
- Add settings.
- Add save/load for progression.
- Add match history and statistics.
- Add basic profile persistence.

Success criteria:

- Player progress survives restart.
- Local two-player can use the same command interface.
- Settings and match setup are clear enough for repeated play.

## M5: Online Rooms And Synchronization

Goal: Add online match support without rewriting gameplay.

Scope:

- Add room creation or room code flow.
- Add network player type.
- Send commands over the network.
- Sync authoritative match state.
- Handle disconnects.
- Handle invalid or late commands.
- Add basic reconnect or forfeit behavior.

Success criteria:

- Online play uses the same command model as local play.
- The gameplay core remains independent from the transport layer.
- Network errors do not corrupt match state.

## M6: Content Polish And Release Preparation

Goal: Turn the game from a system prototype into a polished release candidate.

Scope:

- Dice roll animation.
- Table impact effects.
- Candle or ambient tavern effects.
- Sound effects.
- Music or ambience.
- Better victory/loss presentation.
- Additional NPCs, taverns, dice, badges, and table variants.
- Export builds.
- Release QA.

Success criteria:

- The game has a coherent tavern atmosphere.
- Content progression feels rewarding.
- Builds can be exported and tested outside the editor.

## Near-Term Priority

The next priority is M2.1 integration stabilization.

Before starting M3 progression systems, verify the merged gameplay core and tavern UI inside Godot:

- Confirm bust rolls such as `2-3-3-4-6-6` visibly pass the turn.
- Confirm AI turns start and finish clearly.
- Confirm dice selection, banking, hot dice, and win detection still work through the tavern UI.
- Confirm layout readability at the configured viewport.
- Decide whether generated Godot `.uid` files should be committed or ignored.

After M2.1 is stable, begin M3 with data-first progression: NPC definitions, wallet/reward data, dice inventory, badge inventory, and match reward calculation.

## Open Design Questions

These do not block M2.1, but should be answered before later milestones:

- Should the match core be deterministic with injectable random sources for networking and replay?
- Should special dice modify roll results, scoring rules, or both?
- Should badges be passive effects, triggered effects, or both?
- Should NPC opponents have fixed strategies, personality profiles, or unlockable rule variants?
- Should online matches be peer-authoritative, host-authoritative, or server-authoritative?
- Should coins and reputation be separate progression currencies from the beginning?
