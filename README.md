# Bohemian Farkle

A Godot 4 prototype inspired by the tavern dice game in *Kingdom Come: Deliverance 2*.

## Current Rules

- Two players race to 4000 points.
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
- AI opponent.
- Tavern table art and dice animations.
- Rule variants matching specific table types.
