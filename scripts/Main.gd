extends Control

enum GameMode { SINGLE_PLAYER, LOCAL_TWO_PLAYER, ONLINE_TWO_PLAYER }
enum AiDifficulty { EASY, NORMAL, HARD }

const TARGET_SCORE := 4000
const PLAYER_COUNT := 2
const HUMAN_PLAYER := 0
const AI_PLAYER := 1

var rng := RandomNumberGenerator.new()
var game_mode := GameMode.SINGLE_PLAYER
var ai_difficulty := AiDifficulty.NORMAL
var current_player := 0
var banked_scores := [0, 0]
var turn_score := 0
var dice_values: Array[int] = []
var held_indices: Array[int] = []
var can_bank := false
var game_over := false
var ai_turn_running := false

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
	rng.randomize()
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
	difficulty_option.add_item("Easy AI", AiDifficulty.EASY)
	difficulty_option.add_item("Normal AI", AiDifficulty.NORMAL)
	difficulty_option.add_item("Hard AI", AiDifficulty.HARD)
	difficulty_option.selected = AiDifficulty.NORMAL
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
	current_player = HUMAN_PLAYER
	banked_scores = [0, 0]
	turn_score = 0
	dice_values.clear()
	held_indices.clear()
	can_bank = false
	game_over = false
	ai_turn_running = false
	status_label.text = "Player 1 starts. Roll the dice."
	_refresh_ui()


func _on_difficulty_selected(index: int) -> void:
	ai_difficulty = difficulty_option.get_item_id(index)
	status_label.text = "AI difficulty set to %s." % _ai_difficulty_name()
	_refresh_ui()


func _on_roll_pressed() -> void:
	if not _is_human_turn():
		return

	if not _commit_current_selection_before_roll():
		return

	_roll_current_dice()


func _on_bank_pressed() -> void:
	if not _is_human_turn():
		return

	_bank_points()


func _commit_current_selection_before_roll() -> bool:
	if dice_values.is_empty():
		return true

	var selected_score := _score_selection()
	if selected_score <= 0:
		status_label.text = "Select at least one scoring die before rolling again."
		return false

	turn_score += selected_score
	var dice_to_roll := dice_values.size() - held_indices.size()
	dice_values.clear()
	held_indices.clear()

	if dice_to_roll == 0:
		status_label.text = "Hot dice! All dice scored, rolling all six again."
		return true

	_roll_new_values(dice_to_roll)
	return false


func _roll_current_dice() -> void:
	_roll_new_values(6)


func _roll_new_values(dice_to_roll: int) -> void:
	dice_values.clear()
	held_indices.clear()
	for i in range(dice_to_roll):
		dice_values.append(rng.randi_range(1, 6))

	if _best_score_for_values(dice_values, false) == 0:
		turn_score = 0
		can_bank = false
		status_label.text = "%s busts. No scoring dice, turn passes." % _player_name(current_player)
		_refresh_ui()
		_next_player_deferred()
		return

	can_bank = true
	if _is_human_turn():
		status_label.text = "Choose dice to keep, then bank or roll again."
	else:
		status_label.text = "AI rolled: %s." % _dice_text(dice_values)
	_refresh_ui()


func _bank_points() -> void:
	if game_over or not can_bank:
		return

	var selected_score := 0
	if not dice_values.is_empty():
		selected_score = _score_selection()
		if selected_score <= 0:
			status_label.text = "Select a scoring set before banking."
			return

	banked_scores[current_player] += turn_score + selected_score
	if banked_scores[current_player] >= TARGET_SCORE:
		game_over = true
		status_label.text = "%s wins with %d points." % [_player_name(current_player), banked_scores[current_player]]
	else:
		status_label.text = "%s banks %d points." % [_player_name(current_player), turn_score + selected_score]
		_next_player()

	_refresh_ui()


func _next_player_deferred() -> void:
	await get_tree().create_timer(0.8).timeout
	if not game_over:
		_next_player()


func _next_player() -> void:
	current_player = (current_player + 1) % PLAYER_COUNT
	turn_score = 0
	dice_values.clear()
	held_indices.clear()
	can_bank = false
	status_label.text += " %s's turn." % _player_name(current_player)
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

	var dice_to_roll := 6
	while _is_ai_turn() and not game_over:
		_roll_new_values(dice_to_roll)
		if not _is_ai_turn() or game_over or not can_bank:
			break

		await get_tree().create_timer(0.6).timeout

		held_indices = _best_scoring_indices(dice_values)
		var selected_score := _score_selection()
		turn_score += selected_score
		status_label.text = "AI keeps %s for %d points." % [_dice_text(_selected_dice_values()), selected_score]
		_refresh_ui()

		await get_tree().create_timer(0.6).timeout

		var dice_remaining := dice_values.size() - held_indices.size()
		var should_bank := _ai_should_bank(dice_remaining)
		dice_values.clear()
		held_indices.clear()

		if should_bank:
			_bank_ai_points()
			break

		if dice_remaining == 0:
			status_label.text = "AI has hot dice and keeps rolling."
			dice_to_roll = 6
		else:
			dice_to_roll = dice_remaining
		dice_values.clear()

		_refresh_ui()
		await get_tree().create_timer(0.4).timeout

	ai_turn_running = false
	_refresh_ui()


