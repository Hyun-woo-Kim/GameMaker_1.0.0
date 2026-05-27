## vitality_system.gd
## 행동 비용(시간·스태미너) 계산 및 실행 처리
## 각 행동은 시간(hours)과 스태미너를 소모하고, 체력·스태미너를 회복할 수 있음
extends RefCounted
class_name VitalitySystem

enum ActionType {
	TRAVEL,        # 이동
	SPARRING,      # 스파링 (TEC, SP 획득)
	MIT_TRAINING,  # 미트 훈련 (TEC)
	DIET,          # 식사    (HP 회복)
	PARTTIME_JOB,  # 아르바이트 (골드)
	REST,          # 휴식   (스태미너 소회복)
	# ── 3대 운동 + 런닝머신
	BENCH_PRESS,   # 벤치프레스 (STR)
	SQUAT,         # 스쿼트    (HP 스탯)
	DEADLIFT,      # 데드리프트 (STA 스탯)
	TREADMILL,     # 런닝머신  (AGI)
	# ── 회복 아이템
	ENERGY_DRINK,  # 에너지 드링크 (스태미너+체력 즉시 회복)
	SLEEP,         # 잠자기 — 하루 종료 (스태미너 완전 회복)
}

# 행동 실행 결과
class ActionResult:
	var success: bool = false
	var message: String = ""
	var stat_changes: Dictionary = {}
	var gold_change: int = 0
	var sp_gained: int = 0
	var time_spent: float = 0.0
	var stamina_spent: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────

static func can_perform(action: ActionType) -> bool:
	var time_needed := get_time_cost(action)
	if GameState.time_hours_left < time_needed - 0.001:
		return false

	var sta_needed := get_stamina_cost(action)
	if sta_needed > 0.0 and GameState.cur_stamina < sta_needed:
		return false

	# 체육관 / 홈 장비 필요 여부
	match action:
		ActionType.BENCH_PRESS, ActionType.SQUAT, ActionType.DEADLIFT, \
		ActionType.SPARRING, ActionType.MIT_TRAINING:
			if not (GameState.has_gym_membership or _has_home_alt(action)):
				return false
		ActionType.TREADMILL:
			if not (GameState.has_gym_membership or _has_home_alt(action)):
				return false

	# 에너지 드링크: 골드 필요
	if action == ActionType.ENERGY_DRINK:
		if GameState.gold < Config.energy_drink_cost:
			return false

	return true

static func _has_home_alt(action: ActionType) -> bool:
	match action:
		ActionType.BENCH_PRESS, ActionType.SQUAT, ActionType.DEADLIFT, ActionType.MIT_TRAINING:
			return GameState.home_equipment.get("dumbbell_set",  false) \
			    or GameState.home_equipment.get("full_home_gym", false)
		ActionType.TREADMILL:
			return GameState.home_equipment.get("treadmill",     false) \
			    or GameState.home_equipment.get("full_home_gym", false)
		ActionType.SPARRING:
			return false  # 스파링은 항상 체육관 필요
	return false

# ── 시간 비용 (시간 단위)
static func get_time_cost(action: ActionType) -> float:
	match action:
		ActionType.BENCH_PRESS, ActionType.SQUAT, ActionType.DEADLIFT:
			return Config.time_cost_exercise
		ActionType.TREADMILL:
			return Config.time_cost_treadmill
		ActionType.SPARRING, ActionType.MIT_TRAINING:
			return Config.time_cost_sparring
		ActionType.PARTTIME_JOB:
			return Config.time_cost_parttime
		ActionType.REST:
			return Config.time_cost_rest
		ActionType.DIET:
			return Config.time_cost_eat
		ActionType.ENERGY_DRINK:
			return 0.0
		ActionType.SLEEP:
			return GameState.time_hours_left  # 남은 시간 전부 사용
	return 0.0

# ── 스태미너 비용 (양수 = 소모, 음수 = 회복)
static func get_stamina_cost(action: ActionType) -> float:
	match action:
		ActionType.BENCH_PRESS, ActionType.SQUAT, ActionType.DEADLIFT:
			return Config.sta_cost_exercise
		ActionType.TREADMILL:
			return Config.sta_cost_treadmill
		ActionType.SPARRING, ActionType.MIT_TRAINING:
			return Config.sta_cost_sparring
		ActionType.PARTTIME_JOB:
			return Config.sta_cost_parttime
		ActionType.REST:
			return 0.0  # 휴식은 별도로 restore 처리
	return 0.0

# ─────────────────────────────────────────────────────────────────────────────

