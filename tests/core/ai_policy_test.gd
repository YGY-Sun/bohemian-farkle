extends RefCounted

const MatchConfig := preload("res://scripts/core/MatchConfig.gd")
const AiPolicy := preload("res://scripts/core/AiPolicy.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var policy := AiPolicy.new()

	_expect_eq(failures, "easy banks at 300", policy.should_bank(MatchConfig.AiDifficulty.EASY, [0, 0], 300, 3, 4000), true)
	_expect_eq(failures, "normal waits below 550", policy.should_bank(MatchConfig.AiDifficulty.NORMAL, [0, 0], 500, 3, 4000), false)
	_expect_eq(failures, "normal banks at 550", policy.should_bank(MatchConfig.AiDifficulty.NORMAL, [0, 0], 550, 3, 4000), true)
	_expect_eq(failures, "hard banks at 750", policy.should_bank(MatchConfig.AiDifficulty.HARD, [0, 0], 750, 3, 4000), true)
	_expect_eq(failures, "AI banks when it can win", policy.should_bank(MatchConfig.AiDifficulty.HARD, [0, 3900], 100, 6, 4000), true)
	_expect_eq(failures, "hard AI raises threshold when far behind", policy.should_bank(MatchConfig.AiDifficulty.HARD, [2000, 500], 900, 3, 4000), false)
	_expect_eq(failures, "one die remaining lowers threshold", policy.should_bank(MatchConfig.AiDifficulty.NORMAL, [0, 0], 400, 1, 4000), true)
	_expect_eq(failures, "many dice remaining raises threshold", policy.should_bank(MatchConfig.AiDifficulty.NORMAL, [0, 0], 650, 4, 4000), false)

	return failures


func _expect_eq(failures: Array[String], label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