func _bank_ai_points() -> void:
	banked_scores[current_player] += turn_score
	if banked_scores[current_player] >= TARGET_SCORE:
		game_over = true
		status_label.text = "AI wins with %d points." % banked_scores[current_player]
	else:
		status_label.text = "AI banks %d points." % turn_score
		_next_player()
	_refresh_ui()


func _ai_should_bank(dice_remaining: int) -> bool:
	var threshold := 450
	var chase_margin := banked_scores[HUMAN_PLAYER] - banked_scores[AI_PLAYER]

	match ai_difficulty:
		AiDifficulty.EASY:
			threshold = 300
		AiDifficulty.NORMAL:
			threshold = 550
		AiDifficulty.HARD:
			threshold = 750

	if banked_scores[AI_PLAYER] + turn_score >= TARGET_SCORE:
		return true

	if ai_difficulty == AiDifficulty.HARD and chase_margin > 900:
		threshold += 250

	if dice_remaining <= 1:
		threshold -= 150
	elif dice_remaining >= 4:
		threshold += 150

	return turn_score >= max(200, threshold)


func _toggle_die(index: int) -> void:
	if not _is_human_turn():
		return

	if held_indices.has(index):
		held_indices.erase(index)
	else:
		held_indices.append(index)

	var selected_score := _score_selection()
	if selected_score > 0:
		status_label.text = "Selected score: %d." % selected_score
	else:
		status_label.text = "That selection does not score yet."

	_refresh_ui()


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


func _score_selection() -> int:
	var selected: Array[int] = _selected_dice_values()
	return _best_score_for_values(selected)


func _selected_dice_values() -> Array[int]:
	var selected: Array[int] = []
	for index in held_indices:
		selected.append(dice_values[index])
	return selected


func _best_scoring_indices(values: Array[int]) -> Array[int]:
	var best_indices: Array[int] = []
	var best_score := 0
	var count := values.size()

	for mask in range(1, 1 << count):
		var subset: Array[int] = []
		var indices: Array[int] = []
		for i in range(count):
			if (mask & (1 << i)) != 0:
				subset.append(values[i])
				indices.append(i)
		var score := _best_score_for_values(subset)
		if score > best_score or (score == best_score and indices.size() > best_indices.size()):
			best_score = score
			best_indices = indices

	return best_indices


func _best_score_for_values(values: Array[int], require_all_scoring := true) -> int:
	if values.is_empty():
		return 0

	var counts := _count_faces(values)
	var total := 0
	var dice_count := values.size()

	if dice_count == 6:
		var is_straight := true
		for face in range(1, 7):
			if counts[face] != 1:
				is_straight = false
				break
		if is_straight:
			return 1500

		var pairs := 0
		for face in range(1, 7):
			if counts[face] == 2:
				pairs += 1
		if pairs == 3:
			return 1500

	if _consume_short_straight(counts, 2, 6):
		total += 750
	elif _consume_short_straight(counts, 1, 5):
		total += 500

	for face in range(1, 7):
		var count := counts[face]
		if count >= 3:
			var base := 1000 if face == 1 else face * 100
			total += base * int(pow(2, count - 3))
			counts[face] = 0

	total += counts[1] * 100
	total += counts[5] * 50
	if require_all_scoring:
		for face in [2, 3, 4, 6]:
			if counts[face] > 0:
				return 0
	return total


func _consume_short_straight(counts: Array[int], first_face: int, last_face: int) -> bool:
	for face in range(first_face, last_face + 1):
		if counts[face] < 1:
			return false

	for face in range(first_face, last_face + 1):
		counts[face] -= 1

	return true


func _count_faces(values: Array[int]) -> Array[int]:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for value in values:
		counts[value] += 1
	return counts


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
		AiDifficulty.EASY:
			return "Easy"
		AiDifficulty.NORMAL:
			return "Normal"
		AiDifficulty.HARD:
			return "Hard"
	return "Normal"


func _dice_text(values: Array[int]) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return "-".join(parts)
