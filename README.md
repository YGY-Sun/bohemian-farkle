# Bohemian Farkle

A Godot 4 prototype inspired by the tavern dice game in *Kingdom Come: Deliverance 2*.

## Current Rules

- Single player mode: Player 1 races an AI opponent to 4000 points.
- The AI opponent supports Easy, Normal, and Hard difficulty.
- Roll up to six dice.
- Select at least one scoring die or scoring set after each roll.
- Bank to keep the current turn score.
- Roll again to risk the current turn score for more points.
- If a roll has no scoring dice, the turn busts and the player scores 0 for that turn.
- If all dice score, the player gets hot dice and rolls all six again.

## Scoring

| Roll | Points |
| --- | ---: |
| Single 1 | 100 |
| Single 5 | 50 |
| Three 1s | 1000 |
| Three 2s-6s | Face x 100 |
| Four/five/six of a kind | Doubles per extra die |
| Straight 1-6 | 1500 |
| Straight 1-5 | 500 |
| Straight 2-6 | 750 |
| Three pairs | 1500 |

## Run

Open this folder in Godot 4 and press Run.

## Core Architecture

The playable prototype now keeps game rules outside the UI:

- `scripts/core/FarkleScorer.gd` scores dice selections and detects busts.
- `scripts/core/MatchConfig.gd` describes match setup, including target score, player types, AI difficulty, feature toggles, and reward multiplier.
- `scripts/core/FarkleMatch.gd` owns turn state and command-style actions such as rolling, selecting dice, and banking.
- `scripts/core/AiPolicy.gd` owns AI banking decisions.
- `scripts/Main.gd` is a Godot UI adapter that renders state and sends commands into the gameplay core.

## Tests

Run the core test suite with:

```sh
godot --headless --script tests/run_tests.gd --log-file /private/tmp/farkle-tests.log
```

## Modes

- Single Player: implemented. Player 1 is controlled by the local player, Player 2 is a background AI.
- Local Two Player: planned.
- Online Two Player: planned. The current turn/controller split is intended to support a future network controller for Player 2.

## Git

This folder is initialized as a Git repository. Suggested first snapshot:

```sh
git status
git add .
git commit -m "Create Godot Farkle prototype"
```

## Next Features

- Special weighted dice.
- Badge/perk effects.
- Local two-player mode.
- Online two-player matchmaking or room codes.
- Tavern table art and dice animations.
- Rule variants matching specific table types.
