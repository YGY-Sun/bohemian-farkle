extends RefCounted

const MatchConfig := preload("res://scripts/core/MatchConfig.gd")
const FarkleMatch := preload("res://scripts/core/FarkleMatch.gd")


func run() -> Array[String]:
	var failures: Array[String] = []

	_default_config_has_mvp_values(failures)
	_match_starts_on_player_one(failures)
	_roll_command_uses_injected_dice(failures)
	_selection_command_tracks_selected_dice(failures)
	_bank_command_adds_selection_and_changes_turn(failures)
	_bust_roll_passes_turn_with_zero_turn_score(failures)
	_hot_dice_rolls_all_six_after_all_dice_score(failures)

	return failures


func _default_config_has_mvp_values(failures: Array[String]) -> void:
	var config := MatchConfig.new()
	_expect_eq(failures, "default target score", config.target_score, 4000)
	_expect_eq(failures, "default player one kind", config.player_kinds[0], MatchConfig.PlayerKind.HUMAN)
	_expect_eq(failures, "default player two kind", config.player_kinds[1], MatchConfig.PlayerKind.AI)
	_expect_eq(failures, "default AI difficulty", config.ai_difficulty, MatchConfig.AiDifficulty.NORMAL)
	_expect_eq(failures, "special dice disabled by default", config.special_dice_enabled, false)
	_expect_eq(failures, "badges disabled by default", config.badges_enabled, false)
	_expect_eq(failures, "default reward multiplier", config.reward_multiplier, 1.0)


func _match_starts_on_player_one(failures: Array[String]) -> void:
	var game := FarkleMatch.new(MatchConfig.new())
	_expect_eq(failures, "initial current player", game.current_player, 0)
	_expect_eq(failures, "initial scores", game.banked_scores, [0, 0])
	_expect_eq(failures, "initial turn score", game.turn_score, 0)
	_expect_eq(failures, "initial can bank", game.can_bank, false)


func _roll_command_uses_injected_dice(failures: Array[String]) -> void:
	var game := FarkleMatch.new(MatchConfig.new())
	game.set_roll_queue([[1, 5, 2, 3, 4, 6]])
	_expect_eq(failures, "roll command succeeds", game.roll_requested(), true)
	_expect_eq(failures, "roll command stores dice", game.dice_values, [1, 5, 2, 3, 4, 6])
	_expect_eq(failures, "roll command enables banking", game.can_bank, true)


func _selection_command_tracks_selected_dice(failures: Array[String]) -> void:
	var game := FarkleMatch.new(MatchConfig.new())
	game.set_roll_queue([[1, 5, 2, 3, 4, 6]])
	game.roll_requested()
	_expect_eq(failures, "selection command succeeds", game.dice_selected([0, 1]), true)
	_expect_eq(failures, "selection stores indices", game.held_indices, [0, 1])
	_expect_eq(failures, "selection score is exposed", game.selection_score(), 150)


func _bank_command_adds_selection_and_changes_turn(failures: Array[String]) -> void:
	var game := FarkleMatch.new(MatchConfig.new())
	game.set_roll_queue([[1, 5, 2, 3, 4, 6]])
	game.roll_requested()
	game.dice_selected([0, 1])
	_expect_eq(failures, "bank command succeeds", game.bank_requested(), true)
	_expect_eq(failures, "bank adds selection", game.banked_scores[0], 150)
	_expect_eq(failures, "bank changes turn", game.current_player, 1)
	_expect_eq(failures, "bank clears dice", game.dice_values, [])


func _bust_roll_passes_turn_with_zero_turn_score(failures: Array[String]) -> void:
	var game := FarkleMatch.new(MatchConfig.new())
	game.set_roll_queue([[2, 3, 3, 4, 6, 6]])
	_expect_eq(failures, "bust roll command returns false", game.roll_requested(), false)
	_expect_eq(failures, "bust clears turn score", game.turn_score, 0)
	_expect_eq(failures, "bust changes turn", game.current_player, 1)
	_expect_eq(failures, "bust disables banking", game.can_bank, false)
	_expect_eq(failures, "bust status names next turn", game.status, "Player 1 busts. No scoring dice, turn passes. AI's turn.")


func _hot_dice_rolls_all_six_after_all_dice_score(failures: Array[String]) -> void:
	var game := FarkleMatch.new(MatchConfig.new())
	game.set_roll_queue([[1, 2, 3, 4, 5, 6], [1, 5, 2, 3, 4, 6]])
	game.roll_requested()
	game.dice_selected([0, 1, 2, 3, 4, 5])
	_expect_eq(failures, "hot dice roll succeeds", game.roll_requested(), true)
	_expect_eq(failures, "hot dice commits turn score", game.turn_score, 1500)
	_expect_eq(failures, "hot dice rolls six dice", game.dice_values, [1, 5, 2, 3, 4, 6])


func _expect_eq(failures: Array[String], label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
