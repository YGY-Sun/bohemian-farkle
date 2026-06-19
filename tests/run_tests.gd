extends SceneTree

const TEST_SCRIPTS := [
	"res://tests/core/farkle_scorer_test.gd",
	"res://tests/core/farkle_match_test.gd",
	"res://tests/core/ai_policy_test.gd",
]


func _initialize() -> void:
	var failures: Array[String] = []

	for script_path in TEST_SCRIPTS:
		var test_script := load(script_path)
		if test_script == null or not test_script.can_instantiate():
			failures.append("Could not load %s" % script_path)
			continue

		var test_case = test_script.new()
		var result: Array[String] = test_case.run()
		failures.append_array(result)

	if failures.is_empty():
		print("All tests passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("%d test failure(s)." % failures.size())
	quit(1)
