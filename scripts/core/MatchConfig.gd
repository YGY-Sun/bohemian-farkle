extends RefCounted

enum PlayerKind { HUMAN, AI, NETWORK }
enum AiDifficulty { EASY, NORMAL, HARD }

var target_score := 4000
var player_kinds: Array[int] = [PlayerKind.HUMAN, PlayerKind.AI]
var ai_difficulty := AiDifficulty.NORMAL
var special_dice_enabled := false
var badges_enabled := false
var reward_multiplier := 1.0


func duplicate_config():
	var copy = get_script().new()
	copy.target_score = target_score
	copy.player_kinds = player_kinds.duplicate()
	copy.ai_difficulty = ai_difficulty
	copy.special_dice_enabled = special_dice_enabled
	copy.badges_enabled = badges_enabled
	copy.reward_multiplier = reward_multiplier
	return copy
