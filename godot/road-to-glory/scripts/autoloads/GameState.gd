## GameState.gd
## 현재 진행 중인 게임의 모든 런타임 상태를 보관하는 싱글톤
extends Node

signal stats_changed(stat_name: String, new_value: float)
signal gold_changed(new_value: int)
signal day_ended(day_number: int)
signal tier_advanced(new_tier: int)
signal match_result_recorded(won: bool, sp_gained: int, gold_gained: int)
# ── 새 리소스 시그널
signal time_changed(hours_left: float)
signal cur_hp_changed(value: float, max_val: float)
signal cur_stamina_changed(value: float, max_val: float)

# ── 플레이어 기본 정보
var player_class: String = ""
var rival_class:  String = ""
var current_tier: int    = 1
var current_day:  int    = 1

# ── 티어 진행 추적
var wins_this_tier:       int = 0
var rival_defeated_count: int = 0
const WINS_TO_ADVANCE := { 1: 3, 2: 4, 3: 5, 4: 999 }

# ── 영구 스탯 (훈련으로 성장)
var stats := {
	"STR": 10.0, "AGI": 10.0, "STA": 10.0, "TEC": 10.0, "HP": 100.0,
}

# ── 일일 시간 예산 (18시간 = 오전 6시 ~ 자정)
var time_hours_left: float = 18.0

# ── 런타임 체력 / 스태미너 (전투·훈련으로 소모, 식사·수면으로 회복)
var cur_hp:      float = 100.0   # 현재 체력
var cur_stamina: float = 100.0   # 현재 스태미너

# ── 경제
var gold:                int  = 300
var has_gym_membership:  bool = false
var gym_membership_days: int  = 0

# ── 집 장비
var home_equipment := {
	"dumbbell_set":  false,
	"treadmill":     false,
	"sandbag":       false,
	"full_home_gym": false,
}

# ── 스킬
var skill_points:    int           = 0
var unlocked_skills: Array[String] = []

# ── 전투 기록
var match_wins:   int = 0
var match_losses: int = 0

# ── 현재 경기 대상 (daily_life → combat 전달용)
var current_enemy_id:    String = ""
var current_match_type:  String = "normal"

# ── 챕터 대화 예약 (티어 승급 시 daily_life → dialogue 리디렉트용)
var next_chapter_dialogue: String = ""

# ─────────────────────────────────────────────────────────────────────────────

# ── 런타임 체력/스태미너 상한 계산
func get_hp_max() -> float:
	return maxf(1.0, float(stats.get("HP", 100.0)))

func get_stamina_max() -> float:
	# 기본 50 + STA 스탯 × 5  (STA=10 → 100, STA=50 → 300)
	return 50.0 + float(stats.get("STA", 10.0)) * 5.0

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
	gold               = 300
	has_gym_membership = false
	time_hours_left    = 18.0
	cur_hp             = get_hp_max()
	cur_stamina        = get_stamina_max()

func _get_rival_class(p_class: String) -> String:
	match p_class:
		"boxer":     return "wrestler"
		"wrestler":  return "jiu_jitsu"
		"jiu_jitsu": return "boxer"
	return ""

# ── 시간 소비
func spend_time(hours: float) -> bool:
	if time_hours_left < hours - 0.001:
		return false
	time_hours_left = maxf(0.0, time_hours_left - hours)
	time_changed.emit(time_hours_left)
	return true

# ── 이동 시간 비용 (홈짐 있으면 무료)
func get_travel_time() -> float:
	return 0.0 if home_equipment.get("full_home_gym", false) else 0.5

# ── 체력 소비 / 회복
func consume_hp(amount: float) -> void:
	cur_hp = maxf(0.0, cur_hp - amount)
	cur_hp_changed.emit(cur_hp, get_hp_max())

func restore_hp(amount: float) -> void:
	cur_hp = minf(get_hp_max(), cur_hp + amount)
	cur_hp_changed.emit(cur_hp, get_hp_max())

# ── 스태미너 소비 / 회복
func consume_stamina(amount: float) -> void:
	cur_stamina = maxf(0.0, cur_stamina - amount)
	cur_stamina_changed.emit(cur_stamina, get_stamina_max())

func restore_stamina(amount: float) -> void:
	cur_stamina = minf(get_stamina_max(), cur_stamina + amount)
	cur_stamina_changed.emit(cur_stamina, get_stamina_max())

# ── 영구 스탯 수정
func modify_stat(stat: String, delta: float) -> void:
	if not stats.has(stat):
		return
	stats[stat] = maxf(0.0, stats[stat] + delta)
	stats_changed.emit(stat, stats[stat])

# ── 하루 종료 (잠자기)
func end_day() -> void:
	_apply_stat_decay()
	# 수면 효과: 스태미너 완전 회복, 체력 30% 회복
	cur_stamina     = get_stamina_max()
	cur_hp          = minf(get_hp_max(), cur_hp + get_hp_max() * 0.3)
	time_hours_left = 18.0
	current_day    += 1
	_update_gym_membership()
	day_ended.emit(current_day)
	SaveManager.save()

func _apply_stat_decay() -> void:
	# 스태미너가 낮거나 런타임 스태미너가 소진된 경우 감소 2배
	var sta_low := stats["STA"] < Config.sta_low_threshold or cur_stamina < 10.0
	var mult := 2.0 if sta_low else 1.0
	modify_stat("STR", -Config.decay_STR * mult)
	modify_stat("AGI", -Config.decay_AGI * mult)
	modify_stat("TEC", -Config.decay_TEC * mult)

func _update_gym_membership() -> void:
	if has_gym_membership:
		gym_membership_days -= 1
		if gym_membership_days <= 0:
			has_gym_membership = false

# ── 골드
func earn_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# ── 멤버십 구매
func buy_gym_membership() -> bool:
	if not spend_gold(Config.gym_membership_cost):
		return false
	has_gym_membership = true
	gym_membership_days = Config.gym_membership_days
	return true

# ── 집 장비 구매
func buy_home_equipment(item_key: String) -> bool:
	var econ: Dictionary = GameData.economy.get("home_equipment", {})
	var item: Dictionary = econ.get(item_key, {})
	if item.is_empty():
		return false
	if not spend_gold(int(item.get("cost", 999999))):
		return false
	home_equipment[item_key] = true
	return true

# ── 스킬
func add_skill_point(amount: int = 1) -> void:
	skill_points += amount

func unlock_skill(skill_id: String) -> bool:
	if skill_points <= 0 or skill_id in unlocked_skills:
		return false
	unlocked_skills.append(skill_id)
	skill_points -= 1
	return true

# ── 경기 결과 처리
func record_match_result(won: bool, sp_gained: int, gold_gained: int, is_rival: bool) -> void:
	if won:
		match_wins += 1
		wins_this_tier += 1
		earn_gold(gold_gained)
		add_skill_point(sp_gained)
		if is_rival:
			rival_defeated_count += 1
	else:
		match_losses += 1
	match_result_recorded.emit(won, sp_gained, gold_gained)
	_check_tier_advance()

func _check_tier_advance() -> void:
	if current_tier >= 4:
		return
	var required: int = WINS_TO_ADVANCE.get(current_tier, 999)
	if wins_this_tier >= required and rival_defeated_count > (current_tier - 1):
		current_tier += 1
		wins_this_tier = 0
		tier_advanced.emit(current_tier)
		match current_tier:
			2: next_chapter_dialogue = "CH2_DLG_001"
			3: next_chapter_dialogue = "CH3_DLG_001"
			4: next_chapter_dialogue = "CH4_DLG_001"
