# Gameplay Core Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the playable Farkle rules from `Main.gd` into a tested, UI-independent gameplay core.

**Architecture:** Create focused GDScript resources for scoring, match configuration, match state, commands, and AI policy. Keep the current UI playable by turning `Main.gd` into an adapter that sends commands to the core and renders the returned state. Tests run through Godot's `--headless --script` path so the gameplay core can be verified without opening the editor.

**Tech Stack:** Godot 4.7 GDScript, `RefCounted` gameplay classes, simple custom test runner scripts.

---

## File Structure

- Create `scripts/core/FarkleScorer.gd`: pure scoring helpers for selections, full roll bust checks, and best scoring indices.
- Create `scripts/core/MatchConfig.gd`: match setup values such as target score, player kinds, AI difficulty, and feature toggles.
- Create `scripts/core/FarkleMatch.gd`: UI-independent turn state and command methods for rolling, selecting dice, banking, and ending turns.
- Create `scripts/core/AiPolicy.gd`: AI keep/bank decisions based on state and difficulty.
- Modify `scripts/Main.gd`: use core classes instead of owning scoring and turn rules directly.
- Create `tests/core/*_test.gd`: focused tests for scorer, match flow, and AI policy.
- Create `tests/run_tests.gd`: CLI test runner that loads and runs the test scripts.

## Task 1: Test Harness And Scorer Extraction

- [ ] Write failing scorer tests for singles, sets, straights, three pairs, invalid leftovers, bust detection, and best scoring indices.
- [ ] Run `godot --headless --script tests/run_tests.gd --log-file /private/tmp/farkle-tests.log` and confirm the tests fail because the scorer does not exist.
- [ ] Implement `scripts/core/FarkleScorer.gd` by moving the scoring logic out of `Main.gd`.
- [ ] Run the scorer tests and confirm they pass.

## Task 2: Match Config And Command Core

- [ ] Write failing match tests for default config, initial state, roll command, selection command, bank command, bust turn pass, and hot dice.
- [ ] Run the test runner and confirm the tests fail because `FarkleMatch` and `MatchConfig` do not exist.
- [ ] Implement `MatchConfig.gd` and `FarkleMatch.gd` with deterministic dice injection for tests.
- [ ] Run all tests and confirm they pass.

## Task 3: AI Policy Extraction

- [ ] Write failing AI tests for Easy, Normal, Hard, winning-bank behavior, chase margin behavior, and dice-remaining adjustments.
- [ ] Run the test runner and confirm the tests fail because `AiPolicy` does not exist.
- [ ] Implement `AiPolicy.gd` using the existing thresholds from `Main.gd`.
- [ ] Run all tests and confirm they pass.

## Task 4: Main UI Adapter

- [ ] Refactor `Main.gd` to own `FarkleMatch`, `MatchConfig`, and `AiPolicy` instances.
- [ ] Replace direct scoring calls with match commands while preserving the existing visible UI and status messages.
- [ ] Remove duplicated scoring helpers from `Main.gd`.
- [ ] Run `godot --headless --check-only --script scripts/Main.gd --log-file /private/tmp/farkle-main-check.log`.
- [ ] Run all tests and confirm they pass.

## Task 5: Documentation And Final Verification

- [ ] Update `README.md` with the new core/test structure.
- [ ] Run the full test runner.
- [ ] Run `git status -sb` and review the diff.
- [ ] Commit the branch with `Refactor gameplay core with tests`.
