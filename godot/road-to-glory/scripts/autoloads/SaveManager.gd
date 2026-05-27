## SaveManager.gd
## 게임 진행 상태를 JSON으로 저장/불러오기
extends Node

const SAVE_PATH := "user://save.json"

signal save_completed
signal load_completed

# ── 저장
func save() -> void:
	var data := {
		"version":          2,
		"current_day":      GameState.current_day,
		"current_tier":     GameState.current_tier,
		"player_class":     GameState.player_class,
		"rival_class":      GameState.rival_class,
		"gold":             GameState.gold,
		"cur_hp":           GameState.cur_hp,
		"cur_stamina":      GameState.cur_stamina,
		"time_hours_left":  GameState.time_hours_left,
		"skill_points":     GameState.skill_points,
		"unlocked_skills":  GameState.unlocked_skills,
		"match_wins":       GameState.match_wins,
		"match_losses":     GameState.match_losses,
		"has_gym_membership":    GameState.has_gym_membership,
		"gym_membership_days":   GameState.gym_membership_days,
		"home_equipment":        GameState.home_equipment,
		"stats":                 GameState.stats,
		"wins_this_tier":        GameState.wins_this_tier,
		"rival_defeated_count":  GameState.rival_defeated_count,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 저장 실패 → " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit()
	print("SaveManager: 저장 완료 — Day %d" % GameState.current_day)

# ── 불러오기
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data  = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		push_error("SaveManager: 파싱 실패")
		return false

	GameState.current_day    = data.get("current_day",  1)
	GameState.current_tier   = data.get("current_tier", 1)
	GameState.player_class   = data.get("player_class", "")
	GameState.rival_class    = data.get("rival_class",  "")
	GameState.gold           = data.get("gold",         300)
	GameState.skill_points   = data.get("skill_points", 0)
	GameState.match_wins     = data.get("match_wins",   0)
	GameState.match_losses   = data.get("match_losses", 0)
	GameState.has_gym_membership  = data.get("has_gym_membership", false)
	GameState.gym_membership_days = data.get("gym_membership_days", 0)
	GameState.wins_this_tier      = data.get("wins_this_tier", 0)
	GameState.rival_defeated_count= data.get("rival_defeated_count", 0)

	var skills = data.get("unlocked_skills", [])
	GameState.unlocked_skills.clear()
	for s in skills:
		GameState.unlocked_skills.append(str(s))

	var equip = data.get("home_equipment", {})
	for key in GameState.home_equipment.keys():
		if equip.has(key):
			GameState.home_equipment[key] = equip[key]

	# 영구 스탯 먼저 복원 (cur_hp/cur_stamina 상한 계산에 필요)
	var saved_stats = data.get("stats", {})
	for key in GameState.stats.keys():
		if saved_stats.has(key):
			GameState.stats[key] = float(saved_stats[key])

	# 런타임 자원 복원 (없으면 최대치로 초기화)
	GameState.time_hours_left = float(data.get("time_hours_left", 18.0))
	GameState.cur_hp          = float(data.get("cur_hp",          GameState.get_hp_max()))
	GameState.cur_stamina     = float(data.get("cur_stamina",     GameState.get_stamina_max()))

	load_completed.emit()
	print("SaveManager: 불러오기 완료 — Day %d / 티어 %d" % [GameState.current_day, GameState.current_tier])
	return true

# ── 세이브 파일 삭제
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
