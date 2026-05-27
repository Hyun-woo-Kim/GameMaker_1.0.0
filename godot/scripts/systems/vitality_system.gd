## vitality_system.gd
## 하루 활력(VIT) 예산 관리 및 행동 실행 처리
extends RefCounted
class_name VitalitySystem

enum ActionType {
	TRAVEL,          # 이동
	WEIGHT_TRAINING, # 웨이트 (STR)
	RUNNING,         # 달리기 (AGI)
	JUMP_ROPE,       # 줄넘기 (AGI+VIT)
	SPARRING,        # 스파링 (TEC, SP 획득)
	MIT_TRAINING,    # 미트 훈련 (TEC)
	DIET,            # 식단 (HP+VIT)
	PARTTIME_JOB,    # 아르바이트 (골드)
	REST,            # 휴식 (VIT 회복)
}

# 행동 실행 결과
class ActionResult:
	var success: bool = false
	var message: String = ""
	var stat_changes: Dictionary = {}   # { "STR": +3.0 }
	var gold_change: int = 0
	var sp_gained: int = 0
	var vitality_spent: int = 0

# ─────────────────────────────────────────────────────────────────────────────

static func can_perform(action: ActionType) -> bool:
	var cost := get_vitality_cost(action)
	if GameState.vitality < cost:
		return false
	match action:
		ActionType.WEIGHT_TRAINING, ActionType.SPARRING, ActionType.MIT_TRAINING:
			return GameState.has_gym_membership or _has_home_alt(action)
		ActionType.TRAVEL:
			return GameState.get_travel_cost() > 0  # 이동 필요할 때만
	return true

static func _has_home_alt(action: ActionType) -> bool:
	match action:
		ActionType.WEIGHT_TRAINING:
			return GameState.home_equipment["dumbbell_set"] or \
			       GameState.home_equipment["full_home_gym"]
		ActionType.SPARRING:
			return false  # 스파링은 항상 체육관 또는 초청 필요
		ActionType.MIT_TRAINING:
			return GameState.home_equipment["sandbag"]
	return false

static func get_vitality_cost(action: ActionType) -> int:
	match action:
		ActionType.TRAVEL:          return Config.travel_cost_one_way
		ActionType.WEIGHT_TRAINING: return Config.action_cost_weight
		ActionType.RUNNING:         return Config.action_cost_run
		ActionType.JUMP_ROPE:       return Config.action_cost_run - 2
		ActionType.SPARRING:        return Config.action_cost_sparring
		ActionType.MIT_TRAINING:    return Config.action_cost_weight - 2
		ActionType.DIET:            return 5
		ActionType.PARTTIME_JOB:    return Config.action_cost_parttime
		ActionType.REST:            return 0
	return 0

static func perform(action: ActionType) -> ActionResult:
	var r := ActionResult.new()

	if not can_perform(action):
		r.message = "활력 또는 조건 부족"
		return r

	var cost := get_vitality_cost(action)
	GameState.spend_vitality(cost)
	r.vitality_spent = cost
	r.success = true

	match action:
		ActionType.WEIGHT_TRAINING:
			var gain := _calc_gain("STR", 3.0)
			GameState.modify_stat("STR", gain)
			r.stat_changes["STR"] = gain
			r.message = "웨이트 트레이닝 완료"

		ActionType.RUNNING:
			var gain := _calc_gain("AGI", 2.0)
			GameState.modify_stat("AGI", gain)
			r.stat_changes["AGI"] = gain
			r.message = "달리기 완료"

		ActionType.JUMP_ROPE:
			var agi_gain := _calc_gain("AGI", 1.0)
			GameState.modify_stat("AGI", agi_gain)
			GameState.restore_vitality(2)
			r.stat_changes["AGI"] = agi_gain
			r.stat_changes["VIT"] = 2
			r.message = "줄넘기 완료"

		ActionType.SPARRING:
			var tec_gain := _calc_gain("TEC", 3.0)
			GameState.modify_stat("TEC", tec_gain)
			GameState.modify_stat("HP", -5.0)
			GameState.add_skill_point(1)
			r.stat_changes["TEC"] = tec_gain
			r.stat_changes["HP"] = -5.0
			r.sp_gained = 1
			r.message = "스파링 완료 (SP +1)"

		ActionType.MIT_TRAINING:
			var tec_gain := _calc_gain("TEC", 2.0)
			GameState.modify_stat("TEC", tec_gain)
			r.stat_changes["TEC"] = tec_gain
			r.message = "미트 훈련 완료"

		ActionType.DIET:
			GameState.modify_stat("HP", 10.0)
			GameState.restore_vitality(5)
			if GameState.spend_gold(Config.diet_cost):
				r.stat_changes["HP"] = 10.0
				r.gold_change = -Config.diet_cost
				r.message = "식단 관리 완료"
			else:
				r.success = false
				r.message = "골드 부족"

		ActionType.PARTTIME_JOB:
			var earned := randi_range(Config.parttime_gold_min, Config.parttime_gold_max)
			GameState.earn_gold(earned)
			r.gold_change = earned
			r.message = "아르바이트 완료 (+%d골드)" % earned

		ActionType.REST:
			GameState.restore_vitality(Config.rest_vitality_restore)
			r.stat_changes["VIT"] = Config.rest_vitality_restore
			r.message = "휴식 완료"

	return r

# 수확 체감 공식 적용
static func _calc_gain(stat: String, base: float) -> float:
	var current := GameState.stats.get(stat, 10.0)
	# 티어별 목표 스탯을 Config나 GameData에서 가져오는 것이 이상적이나
	# 우선 80을 임시 목표값으로 사용
	var target := 80.0
	if current <= 0:
		return base
	return base * pow(target / current, Config.diminishing_returns_exp)
