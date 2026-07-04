extends Control

enum GameMode { SINGLE_PLAYER, LOCAL_TWO_PLAYER, ONLINE_TWO_PLAYER }

const MatchConfig := preload("res://scripts/core/MatchConfig.gd")
const FarkleMatch := preload("res://scripts/core/FarkleMatch.gd")
const AiPolicy := preload("res://scripts/core/AiPolicy.gd")

const TARGET_SCORE := 4000
const PLAYER_COUNT := 2
const HUMAN_PLAYER := 0
const AI_PLAYER := 1
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
const DICE_SIZE := 110
const DICE_AREA_SIZE := Vector2(470, 390)
const DICE_SELECTION_RING_SIZE := 96
const SIDE_PARCHMENT_SIZE := Vector2(236, 412)

class DiceSelectionRing:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE


	func _draw() -> void:
		var center := size * 0.5
		var radius: float = min(size.x, size.y) * 0.43
		draw_arc(center, radius, 0.0, TAU, 72, Color("#ffd34f", 0.95), 4.0)
		draw_arc(center, radius + 2.0, PI * 0.08, PI * 1.15, 72, Color("#ff7b2d", 0.9), 3.0)

var game_mode := GameMode.SINGLE_PLAYER
var ai_difficulty := MatchConfig.AiDifficulty.NORMAL
var rng := RandomNumberGenerator.new()
var current_player := 0
var banked_scores := [0, 0]
var turn_score := 0
var dice_values: Array[int] = []
var dice_poses: Array[Dictionary] = []
var held_indices: Array[int] = []
var can_bank := false
var game_over := false
var ai_turn_running := false
var match_config
var game
var ai_policy := AiPolicy.new()

var mode_label: Label
var status_label: Label
var score_label: RichTextLabel
var turn_label: Label
var dice_box: Control
var roll_button: Button
var bank_button: Button
var new_game_button: Button
var difficulty_option: OptionButton
var rule_label: RichTextLabel


func _ready() -> void:
	rng.randomize()
	_build_ui()
	_new_game()


func _build_ui() -> void:
	add_child(_build_table_background())

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

	root.add_child(_build_table_layer())

	root.add_child(_build_action_row())


func _build_table_background() -> Control:
	var background := TextureRect.new()
	background.name = "TavernTable"
	background.texture = preload("res://assets/art/ui/tavern/backgrounds/bg_tavern_table_final.png")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return background


func _build_table_layer() -> Control:
	var table_layer := Control.new()
	table_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_layer.clip_contents = false

	var score_panel := _build_score_panel()
	_place_side_parchment(score_panel, true)
	table_layer.add_child(score_panel)

	var dice_table := _build_dice_table()
	_place_center_table(dice_table)
	table_layer.add_child(dice_table)

	var rules_panel := _build_rules_panel()
	_place_side_parchment(rules_panel, false)
	table_layer.add_child(rules_panel)

	return table_layer


func _place_side_parchment(panel: Control, left_side: bool) -> void:
	panel.size = SIDE_PARCHMENT_SIZE
	panel.custom_minimum_size = SIDE_PARCHMENT_SIZE
	panel.pivot_offset = SIDE_PARCHMENT_SIZE * 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_top = -SIDE_PARCHMENT_SIZE.y * 0.5
	panel.offset_bottom = SIDE_PARCHMENT_SIZE.y * 0.5

	if left_side:
		panel.anchor_left = 0.0
		panel.anchor_right = 0.0
		panel.offset_left = -34.0
		panel.offset_right = SIDE_PARCHMENT_SIZE.x - 34.0
	else:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
		panel.offset_left = -SIDE_PARCHMENT_SIZE.x + 34.0
		panel.offset_right = 34.0


func _place_center_table(table: Control) -> void:
	table.anchor_left = 0.5
	table.anchor_right = 0.5
	table.anchor_top = 0.5
	table.anchor_bottom = 0.5
	table.offset_left = -DICE_AREA_SIZE.x * 0.5
	table.offset_right = DICE_AREA_SIZE.x * 0.5
	table.offset_top = -DICE_AREA_SIZE.y * 0.5
	table.offset_bottom = DICE_AREA_SIZE.y * 0.5


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	difficulty_option = OptionButton.new()
	difficulty_option.add_item("Easy AI", MatchConfig.AiDifficulty.EASY)
	difficulty_option.add_item("Normal AI", MatchConfig.AiDifficulty.NORMAL)
	difficulty_option.add_item("Hard AI", MatchConfig.AiDifficulty.HARD)
	difficulty_option.selected = MatchConfig.AiDifficulty.NORMAL
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	_style_button(difficulty_option, TABLE_DARK, BRASS, 16)
	header.add_child(difficulty_option)

	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(_new_game)
	_style_button(new_game_button, TABLE_DARK, BRASS, 16)
	header.add_child(new_game_button)

	return header


