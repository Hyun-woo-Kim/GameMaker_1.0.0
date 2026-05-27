## GameData.gd
## JSON 데이터 파일을 로드하고 전역으로 제공하는 싱글톤
## Excel → JSON 변환 후 이 싱글톤을 통해 모든 시스템이 데이터에 접근
extends Node

# 로드된 데이터 캐시
var character_stats: Dictionary = {}
var enemy_stats: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}
var economy: Dictionary = {}

const DATA_PATH = "res://data/json/"

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	character_stats = _load_json("character_stats.json")
	enemy_stats     = _load_json("enemy_stats.json")
	skills          = _load_json("skills.json")
	items           = _load_json("items.json")
	economy         = _load_json("economy.json")

func _load_json(filename: String) -> Dictionary:
	var path := DATA_PATH + filename
	if not FileAccess.file_exists(path):
		push_warning("GameData: 파일 없음 → " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var result := JSON.parse_string(text)
	if result == null:
		push_error("GameData: JSON 파싱 실패 → " + path)
		return {}
	return result

# 특정 직업의 스탯 기초값 반환
func get_class_base_stats(class_id: String) -> Dictionary:
	return character_stats.get(class_id, {})

# 특정 적의 스탯 반환
func get_enemy_stats(enemy_id: String) -> Dictionary:
	return enemy_stats.get(enemy_id, {})

# 특정 스킬 데이터 반환
func get_skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})

# 상성 배율 반환 (advantage: "favorable" | "neutral" | "unfavorable")
func get_class_advantage_mult(advantage: String) -> float:
	match advantage:
		"favorable":   return 1.2
		"unfavorable": return 0.8
		_:             return 1.0

# 상성 관계 판단
func get_advantage(attacker_class: String, defender_class: String) -> String:
	# boxer > jiu_jitsu > wrestler > boxer
	var wins_against := {
		"boxer":     "jiu_jitsu",
		"wrestler":  "boxer",
		"jiu_jitsu": "wrestler",
	}
	if wins_against.get(attacker_class) == defender_class:
		return "favorable"
	if wins_against.get(defender_class) == attacker_class:
		return "unfavorable"
	return "neutral"

# 런타임 중 데이터 핫리로드 (개발 중 편의 기능)
func reload() -> void:
	_load_all()
	print("GameData: 데이터 리로드 완료")