static func perform(action: ActionType) -> ActionResult:
	var r := ActionResult.new()

	if not can_perform(action):
		r.message = _fail_reason(action)
		return r

	r.success = true
	var time_cost := get_time_cost(action)
	GameState.spend_time(time_cost)
	r.time_spent = time_cost

	var sta_cost := get_stamina_cost(action)
	if sta_cost > 0.0:
		GameState.consume_stamina(sta_cost)
		r.stamina_spent = sta_cost

	match action:
		# ── 3대 운동 ────────────────────────────────────────────────────────
		ActionType.BENCH_PRESS:
			var gain := _calc_gain("STR", 3.0)
			GameState.modify_stat("STR", gain)
			r.stat_changes["STR"] = gain
			r.message = "벤치프레스 완료!  STR +%.1f" % gain

		ActionType.SQUAT:
			var gain := _calc_gain("HP", 12.0)
			GameState.modify_stat("HP", gain)
			r.stat_changes["HP"] = gain
			r.message = "스쿼트 완료!  HP(스탯) +%.1f" % gain

		ActionType.DEADLIFT:
			var gain := _calc_gain("STA", 3.0)
			GameState.modify_stat("STA", gain)
			r.stat_changes["STA"] = gain
			r.message = "데드리프트 완료!  STA +%.1f" % gain

		# ── 런닝머신 ─────────────────────────────────────────────────────────
		ActionType.TREADMILL:
			var gain := _calc_gain("AGI", 2.0)
			GameState.modify_stat("AGI", gain)
			r.stat_changes["AGI"] = gain
			r.message = "런닝머신 완료!  AGI +%.1f" % gain

		# ── 스파링 ───────────────────────────────────────────────────────────
		ActionType.SPARRING:
			var tec_gain := _calc_gain("TEC", 3.0)
			GameState.modify_stat("TEC", tec_gain)
			GameState.add_skill_point(1)
			r.stat_changes["TEC"] = tec_gain
			r.sp_gained = 1
			r.message = "스파링 완료!  TEC +%.1f  SP +1" % tec_gain

		ActionType.MIT_TRAINING:
			var tec_gain := _calc_gain("TEC", 2.0)
			GameState.modify_stat("TEC", tec_gain)
			r.stat_changes["TEC"] = tec_gain
			r.message = "미트 훈련 완료!  TEC +%.1f" % tec_gain

		# ── 식사 (체력 회복) ──────────────────────────────────────────────────
		ActionType.DIET:
			if not GameState.spend_gold(Config.diet_cost):
				r.success = false
				r.message = "골드 부족 (식사비: %d골드)" % Config.diet_cost
				GameState.spend_time(-time_cost)  # 시간 환불
				return r
			GameState.restore_hp(Config.hp_restore_eat)
			r.stat_changes["cur_HP"] = Config.hp_restore_eat
			r.gold_change = -Config.diet_cost
			r.message = "식사 완료!  체력 +%.0f  (-%d골드)" % [Config.hp_restore_eat, Config.diet_cost]

		# ── 에너지 드링크 (즉시 회복) ─────────────────────────────────────────
		ActionType.ENERGY_DRINK:
			GameState.spend_gold(Config.energy_drink_cost)
			GameState.restore_stamina(Config.sta_restore_drink)
			GameState.restore_hp(Config.hp_restore_drink)
			r.stat_changes["cur_STA"] = Config.sta_restore_drink
			r.stat_changes["cur_HP"]  = Config.hp_restore_drink
			r.gold_change = -Config.energy_drink_cost
			r.message = "에너지 드링크!  스태미너 +%.0f  체력 +%.0f  (-%d골드)" % [
				Config.sta_restore_drink, Config.hp_restore_drink, Config.energy_drink_cost]

		# ── 아르바이트 ────────────────────────────────────────────────────────
		ActionType.PARTTIME_JOB:
			var earned := randi_range(Config.parttime_gold_min, Config.parttime_gold_max)
			GameState.earn_gold(earned)
			r.gold_change = earned
			r.message = "아르바이트 완료!  💰 +%d골드" % earned

		# ── 휴식 (스태미너 소회복) ────────────────────────────────────────────
		ActionType.REST:
			GameState.restore_stamina(Config.sta_restore_rest)
			r.stat_changes["cur_STA"] = Config.sta_restore_rest
			r.message = "휴식 완료!  스태미너 +%.0f" % Config.sta_restore_rest

		# ── 잠자기 → 하루 종료 (호출부에서 직접 GameState.end_day() 처리)
		ActionType.SLEEP:
			r.message = "SLEEP"  # 신호: 호출부에서 end_day() 실행

	return r

# ── 실패 이유 메시지
static func _fail_reason(action: ActionType) -> String:
	if GameState.time_hours_left < get_time_cost(action) - 0.001:
		return "시간이 부족합니다! (필요: %.1f시간)" % get_time_cost(action)
	if get_stamina_cost(action) > 0.0 and GameState.cur_stamina < get_stamina_cost(action):
		return "스태미너가 부족합니다! (필요: %.0f)" % get_stamina_cost(action)
	if action == ActionType.ENERGY_DRINK and GameState.gold < Config.energy_drink_cost:
		return "골드 부족 (에너지 드링크: %d골드)" % Config.energy_drink_cost
	if not GameState.has_gym_membership and not _has_home_alt(action):
		return "체육관 멤버십 또는 홈 장비가 필요합니다!"
	return "조건 부족"

# ── 수확 체감 공식
static func _calc_gain(stat: String, base: float) -> float:
	var current: float = GameState.stats.get(stat, 10.0)
	var target := 80.0
	if current <= 0:
		return base
	return base * pow(target / current, Config.diminishing_returns_exp)
