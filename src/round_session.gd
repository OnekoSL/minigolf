class_name RoundSession
extends RefCounted

signal turn_changed(player_index: int, hole_index: int)
signal hole_finished(hole_index: int)
signal round_finished()

enum AdvanceResult { NEXT_PLAYER, HOLE_COMPLETE, ROUND_COMPLETE }

const MAX_STROKES := 8

var config: RoundConfig
var hole_catalog: HoleCatalog
var current_player_index := 0
var current_hole_index := 0
var scores: Array = []
var capped: Array = []


func configure(value: RoundConfig, catalog: HoleCatalog) -> void:
	config = value
	hole_catalog = catalog
	current_player_index = 0
	current_hole_index = 0
	scores.clear()
	capped.clear()
	for _player in config.players:
		var player_scores: Array[int] = []
		var player_caps: Array[bool] = []
		for _hole_id in config.hole_ids:
			player_scores.append(-1)
			player_caps.append(false)
		scores.append(player_scores)
		capped.append(player_caps)


func record_current_score(strokes: int, reached_limit: bool) -> int:
	scores[current_player_index][current_hole_index] = clampi(strokes, 0, MAX_STROKES)
	capped[current_player_index][current_hole_index] = reached_limit
	if current_player_index + 1 < config.players.size():
		current_player_index += 1
		turn_changed.emit(current_player_index, current_hole_index)
		return AdvanceResult.NEXT_PLAYER
	if current_hole_index + 1 < config.hole_ids.size():
		hole_finished.emit(current_hole_index)
		return AdvanceResult.HOLE_COMPLETE
	round_finished.emit()
	return AdvanceResult.ROUND_COMPLETE


func advance_hole() -> bool:
	if current_hole_index + 1 >= config.hole_ids.size():
		return false
	current_hole_index += 1
	current_player_index = 0
	turn_changed.emit(current_player_index, current_hole_index)
	return true


func get_current_player() -> PlayerProfile:
	return config.players[current_player_index]


func get_current_hole() -> HoleDefinition:
	return hole_catalog.get_hole(config.hole_ids[current_hole_index])


func get_player_total(player_index: int) -> int:
	var total := 0
	for value in scores[player_index]:
		if value >= 0:
			total += value
	return total


func get_completed_par(player_index: int) -> int:
	var total := 0
	for hole_index in range(config.hole_ids.size()):
		if scores[player_index][hole_index] >= 0:
			var hole := hole_catalog.get_hole(config.hole_ids[hole_index])
			if hole != null:
				total += hole.par
	return total


func get_player_difference(player_index: int) -> int:
	return get_player_total(player_index) - get_completed_par(player_index)


func get_ranked_player_indices() -> Array[int]:
	var indices: Array[int] = []
	for index in range(config.players.size()):
		indices.append(index)
	indices.sort_custom(func(a: int, b: int): return get_player_total(a) < get_player_total(b))
	return indices


func get_competition_rank(player_index: int) -> int:
	var ranked := get_ranked_player_indices()
	var rank := 1
	var previous_total := -1
	for position in range(ranked.size()):
		var candidate := ranked[position]
		var total := get_player_total(candidate)
		if previous_total >= 0 and total > previous_total:
			rank = position + 1
		if candidate == player_index:
			return rank
		previous_total = total
	return config.players.size()


func is_complete() -> bool:
	for player_scores in scores:
		for value in player_scores:
			if value < 0:
				return false
	return true