func _build_score_panel() -> Control:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(260, 430)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	panel.rotation_degrees = -4.0

	var parchment := TextureRect.new()
	parchment.texture = preload("res://assets/art/ui/tavern/parchment/panel_score_parchment.png")
	parchment.set_anchors_preset(Control.PRESET_FULL_RECT)
	parchment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parchment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(parchment)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	mode_label = Label.new()
	mode_label.text = "Tavern Ledger"
	mode_label.add_theme_color_override("font_color", Color("#44200d"))
	mode_label.add_theme_color_override("font_shadow_color", Color("#bb7d35", 0.22))
	mode_label.add_theme_constant_override("shadow_offset_x", 1)
	mode_label.add_theme_constant_override("shadow_offset_y", 1)
	mode_label.add_theme_font_size_override("font_size", 19)
	content.add_child(mode_label)

	score_label = RichTextLabel.new()
	score_label.bbcode_enabled = true
	score_label.fit_content = false
	score_label.scroll_active = false
	score_label.custom_minimum_size = Vector2(178, 150)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_color_override("default_color", Color("#281408"))
	score_label.add_theme_font_size_override("normal_font_size", 20)
	content.add_child(score_label)

	turn_label = Label.new()
	turn_label.add_theme_color_override("font_color", Color("#3f1d0b"))
	turn_label.add_theme_color_override("font_shadow_color", Color("#bd843f", 0.18))
	turn_label.add_theme_constant_override("shadow_offset_x", 1)
	turn_label.add_theme_constant_override("shadow_offset_y", 1)
	turn_label.add_theme_font_size_override("font_size", 17)
	turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(turn_label)

	return panel


func _build_rules_panel() -> Control:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(270, 410)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	panel.rotation_degrees = 3.0

	var parchment := TextureRect.new()
	parchment.texture = preload("res://assets/art/ui/tavern/parchment/panel_rules_parchment.png")
	parchment.set_anchors_preset(Control.PRESET_FULL_RECT)
	parchment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parchment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(parchment)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 28)
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


func _build_dice_table() -> Control:
	var table_space := VBoxContainer.new()
	table_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_space.alignment = BoxContainer.ALIGNMENT_CENTER

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("#f7ead0"))
	status_label.add_theme_color_override("font_shadow_color", Color("#2b1206", 0.85))
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.custom_minimum_size = Vector2(DICE_AREA_SIZE.x, 52)
	table_space.add_child(status_label)

	dice_box = Control.new()
	dice_box.custom_minimum_size = DICE_AREA_SIZE
	dice_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dice_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	table_space.add_child(dice_box)

	return table_space


func _build_action_row() -> Control:
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)

	roll_button = Button.new()
	roll_button.text = "Roll"
	roll_button.custom_minimum_size = Vector2(170, 54)
	roll_button.pressed.connect(_on_roll_pressed)
	_style_button(roll_button, Color("#6e3517"), BRASS, 22)
	actions.add_child(roll_button)

	bank_button = Button.new()
	bank_button.text = "Bank"
	bank_button.custom_minimum_size = Vector2(170, 54)
	bank_button.pressed.connect(_on_bank_pressed)
	_style_button(bank_button, Color("#4d2a15"), BRASS, 22)
	actions.add_child(bank_button)

	return actions


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


func _make_parchment_style() -> StyleBoxFlat:
	var style := _make_style(Color("#d8b978"), Color("#5f351c"), 3, 5)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 14
	style.shadow_offset = Vector2(5, 7)
	style.content_margin_left = 16
	style.content_margin_top = 16
	style.content_margin_right = 16
	style.content_margin_bottom = 16
	return style


func _make_table_mat_style() -> StyleBoxFlat:
	var style := _make_style(Color("#271005", 0.72), Color("#8b5529", 0.85), 2, 8)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _make_die_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.0)
	style.border_color = Color.TRANSPARENT
	style.shadow_size = 0
	return style


func _style_button(button: Button, fill: Color, border: Color, font_size := 20) -> void:
	button.add_theme_stylebox_override("normal", _make_style(fill, border, 2, 6))
	button.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.08), CANDLE, 2, 6))
	button.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.12), border, 2, 6))
	button.add_theme_stylebox_override("disabled", _make_style(fill.darkened(0.25), DISABLED_TINT, 2, 6))
	button.add_theme_color_override("font_color", Color("#f7ead0"))
	button.add_theme_color_override("font_disabled_color", Color("#b8aa92"))
	button.add_theme_font_size_override("font_size", font_size)


