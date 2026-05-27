## GameState.gd
## 현재 진행 중인 게임의 모든 런타임 상태를 보관하는 싱글톤
extends Node

signal stats_changed(stat_name: String, new_value: float)
signal gold_changed(new_value: int)
signal day_ended(day_number: int)
signal vitality_changed(new_value: int)

# ── 플레이어 기본 정보
var player_class: String = ""        # "boxer" | "wrestler" | "jiu_jitsu"
var rival_class: String  = ""
var current_tier: int    = 1         # 1~4
var current_day: int     = 1

# ── 스탯 (전투용)
var stats := {
	"STR": 10.0,
	"AGI": 10.0,
	"STA": 10.0,
	"TEC": 10.0,
	"HP":  100.0,
}

# ── 활력 (하루 행동 예산)
var vitality: int          = 100
var vitality_max: int      = 100

# ── 경제
var gold: int              = 300     # 초기 보유 골드
var has_gym_membership: bool = false
var gym_membership_days: int = 0

# ── 집 장비 보유 여부
var home_equipment := {
	"dumbbell_set": false,   # 덤벨 세트 — STR 기초 훈련 가능
	"treadmill":    false,   # 런닝머신 — AGI 기초 훈련 가능
	"sandbag":      false,   # 샌드백 — STR+TEC 기초 훈련 가능
	"full_home_gym": false,  # 홈짐 풀세트 — STR+AGI 이동 없이 훈련
}

# ── 스킬 포인트 & 스킬 트리
var skill_points: int  = 0
var unlocked_skills: Array[String] = []

# ── 전투 기록
var match_wins: int   = 0
var match_losses: int = 0

# ─────────────────────────────────────────────────────────────────────────────

func setup(p_class: String) -> void:
	player_class = p_class
	rival_class  = _get_rival_class(p_class)
	var base := GameData.get_class_base_stats(p_class)
	if base.is_empty():
		push_warning("GameState: 직업 데이터 없음 → " + p_class)
		return
	for key in stats.keys():
		stats[key] = float(base.get(key, stats[key]))

func _get_rival_class(p_class: String) -> String:
	match p_class:
		"boxer":     return "wrestler"
		"wrestler":  return "jiu_jitsu"
		"jiu_jitsu": return "boxer"
	return ""

# ── 활력 소모/회복
func spend_vitality(amount: int) -> bool:
	if vitality < amount:
		return false
	vitality = max(0, vitality - amount)
	vitality_changed.emit(vitality)
	return true

func restore_vitality(amount: int) -> void:
	vitality = min(vitality_max, vitality + amount)
	vitality_changed.emit(vitality)

# ── 이동 비용 계산 (집 장비 보유 여부에 따라)
func get_travel_cost() -> int:
	if home_equipment["full_home_gym"]:
		return 0
	return 30  # 왕복 30 VIT

# ── 스탯 변경
func modify_stat(stat: String, delta: float) -> void:
	if not stats.has(stat):
		return
	stats[stat] = maxf(0.0, stats[stat] + delta)
	stats_changed.emit(stat, stats[stat])

# ── 하루 종료 처리 (스탯 자연 감소)
func end_day() -> void:
	_apply_stat_decay()
	vitality = vitality_max  # 다음 날 활력 완전 회복
	current_day += 1
	_update_gym_membership()
	day_ended.emit(current_day)

func _apply_stat_decay() -> void:
	var sta_low := stats["STA"] < 20.0
	var mult    := 2.0 if sta_low else 1.0
	modify_stat("STR", -0.5 * mult)
	modify_stat("AGI", -0.7 * mult)
	modify_stat("TEC", -0.3 * mult)

func _update_gym_membership() -> void:
	if has_gym_membership:
		gym_membership_days -= 1
		if gym_membership_days <= 0:
			has_gym_membership = false

# ── 골드 관리
func earn_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# ── 스킬 언락
func unlock_skill(skill_id: String) -> bool:
	if skill_points <= 0:
		return false
	if skill_id in unlocked_skills:
		return false
	unlocked_skills.append(skill_id)
	skill_points -= 1
	return true

func add_skill_point(amount: int = 1) -> void:
	skill_points += amount
