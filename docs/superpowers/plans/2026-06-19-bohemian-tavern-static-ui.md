# Bohemian Tavern Static UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current plain Godot prototype UI with a playable static Bohemian tavern tabletop interface.

**Architecture:** Keep the existing game logic in `scripts/Main.gd` and replace only UI construction, styling, and refresh presentation. Use procedural Godot `Control` nodes, `StyleBoxFlat`, labels, buttons, and lightweight custom drawing helpers so this phase has no external art dependency.

**Tech Stack:** Godot 4 GDScript, dynamically constructed `Control` UI, existing `scenes/Main.tscn`.

---

## File Structure

- Modify `scripts/Main.gd`: add UI theme constants, helper methods, parchment panels, tabletop background, physical dice buttons, prop decorations, and refreshed score/status rendering.
- No new runtime assets are required in this phase.
- Use `docs/superpowers/specs/2026-06-19-bohemian-tavern-static-ui-design.md` as the source of truth for scope.

## Task 1: Add Tavern Theme Helpers

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add color and sizing constants near existing constants**

Add constants after `const AI_PLAYER := 1`:

```gdscript
const TABLE_DARK := Color("#1f120b")
const TABLE_MID := Color("#4b2a16")
const TABLE_LIGHT := Color("#7a4724")
const PARCHMENT := Color("#d5b478")
const PARCHMENT_DARK := Color("#8f6335")
const INK := Color("#24170f")
const CANDLE := Color("#f0b65a")
const BRASS := Color("#b78238")
const BONE := Color("#e8ddc6")
const BONE_SELECTED := Color("#f6df9a")
const DISABLED_TINT := Color("#8d8070")
const PANEL_RADIUS := 8
const DICE_SIZE := 86
```

- [ ] **Step 2: Add style helper methods below `_build_ui()`**

Add these helper methods:

```gdscript
func _make_style(fill: Color, border: Color, border_width := 0, radius := PANEL_RADIUS) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(2, 3)
	return style


func _style_button(button: Button, fill: Color, border: Color, font_size := 20) -> void:
	button.add_theme_stylebox_override("normal", _make_style(fill, border, 2, 6))
	button.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.08), CANDLE, 2, 6))
	button.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.12), border, 2, 6))
	button.add_theme_stylebox_override("disabled", _make_style(fill.darkened(0.25), DISABLED_TINT, 2, 6))
	button.add_theme_color_override("font_color", Color("#f7ead0"))
	button.add_theme_color_override("font_disabled_color", Color("#b8aa92"))
	button.add_theme_font_size_override("font_size", font_size)
```

- [ ] **Step 3: Run the project script parser if Godot CLI exists**

Run: `godot --headless --path . --quit`

Expected: the command exits without GDScript parse errors. If `godot` is not installed in PATH, record that manual Godot editor verification is required.

## Task 2: Rebuild The Static Tavern Layout

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Replace `_build_ui()` with layered tavern layout**

Replace the current `_build_ui()` body with:

```gdscript
func _build_ui() -> void:
	var table := ColorRect.new()
	table.name = "TavernTable"
	table.color = TABLE_MID
	table.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(table)

	var vignette := ColorRect.new()
	vignette.name = "TableVignette"
	vignette.color = Color(0, 0, 0, 0.18)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 32)
	safe.add_theme_constant_override("margin_top", 24)
	safe.add_theme_constant_override("margin_right", 32)
	safe.add_theme_constant_override("margin_bottom", 28)
	add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)

	root.add_child(_build_header())

	var table_row := HBoxContainer.new()
	table_row.add_theme_constant_override("separation", 24)
	table_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(table_row)

	table_row.add_child(_build_score_panel())
	table_row.add_child(_build_dice_table())
	table_row.add_child(_build_rules_panel())

	root.add_child(_build_action_row())
```

- [ ] **Step 2: Add `_build_header()`**

Add:

