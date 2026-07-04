extends Control

enum GameMode { SINGLE_PLAYER, LOCAL_TWO_PLAYER, ONLINE_TWO_PLAYER }

const MatchConfig := preload("res://scripts/core/MatchConfig.gd")
const FarkleMatch := preload("res://scripts/core/FarkleMatch.gd")
const AiPolicy := preload("res://scripts/core/AiPolicy.gd")

const TARGET_SCORE := 4000
const PLAYER_COUNT := 2
const HUMAN_PLAYER := 0
const AI_PLAYER := 1

var game_mode := GameMode.SINGLE_PLAYER
var ai_difficulty := MatchConfig.AiDifficulty.NORMAL
var current_player := 0
var banked_scores := [0, 0]
var turn_score := 0
var dice_values: Array[int] = []
var held_indices: Array[int] = []
var can_bank := false
var game_over := false
var ai_turn_running := false
var match_config
var game
var ai_policy := AiPolicy.new()

var title_label: Label
var mode_label: Label
var status_label: Label
var score_label: Label
var turn_label: Label
var dice_box: HBoxContainer
var roll_button: Button
var bank_button: Button
var new_game_button: Button
var difficulty_option: OptionButton
var rule_label: RichTextLabel


func _ready() -> void:
	_build_ui()
	_new_game()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("margin_left", 36)
	add_child(root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	title_label = Label.new()
	title_label.text = "Bohemian Farkle"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	difficulty_option = OptionButton.new()
	difficulty_option.add_item("Easy AI", MatchConfig.AiDifficulty.EASY)
	difficulty_option.add_item("Normal AI", MatchConfig.AiDifficulty.NORMAL)
	difficulty_option.add_item("Hard AI", MatchConfig.AiDifficulty.HARD)
	difficulty_option.selected = MatchConfig.AiDifficulty.NORMAL
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	header.add_child(difficulty_option)

	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(_new_game)
	header.add_child(new_game_button)

	mode_label = Label.new()
	mode_label.text = "Mode: Single Player - Player 1 vs AI"
	mode_label.add_theme_font_size_override("font_size", 18)
	root.add_child(mode_label)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 22)
	root.add_child(score_label)

	turn_label = Label.new()
	turn_label.add_theme_font_size_override("font_size", 20)
	root.add_child(turn_label)

	dice_box = HBoxContainer.new()
	dice_box.add_theme_constant_override("separation", 12)
	dice_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(dice_box)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(actions)

	roll_button = Button.new()
	roll_button.text = "Roll"
	roll_button.custom_minimum_size = Vector2(150, 48)
	roll_button.pressed.connect(_on_roll_pressed)
	actions.add_child(roll_button)

	bank_button = Button.new()
	bank_button.text = "Bank"
	bank_button.custom_minimum_size = Vector2(150, 48)
	bank_button.pressed.connect(_on_bank_pressed)
	actions.add_child(bank_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	root.add_child(status_label)

	rule_label = RichTextLabel.new()
	rule_label.bbcode_enabled = true
	rule_label.fit_content = true
	rule_label.scroll_active = false
	rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_label.text = "[b]Scoring[/b]\n1 = 100, 5 = 50. Three of a kind scores face x 100, except 1-1-1 = 1000. Four/five/six of a kind double each extra die. Straight 1-6 = 1500, straight 1-5 = 500, straight 2-6 = 750, three pairs = 1500. Select scoring dice, then bank or risk another roll."
	root.add_child(rule_label)


func _new_game() -> void:
	match_config = MatchConfig.new()
	match_config.target_score = TARGET_SCORE
	match_config.ai_difficulty = ai_difficulty
	game = FarkleMatch.new(match_config)
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
	current_player = game.current_player
	banked_scores = game.banked_scores.duplicate()
	turn_score = game.turn_score
	dice_values = game.dice_values.duplicate()
	held_indices = game.held_indices.duplicate()
	can_bank = game.can_bank
	game_over = game.game_over


func _refresh_ui() -> void:
	score_label.text = "Player 1: %d / %d      AI (%s): %d / %d" % [banked_scores[0], TARGET_SCORE, _ai_difficulty_name(), banked_scores[1], TARGET_SCORE]
	turn_label.text = "%s turn score: %d" % [_player_name(current_player), turn_score]
	difficulty_option.disabled = ai_turn_running
	roll_button.disabled = game_over or not _is_human_turn()
	bank_button.disabled = game_over or not _is_human_turn() or not can_bank

	for child in dice_box.get_children():
		child.queue_free()

	for i in dice_values.size():
		var button := Button.new()
		button.text = str(dice_values[i])
		button.custom_minimum_size = Vector2(86, 86)
		button.add_theme_font_size_override("font_size", 34)
		if held_indices.has(i):
			button.modulate = Color(0.75, 1.0, 0.72)
		button.disabled = not _is_human_turn()
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
