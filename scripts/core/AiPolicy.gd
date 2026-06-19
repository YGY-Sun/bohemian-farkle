extends RefCounted

const MatchConfig := preload("res://scripts/core/MatchConfig.gd")
const HUMAN_PLAYER := 0
const AI_PLAYER := 1


func should_bank(ai_difficulty: int, banked_scores: Array, turn_score: int, dice_remaining: int, target_score: int) -> bool:
	var threshold := 450
	var chase_margin: int = banked_scores[HUMAN_PLAYER] - banked_scores[AI_PLAYER]

	match ai_difficulty:
		MatchConfig.AiDifficulty.EASY:
			threshold = 300
		MatchConfig.AiDifficulty.NORMAL:
			threshold = 550
		MatchConfig.AiDifficulty.HARD:
			threshold = 750

	if banked_scores[AI_PLAYER] + turn_score >= target_score:
		return true

	if ai_difficulty == MatchConfig.AiDifficulty.HARD and chase_margin > 900:
		threshold += 250

	if dice_remaining <= 1:
		threshold -= 150
	elif dice_remaining >= 4:
		threshold += 150

	return turn_score >= max(200, threshold)