```gdscript
func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	title_label = Label.new()
	title_label.text = "Bohemian Farkle"
	title_label.add_theme_color_override("font_color", Color("#f6d89a"))
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	difficulty_option = OptionButton.new()
	difficulty_option.add_item("Easy AI", AiDifficulty.EASY)
	difficulty_option.add_item("Normal AI", AiDifficulty.NORMAL)
	difficulty_option.add_item("Hard AI", AiDifficulty.HARD)
	difficulty_option.selected = AiDifficulty.NORMAL
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	_style_button(difficulty_option, TABLE_DARK, BRASS, 16)
	header.add_child(difficulty_option)

	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(_new_game)
	_style_button(new_game_button, TABLE_DARK, BRASS, 16)
	header.add_child(new_game_button)

	return header
```

- [ ] **Step 3: Add `_build_score_panel()` and `_build_rules_panel()`**

Add:

```gdscript
func _build_score_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(270, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_style(PARCHMENT, PARCHMENT_DARK, 3, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	mode_label = Label.new()
	mode_label.text = "Single Player"
	mode_label.add_theme_color_override("font_color", INK)
	mode_label.add_theme_font_size_override("font_size", 18)
	content.add_child(mode_label)

	score_label = Label.new()
	score_label.add_theme_color_override("font_color", INK)
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(score_label)

	turn_label = Label.new()
	turn_label.add_theme_color_override("font_color", Color("#5a2812"))
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(turn_label)

	return panel


func _build_rules_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_style(PARCHMENT, PARCHMENT_DARK, 3, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	rule_label = RichTextLabel.new()
	rule_label.bbcode_enabled = true
	rule_label.fit_content = false
	rule_label.scroll_active = false
	rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rule_label.add_theme_color_override("default_color", INK)
	rule_label.text = "[b]Scoring[/b]\n1 = 100    5 = 50\nThree 1s = 1000\nThree 2-6 = face x 100\nFour+ of a kind doubles\n1-6 straight = 1500\n1-5 straight = 500\n2-6 straight = 750\nThree pairs = 1500"
	margin.add_child(rule_label)

	return panel
```

- [ ] **Step 4: Add `_build_dice_table()` and `_build_action_row()`**

Add:

```gdscript
func _build_dice_table() -> Control:
	var area := VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_theme_constant_override("separation", 18)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("#f3dfb0"))
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.custom_minimum_size = Vector2(360, 52)
	area.add_child(status_label)

	dice_box = HBoxContainer.new()
	dice_box.add_theme_constant_override("separation", 14)
	dice_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	area.add_child(dice_box)

	var props := Label.new()
	props.text = "Candle   Cup   Coin Pouch"
	props.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	props.add_theme_color_override("font_color", Color("#b98f5a"))
	props.add_theme_font_size_override("font_size", 14)
	area.add_child(props)

	return area


func _build_action_row() -> Control:
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)

	roll_button = Button.new()
	roll_button.text = "Roll"
	roll_button.custom_minimum_size = Vector2(160, 50)
	roll_button.pressed.connect(_on_roll_pressed)
	_style_button(roll_button, Color("#6e3517"), BRASS, 22)
	actions.add_child(roll_button)

	bank_button = Button.new()
	bank_button.text = "Bank"
	bank_button.custom_minimum_size = Vector2(160, 50)
	bank_button.pressed.connect(_on_bank_pressed)
	_style_button(bank_button, Color("#4d2a15"), BRASS, 22)
	actions.add_child(bank_button)

	return actions
```

- [ ] **Step 5: Run parse verification**

Run: `godot --headless --path . --quit`

Expected: no parse errors, or record that PATH lacks Godot.

## Task 3: Style Dice As Physical Table Dice

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add dice style helper below `_style_button()`**

Add:

```gdscript
func _style_die(button: Button, selected: bool, disabled: bool) -> void:
	var fill := BONE_SELECTED if selected else BONE
	var border := CANDLE if selected else Color("#5d4630")
	if disabled:
		fill = fill.darkened(0.18)
		border = DISABLED_TINT
	button.add_theme_stylebox_override("normal", _make_style(fill, border, 3, 10))
	button.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.05), CANDLE, 3, 10))
	button.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.08), border, 3, 10))
	button.add_theme_stylebox_override("disabled", _make_style(fill.darkened(0.2), border, 3, 10))
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#5e5144"))
	button.add_theme_font_size_override("font_size", 34)


func _die_face_text(value: int) -> String:
	match value:
		1:
			return "•"
		2:
			return "•  •"
		3:
			return "•\n•\n•"
		4:
			return "• •\n• •"
		5:
			return "• •\n • \n• •"
		6:
			return "• •\n• •\n• •"
	return str(value)
```