func _style_die(button: Button, selected: bool, disabled: bool) -> void:
	var clear_style := _make_die_button_style()
	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", clear_style)
	button.add_theme_stylebox_override("pressed", clear_style)
	button.add_theme_stylebox_override("disabled", clear_style)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("#5e5144"))


func _die_texture(value: int) -> Texture2D:
	return load("res://assets/art/ui/tavern/dice/die_%d.png" % value)


func _add_die_texture(button: Button, value: int, selected: bool, disabled: bool) -> void:
	var image := TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture = _die_texture(value)
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.modulate = Color(1.0, 0.92, 0.78, 1.0) if selected else Color.WHITE
	if disabled:
		image.modulate = Color(0.55, 0.52, 0.48, 0.72)
	button.add_child(image)


func _add_die_selection_ring(center: Vector2) -> void:
	var ring := DiceSelectionRing.new()
	ring.size = Vector2(DICE_SELECTION_RING_SIZE, DICE_SELECTION_RING_SIZE)
	ring.position = center - ring.size * 0.5
	dice_box.add_child(ring)


func _randomize_dice_poses(count: int) -> void:
	dice_poses.clear()
	var placed: Array[Vector2] = []
	var min_distance := DICE_SIZE * 0.72
	var margin := DICE_SIZE * 0.16
	var max_position := DICE_AREA_SIZE - Vector2(DICE_SIZE, DICE_SIZE) - Vector2(margin, margin)

	for i in range(count):
		var position := Vector2.ZERO
		var accepted := false
		for attempt in range(36):
			position = Vector2(
				rng.randf_range(margin, max_position.x),
				rng.randf_range(margin, max_position.y)
			)
			accepted = true
			for other in placed:
				if position.distance_to(other) < min_distance:
					accepted = false
					break
			if accepted:
				break

		placed.append(position)
		dice_poses.append({
			"position": position,
			"rotation": deg_to_rad(rng.randf_range(-20.0, 20.0))
		})


func _new_game() -> void:
	match_config = MatchConfig.new()
	match_config.target_score = TARGET_SCORE
	match_config.ai_difficulty = ai_difficulty
	game = FarkleMatch.new(match_config)
	dice_poses.clear()
	ai_turn_running = false
	_sync_from_game()
	status_label.text = game.status
	_refresh_ui()


func _on_difficulty_selected(index: int) -> void:
	ai_difficulty = difficulty_option.get_item_id(index)
	if match_config != null:
		match_config.ai_difficulty = ai_difficulty
	if game != null:
		game.config.ai_difficulty = ai_difficulty
	status_label.text = "AI difficulty set to %s." % _ai_difficulty_name()
	_refresh_ui()


func _on_roll_pressed() -> void:
	if not _is_human_turn():
		return

	var previous_player := current_player
	game.roll_requested()
	_sync_from_game()
	status_label.text = game.status
	_refresh_ui()

	if previous_player != current_player and _is_ai_turn():
		_run_ai_turn()


func _on_bank_pressed() -> void:
	if not _is_human_turn():
		return

	game.bank_requested()
	_sync_from_game()
	status_label.text = game.status
	_refresh_ui()

	if _is_ai_turn():
		_run_ai_turn()


func _run_ai_turn() -> void:
	if ai_turn_running:
		return

	ai_turn_running = true
	_run_ai_turn_async()


func _run_ai_turn_async() -> void:
	await get_tree().create_timer(0.6).timeout

	while _is_ai_turn() and not game_over:
		if dice_values.is_empty():
			game.roll_requested()
			_sync_from_game()
			status_label.text = "AI rolled: %s." % _dice_text(dice_values) if _is_ai_turn() else game.status
			_refresh_ui()

		if not _is_ai_turn() or game_over or not can_bank:
			break

		await get_tree().create_timer(0.6).timeout

		var best_indices: Array[int] = game.scorer.best_scoring_indices(dice_values)
		game.dice_selected(best_indices)
		_sync_from_game()
		var selected_score: int = game.selection_score()
		var selected_values: Array[int] = game.selected_dice_values()
		status_label.text = "AI keeps %s for %d points." % [_dice_text(selected_values), selected_score]
		_refresh_ui()

		await get_tree().create_timer(0.6).timeout

		var dice_remaining := dice_values.size() - held_indices.size()
		var projected_turn_score: int = turn_score + selected_score
		var should_bank := ai_policy.should_bank(ai_difficulty, banked_scores, projected_turn_score, dice_remaining, TARGET_SCORE)

		if should_bank:
			game.bank_requested()
			_sync_from_game()
			status_label.text = game.status
			_refresh_ui()
			break

		game.roll_requested()
		_sync_from_game()
		status_label.text = game.status
		_refresh_ui()
		await get_tree().create_timer(0.4).timeout

	ai_turn_running = false
	_refresh_ui()


