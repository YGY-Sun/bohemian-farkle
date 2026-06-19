extends Control

const TARGET_SCORE := 4000
const PLAYER_COUNT := 2

var rng := RandomNumberGenerator.new()
var current_player := 0
var banked_scores := [0, 0]
var turn_score := 0
var dice_values: Array[int] = []
var held_indices: Array[int] = []
var can_bank := false
var game_over := false

var title_label: Label
var status_label: Label
var score_label: Label
var turn_label: Label
var dice_box: HBoxContainer
var roll_button: Button
var bank_button: Button
var new_game_button: Button
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

	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(_new_game)
	header.add_child(new_game_button)

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
	roll_button.pressed.connect(_roll_dice)
	actions.add_child(roll_button)

	bank_button = Button.new()
	bank_button.text = "Bank"
	bank_button.custom_minimum_size = Vector2(150, 48)
	bank_button.pressed.connect(_bank_points)
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
	rule_label.text = "[b]Scoring[/b]\n1 = 100, 5 = 50. Three of a kind scores face x 100, except 1-1-1 = 1000. Four/five/six of a kind double each extra die. Straight = 1500, three pairs = 1500. Select scoring dice, then bank or risk another roll."
	root.add_child(rule_label)


func _new_game() -> void:
	current_player = 0
	banked_scores = [0, 0]
	turn_score = 0
	dice_values.clear()
	held_indices.clear()
	can_bank = false
	game_over = false
	roll_button.disabled = false
	bank_button.disabled = true
	status_label.text = "Player 1 starts. Roll the dice."
	_refresh_ui()


func _roll_dice() -> void:
	if game_over:
		return

	var dice_to_roll := 6
	if not dice_values.is_empty():
		var selected_score := _score_selection()
		if selected_score <= 0:
			status_label.text = "Select at least one scoring die before rolling again."
			return

		turn_score += selected_score
		dice_to_roll = dice_values.size() - held_indices.size()
		if dice_to_roll == 0:
			dice_to_roll = 6
			status_label.text = "Hot dice! All dice scored, rolling all six again."

	dice_values.clear()
	held_indices.clear()
	for i in range(dice_to_roll):
		dice_values.append(rng.randi_range(1, 6))

	if _best_score_for_values(dice_values, false) == 0:
		turn_score = 0
		can_bank = false
		status_label.text = "Bust. No scoring dice, turn passes."
		_refresh_ui()
		await get_tree().create_timer(0.8).timeout
		_next_player()
		return

	can_bank = true
	status_label.text = "Choose dice to keep, then bank or roll again."
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
		status_label.text = "Player %d wins with %d points." % [current_player + 1, banked_scores[current_player]]
		roll_button.disabled = true
		bank_button.disabled = true
	else:
		status_label.text = "Player %d banks points." % [current_player + 1]
		_next_player()

	_refresh_ui()


func _next_player() -> void:
	current_player = (current_player + 1) % PLAYER_COUNT
	turn_score = 0
	dice_values.clear()
	held_indices.clear()
	can_bank = false
	status_label.text += " Player %d's turn." % [current_player + 1]
	_refresh_ui()


func _toggle_die(index: int) -> void:
	if game_over:
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
	score_label.text = "Player 1: %d / %d      Player 2: %d / %d" % [banked_scores[0], TARGET_SCORE, banked_scores[1], TARGET_SCORE]
	turn_label.text = "Player %d turn score: %d" % [current_player + 1, turn_score]
	bank_button.disabled = game_over or not can_bank
	roll_button.disabled = game_over

	for child in dice_box.get_children():
		child.queue_free()

	for i in dice_values.size():
		var button := Button.new()
		button.text = str(dice_values[i])
		button.custom_minimum_size = Vector2(86, 86)
		button.add_theme_font_size_override("font_size", 34)
		if held_indices.has(i):
			button.modulate = Color(0.75, 1.0, 0.72)
		button.pressed.connect(_toggle_die.bind(i))
		dice_box.add_child(button)


func _score_selection() -> int:
	var selected: Array[int] = []
	for index in held_indices:
		selected.append(dice_values[index])
	return _best_score_for_values(selected)


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


func _count_faces(values: Array[int]) -> Array[int]:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for value in values:
		counts[value] += 1
	return counts