- [ ] **Step 2: Update dice creation in `_refresh_ui()`**

Replace the dice button loop with:

```gdscript
	for i in dice_values.size():
		var button := Button.new()
		var selected := held_indices.has(i)
		var disabled := not _is_human_turn()
		button.text = _die_face_text(dice_values[i])
		button.custom_minimum_size = Vector2(DICE_SIZE, DICE_SIZE)
		_style_die(button, selected, disabled)
		button.disabled = disabled
		button.pressed.connect(_toggle_die.bind(i))
		dice_box.add_child(button)
```

- [ ] **Step 3: Manually verify dice states**

Run the scene in Godot. Roll dice, click scoring dice, click non-scoring dice, and wait for an AI turn.

Expected:
- Dice are square and tactile.
- Selected dice are visibly highlighted.
- AI dice are visible but disabled.
- Existing status messages still update.

## Task 4: Format Score And Status Text For Parchment

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Replace score and turn label formatting in `_refresh_ui()`**

Replace:

```gdscript
	score_label.text = "Player 1: %d / %d      AI (%s): %d / %d" % [banked_scores[0], TARGET_SCORE, _ai_difficulty_name(), banked_scores[1], TARGET_SCORE]
	turn_label.text = "%s turn score: %d" % [_player_name(current_player), turn_score]
```

with:

```gdscript
	var player_mark := ">" if current_player == HUMAN_PLAYER else " "
	var ai_mark := ">" if current_player == AI_PLAYER else " "
	score_label.text = "%s Player 1\n  %d / %d\n\n%s AI (%s)\n  %d / %d" % [player_mark, banked_scores[0], TARGET_SCORE, ai_mark, _ai_difficulty_name(), banked_scores[1], TARGET_SCORE]
	turn_label.text = "Current turn\n%s\n\nTurn stake: %d" % [_player_name(current_player), turn_score]
```

- [ ] **Step 2: Keep mode label compact**

In `_refresh_ui()`, add before button disabled state updates:

```gdscript
	mode_label.text = "Race to %d" % TARGET_SCORE
```

- [ ] **Step 3: Verify no layout shifts**

Run the scene. Roll, select dice, bank, and let the AI act.

Expected:
- Score parchment stays fixed width.
- Status text does not push dice off center.
- Current player mark changes when turns change.

## Task 5: Final Verification And Commit

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Check git diff**

Run: `git diff -- scripts/Main.gd`

Expected: diff only changes UI construction, style helpers, dice rendering, and label formatting. Scoring and AI decision logic remain unchanged.

- [ ] **Step 2: Run available verification**

Run: `godot --headless --path . --quit`

Expected: no parse errors. If Godot CLI is unavailable, open `/Users/ygy/Downloads/vibe_game_dev/farkle/project.godot` in Godot 4 and run the main scene manually.

- [ ] **Step 3: Manual playtest checklist**

Verify:
- New game starts with the tavern tabletop UI visible.
- Roll button rolls dice.
- Dice selection works.
- Invalid selection still shows feedback.
- Bank adds points and advances turn.
- AI turn disables human controls.
- Difficulty option changes the AI label.
- Rules parchment is readable.
- No text overlaps at 1280x720.

- [ ] **Step 4: Commit only intentional files**

Run:

```bash
git add scripts/Main.gd
git commit -m "Add static tavern tabletop UI"
```

Expected: commit includes only `scripts/Main.gd` unless Godot legitimately updates scene metadata during verification.

## Self-Review

- Spec coverage: the plan covers the static tabletop composition, parchment score and rule panels, physical dice styling, action controls, status display, and manual verification. Deferred animation, audio, effects, and high-resolution assets remain out of scope.
- Placeholder scan: no TBD, TODO, or unspecified implementation steps remain.
- Type consistency: all helper names used later in the plan are defined earlier: `_make_style`, `_style_button`, `_style_die`, and `_die_face_text`.