func _toggle_die(index: int) -> void:
	if not _is_human_turn():
		return

	var next_indices := held_indices.duplicate()
	if next_indices.has(index):
		next_indices.erase(index)
	else:
		next_indices.append(index)

	game.dice_selected(next_indices)
	_sync_from_game()
	status_label.text = game.status
	_refresh_ui()


func _sync_from_game() -> void:
	var previous_dice_values := dice_values.duplicate()
	current_player = game.current_player
	banked_scores = game.banked_scores.duplicate()
	turn_score = game.turn_score
	dice_values = game.dice_values.duplicate()
	if dice_values != previous_dice_values:
		dice_poses.clear()
	held_indices = game.held_indices.duplicate()
	can_bank = game.can_bank
	game_over = game.game_over


func _refresh_ui() -> void:
	var player_mark := ">" if current_player == HUMAN_PLAYER else " "
	var ai_mark := ">" if current_player == AI_PLAYER else " "
	mode_label.text = "Race to %d" % TARGET_SCORE
	score_label.text = (
		"[font_size=16][color=#48220d][i]%s Player 1[/i][/color][/font_size]\n"
		+ "[font_size=22][color=#211006]%d / %d[/color][/font_size]\n\n"
		+ "[font_size=16][color=#48220d][i]%s AI (%s)[/i][/color][/font_size]\n"
		+ "[font_size=22][color=#211006]%d / %d[/color][/font_size]"
	) % [player_mark, banked_scores[0], TARGET_SCORE, ai_mark, _ai_difficulty_name(), banked_scores[1], TARGET_SCORE]
	turn_label.text = "Current hand\n%s\n\nStake: %d" % [_player_name(current_player), turn_score]
	difficulty_option.disabled = ai_turn_running
	roll_button.disabled = game_over or not _is_human_turn()
	bank_button.disabled = game_over or not _is_human_turn() or not can_bank

	for child in dice_box.get_children():
		child.queue_free()

	if dice_values.size() > 0 and dice_poses.size() != dice_values.size():
		_randomize_dice_poses(dice_values.size())

	for i in dice_values.size():
		var selected := held_indices.has(i)
		var disabled := not _is_human_turn()
		if selected and not disabled:
			_add_die_selection_ring(dice_poses[i]["position"] + Vector2(DICE_SIZE, DICE_SIZE) * 0.5)

	for i in dice_values.size():
		var button := Button.new()
		var selected := held_indices.has(i)
		var disabled := not _is_human_turn()
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(DICE_SIZE, DICE_SIZE)
		button.size = Vector2(DICE_SIZE, DICE_SIZE)
		button.pivot_offset = Vector2(DICE_SIZE, DICE_SIZE) * 0.5
		button.position = dice_poses[i]["position"]
		button.rotation = dice_poses[i]["rotation"]
		_style_die(button, selected, disabled)
		_add_die_texture(button, dice_values[i], selected, disabled)
		button.disabled = disabled
		button.pressed.connect(_toggle_die.bind(i))
		dice_box.add_child(button)


func _is_human_turn() -> bool:
	if game_mode == GameMode.SINGLE_PLAYER:
		return current_player == HUMAN_PLAYER and not ai_turn_running
	return game_mode == GameMode.LOCAL_TWO_PLAYER


func _is_ai_turn() -> bool:
	return game_mode == GameMode.SINGLE_PLAYER and current_player == AI_PLAYER


func _player_name(player_index: int) -> String:
	if player_index == HUMAN_PLAYER:
		return "Player 1"
	if game_mode == GameMode.SINGLE_PLAYER:
		return "AI"
	return "Player 2"


func _ai_difficulty_name() -> String:
	match ai_difficulty:
		MatchConfig.AiDifficulty.EASY:
			return "Easy"
		MatchConfig.AiDifficulty.NORMAL:
			return "Normal"
		MatchConfig.AiDifficulty.HARD:
			return "Hard"
	return "Normal"


func _dice_text(values: Array[int]) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return "-".join(parts)
