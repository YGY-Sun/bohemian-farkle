extends RefCounted

const FarkleScorer := preload("res://scripts/core/FarkleScorer.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var scorer := FarkleScorer.new()

	_expect_eq(failures, "single one scores 100", scorer.score_values([1]), 100)
	_expect_eq(failures, "single five scores 50", scorer.score_values([5]), 50)
	_expect_eq(failures, "three ones score 1000", scorer.score_values([1, 1, 1]), 1000)
	_expect_eq(failures, "three twos score 200", scorer.score_values([2, 2, 2]), 200)
	_expect_eq(failures, "three sixes score 600", scorer.score_values([6, 6, 6]), 600)
	_expect_eq(failures, "four twos double the triple", scorer.score_values([2, 2, 2, 2]), 400)
	_expect_eq(failures, "six threes double three times", scorer.score_values([3, 3, 3, 3, 3, 3]), 2400)
	_expect_eq(failures, "straight one through six scores 1500", scorer.score_values([1, 2, 3, 4, 5, 6]), 1500)
	_expect_eq(failures, "short straight one through five scores 500", scorer.score_values([1, 2, 3, 4, 5]), 500)
	_expect_eq(failures, "short straight two through six scores 750", scorer.score_values([2, 3, 4, 5, 6]), 750)
	_expect_eq(failures, "three pairs score 1500", scorer.score_values([1, 1, 3, 3, 6, 6]), 1500)
	_expect_eq(failures, "unscoring leftovers invalidate a selection", scorer.score_values([1, 2]), 0)
	_expect_eq(failures, "full roll with a scoring die is not bust", scorer.is_bust([2, 3, 4, 5, 6]), false)
	_expect_eq(failures, "full roll with three sixes is not bust", scorer.is_bust([2, 3, 3, 6, 6, 6]), false)
	_expect_eq(failures, "full roll without scoring dice is bust", scorer.is_bust([2, 2, 3, 3, 4, 6]), true)
	_expect_array_eq(failures, "best indices keep highest scoring set", scorer.best_scoring_indices([1, 1, 1, 5, 2]), [0, 1, 2, 3])
	_expect_array_eq(failures, "best indices can keep three sixes", scorer.best_scoring_indices([2, 3, 3, 6, 6, 6]), [3, 4, 5])

	return failures


func _expect_eq(failures: Array[String], label: String, actual, expected) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _expect_array_eq(failures: Array[String], label: String, actual: Array[int], expected: Array[int]) -> void:
	if actual.size() != expected.size():
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		return

	for i in expected.size():
		if actual[i] != expected[i]:
			failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
			return
