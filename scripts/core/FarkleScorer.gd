extends RefCounted


func score_values(values: Array[int], require_all_scoring := true) -> int:
	if values.is_empty():
		return 0

	var counts := count_faces(values)
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

	if consume_short_straight(counts, 2, 6):
		total += 750
	elif consume_short_straight(counts, 1, 5):
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


func is_bust(values: Array[int]) -> bool:
	return score_values(values, false) == 0


func best_scoring_indices(values: Array[int]) -> Array[int]:
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
		var score := score_values(subset)
		if score > best_score or (score == best_score and indices.size() > best_indices.size()):
			best_score = score
			best_indices = indices

	return best_indices


func selected_values(values: Array[int], indices: Array[int]) -> Array[int]:
	var selected: Array[int] = []
	for index in indices:
		selected.append(values[index])
	return selected


func consume_short_straight(counts: Array[int], first_face: int, last_face: int) -> bool:
	for face in range(first_face, last_face + 1):
		if counts[face] < 1:
			return false

	for face in range(first_face, last_face + 1):
		counts[face] -= 1

	return true


func count_faces(values: Array[int]) -> Array[int]:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for value in values:
		counts[value] += 1
	return counts
