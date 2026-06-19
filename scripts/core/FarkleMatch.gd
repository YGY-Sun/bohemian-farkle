extends RefCounted

const FarkleScorer := preload("res://scripts/core/FarkleScorer.gd")
const MatchConfig := preload("res://scripts/core/MatchConfig.gd")

var config
var scorer := FarkleScorer.new()
var rng := RandomNumberGenerator.new()
var current_player := 0
var banked_scores := [0, 0]
var turn_score := 0
var dice_values: Array[int] = []
var held_indices: Array[int] = []
var can_bank := false
var game_over := false
var status := ""
var roll_queue: Array[Array] = []


func _init(match_config = null) -> void:
	config = match_config.duplicate_config() if match_config != null else MatchConfig.new()
	rng.randomize()
	status = "Player 1 starts. Roll the dice."


func set_roll_queue(rolls: Array[Array]) -> void:
	roll_queue = rolls.duplicate(true)


func roll_requested() -> bool:
	if game_over:
		return false

	if dice_values.is_empty():
		return _roll_new_values(6)

	var selected_score := selection_score()
	if selected_score <= 0:
		status = "Select at least one scoring die before rolling again."
		return false

	turn_score += selected_score
	var dice_to_roll := dice_values.size() - held_indices.size()
	dice_values.clear()
	held_indices.clear()

	if dice_to_roll == 0:
		status = "Hot dice! All dice scored, rolling all six again."
		return _roll_new_values(6)

	return _roll_new_values(dice_to_roll)


func dice_selected(indices: Array[int]) -> bool:
	for index in indices:
		if index < 0 or index >= dice_values.size():
			status = "Selected die index is out of range."
			return false

	held_indices = indices.duplicate()
	if selection_score() > 0:
		status = "Selected score: %d." % selection_score()
	else:
		status = "That selection does not score yet."
	return true


func bank_requested() -> bool:
	if game_over or not can_bank:
		return false

	var selected_score := 0
	if not dice_values.is_empty():
		selected_score = selection_score()
		if selected_score <= 0:
			status = "Select a scoring set before banking."
			return false

	var banked := turn_score + selected_score
	banked_scores[current_player] += banked
	if banked_scores[current_player] >= config.target_score:
		game_over = true
		status = "%s wins with %d points." % [player_name(current_player), banked_scores[current_player]]
	else:
		status = "%s banks %d points." % [player_name(current_player), banked]
		_next_player()
	return true


func selection_score() -> int:
	return scorer.score_values(selected_dice_values())


func selected_dice_values() -> Array[int]:
	return scorer.selected_values(dice_values, held_indices)


func player_name(player_index: int) -> String:
	if player_index == 0:
		return "Player 1"
	if config.player_kinds[player_index] == MatchConfig.PlayerKind.AI:
		return "AI"
	return "Player 2"


func _roll_new_values(dice_to_roll: int) -> bool:
	dice_values = _next_roll(dice_to_roll)
	held_indices.clear()

	if scorer.is_bust(dice_values):
		turn_score = 0
		can_bank = false
		status = "%s busts. No scoring dice, turn passes." % player_name(current_player)
		_next_player()
		return false

	can_bank = true
	status = "Choose dice to keep, then bank or roll again."
	return true


func _next_roll(dice_to_roll: int) -> Array[int]:
	if not roll_queue.is_empty():
		var queued: Array = roll_queue.pop_front()
		var typed: Array[int] = []
		for value in queued:
			typed.append(value)
		return typed

	var roll: Array[int] = []
	for i in range(dice_to_roll):
		roll.append(rng.randi_range(1, 6))
	return roll


func _next_player() -> void:
	current_player = (current_player + 1) % config.player_kinds.size()
	turn_score = 0
	dice_values.clear()
	held_indices.clear()
	can_bank = false
