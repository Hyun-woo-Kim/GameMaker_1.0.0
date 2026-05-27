extends Control

# ── 노드 참조
@onready var lbl_day:      Label       = $HUD/HBoxHUD/LblDay
@onready var lbl_tier:     Label       = $HUD/HBoxHUD/LblTier
@onready var lbl_gold:     Label       = $HUD/HBoxHUD/LblGold
@onready var lbl_time:     Label       = $HUD/HBoxHUD/LblTime
@onready var lbl_cur_hp:   Label       = $HUD/HBoxHUD/LblCurHP
@onready var lbl_cur_sta:  Label       = $HUD/HBoxHUD/LblCurSTA
@onready var lbl_location: Label       = $ActionPanel/LocationLabel
@onready var btn_go_home:  Button      = $ActionPanel/LocationButtons/BtnGoHome
@onready var btn_go_gym:   Button      = $ActionPanel/LocationButtons/BtnGoGym
@onready var lbl_sp:       Label       = $RightPanel/RightVBox/LblSP
@onready var feedback:     Label       = $FeedbackLabel

# 스탯 바 참조
@onready var pb_str: ProgressBar = $StatPanel/StatVBox/BarSTR/PBstr
@onready var pb_agi: ProgressBar = $StatPanel/StatVBox/BarAGI/PBagi
@onready var pb_sta: ProgressBar = $StatPanel/StatVBox/BarSTA/PBsta
@onready var pb_tec: ProgressBar = $StatPanel/StatVBox/BarTEC/PBtec
@onready var pb_hp:  ProgressBar = $StatPanel/StatVBox/BarHP/PBhp
@onready var lbl_str: Label = $StatPanel/StatVBox/BarSTR/LblSTR
@onready var lbl_agi: Label = $StatPanel/StatVBox/BarAGI/LblAGI
@onready var lbl_sta: Label = $StatPanel/StatVBox/BarSTA/LblSTA
@onready var lbl_tec: Label = $StatPanel/StatVBox/BarTEC/LblTEC
@onready var lbl_hp:  Label = $StatPanel/StatVBox/BarHP/LblHP

# 경기 선택 오버레이 참조
@onready var match_picker:    ColorRect = $MatchPicker
@onready var match_info_lbl:  Label     = $MatchPicker/PickerPanel/VBox/InfoLabel
@onready var btn_normal:      Button    = $MatchPicker/PickerPanel/VBox/BtnNormal
@onready var btn_rival:       Button    = $MatchPicker/PickerPanel/VBox/BtnRival
@onready var btn_boss:        Button    = $MatchPicker/PickerPanel/VBox/BtnBoss
@onready var btn_cancel:      Button    = $MatchPicker/PickerPanel/VBox/BtnCancel

# 팝업 씬 프리로드
const SKILL_TREE_SCENE := preload("res://scenes/skill_tree.tscn")
const SHOP_SCENE       := preload("res://scenes/shop.tscn")

# 티어별 적 목록
const TIER_ENEMIES := {
	1: {
		"normal": ["tier1_grunt_1", "tier1_grunt_2", "tier1_grunt_3"],
		"rival":  "tier1_rival",
		"boss":   "tier1_boss",
	},
	2: {
		"normal": ["tier2_grunt_1", "tier2_grunt_2", "tier2_grunt_3", "tier2_grunt_4"],
		"rival":  "tier2_rival",
		"boss":   "tier2_boss",
	},
	3: {
		"normal": ["tier3_grunt_1", "tier3_grunt_2", "tier3_grunt_3", "tier3_grunt_4", "tier3_grunt_5"],
		"rival":  "tier3_rival",
		"boss":   "tier3_boss",
	},
	4: {
		"normal": ["tier4_defense_1", "tier4_defense_2"],
		"rival":  "tier4_rival_final",
		"boss":   "",
	},
}

enum Location { HOME, GYM }
var current_location: Location = Location.HOME

# 오늘 행동 로그 (슬롯 제한 없음 — 시간·스태미너로 자연 제한)
var actions_today: Array[String] = []

var slot_labels: Array = []

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	slot_labels = [
		$RightPanel/RightVBox/SlotList/Slot1,
		$RightPanel/RightVBox/SlotList/Slot2,
		$RightPanel/RightVBox/SlotList/Slot3,
	]
	_connect_buttons()
	_connect_signals()
	_refresh_all()

	# 티어 승급으로 예약된 챕터 대화가 있으면 즉시 해당 챕터로 이동
	if GameState.next_chapter_dialogue != "":
		var dlg_id: String = GameState.next_chapter_dialogue
		GameState.next_chapter_dialogue = ""
		SceneManager.go_to("dialogue", {"start_id": dlg_id})
		return

func _connect_buttons() -> void:
	btn_go_home.pressed.connect(_on_go_home)
	btn_go_gym.pressed.connect(_on_go_gym)

	$ActionPanel/ActionGrid/BtnBench.pressed.connect(_do_action.bind(VitalitySystem.ActionType.BENCH_PRESS, "벤치프레스"))
	$ActionPanel/ActionGrid/BtnSquat.pressed.connect(_do_action.bind(VitalitySystem.ActionType.SQUAT, "스쿼트"))
	$ActionPanel/ActionGrid/BtnDeadlift.pressed.connect(_do_action.bind(VitalitySystem.ActionType.DEADLIFT, "데드리프트"))
	$ActionPanel/ActionGrid/BtnTreadmill.pressed.connect(_do_action.bind(VitalitySystem.ActionType.TREADMILL, "런닝머신"))
	$ActionPanel/ActionGrid/BtnSpar.pressed.connect(_on_sparring)
	$ActionPanel/ActionGrid/BtnDiet.pressed.connect(_do_action.bind(VitalitySystem.ActionType.DIET, "식사"))
	$ActionPanel/ActionGrid/BtnEnergyDrink.pressed.connect(_do_action.bind(VitalitySystem.ActionType.ENERGY_DRINK, "에너지 드링크"))
	$ActionPanel/ActionGrid/BtnPartTime.pressed.connect(_do_action.bind(VitalitySystem.ActionType.PARTTIME_JOB, "아르바이트"))
	$ActionPanel/ActionGrid/BtnRest.pressed.connect(_do_action.bind(VitalitySystem.ActionType.REST, "휴식"))

	$ActionPanel/BtnEndDay.pressed.connect(_on_end_day)
	$RightPanel/RightVBox/BtnSkillTree.pressed.connect(_on_skill_tree)
	$RightPanel/RightVBox/BtnShop.pressed.connect(_on_shop)
	$RightPanel/RightVBox/BtnMatch.pressed.connect(_on_match_open)

	btn_normal.pressed.connect(_on_match_normal)
	btn_rival.pressed.connect(_on_match_rival)
	btn_boss.pressed.connect(_on_match_boss)
	btn_cancel.pressed.connect(func(): match_picker.visible = false)

func _connect_signals() -> void:
	GameState.stats_changed.connect(_on_stat_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.time_changed.connect(_on_time_changed)
	GameState.cur_hp_changed.connect(_on_cur_hp_changed)
	GameState.cur_stamina_changed.connect(_on_cur_sta_changed)
	GameState.tier_advanced.connect(_on_tier_advanced)

# ── 위치 이동
func _on_go_home() -> void:
	if current_location == Location.HOME:
		_show_feedback("이미 집에 있습니다.")
		return
	var cost: float = GameState.get_travel_time()
	if cost > 0.0 and not GameState.spend_time(cost):
		_show_feedback("시간이 부족합니다!")
		return
	current_location = Location.HOME
	_refresh_location()
	_show_feedback("집으로 이동. " + ("(%.1f시간 소모)" % cost if cost > 0.0 else "(홈짐 — 무료)"))

func _on_go_gym() -> void:
	if current_location == Location.GYM:
		_show_feedback("이미 체육관에 있습니다.")
		return
	if not GameState.has_gym_membership:
		_show_feedback("체육관 멤버십이 필요합니다! (상점에서 구매, 300골드)")
		return
	var cost: float = GameState.get_travel_time()
	if cost > 0.0 and not GameState.spend_time(cost):
		_show_feedback("시간이 부족합니다!")
		return
	current_location = Location.GYM
	_refresh_location()
	_show_feedback("체육관으로 이동. " + ("(%.1f시간 소모)" % cost if cost > 0.0 else ""))

func _refresh_location() -> void:
	lbl_location.text = "📍 현재 위치: " + ("집" if current_location == Location.HOME else "체육관")
	btn_go_home.disabled = current_location == Location.HOME
	btn_go_gym.disabled  = current_location == Location.GYM

	var at_gym: bool          = current_location == Location.GYM
	var has_weights: bool     = GameState.home_equipment.get("dumbbell_set",  false) \
	                         or GameState.home_equipment.get("full_home_gym", false)
	var has_treadmill: bool   = GameState.home_equipment.get("treadmill",     false) \
	                         or GameState.home_equipment.get("full_home_gym", false)

	$ActionPanel/ActionGrid/BtnBench.disabled    = not (at_gym or has_weights)
	$ActionPanel/ActionGrid/BtnSquat.disabled    = not (at_gym or has_weights)
	$ActionPanel/ActionGrid/BtnDeadlift.disabled = not (at_gym or has_weights)
	$ActionPanel/ActionGrid/BtnTreadmill.disabled = not (at_gym or has_treadmill)
	$ActionPanel/ActionGrid/BtnSpar.disabled     = not at_gym

# ── 행동 실행
func _do_action(action_type: VitalitySystem.ActionType, action_name: String) -> void:
	var result := VitalitySystem.perform(action_type)
	if result.success:
		# 잠자기 신호 처리
		if result.message == "SLEEP":
			_on_end_day()
			return
		actions_today.append(action_name)
		_update_slots()
		_refresh_hud()
		_show_feedback(result.message)
	else:
		_show_feedback("❌ " + result.message)

func _on_sparring() -> void:
	var tier_key := "tier%d" % GameState.current_tier
	var cost: int = GameData.economy.get("sparring_invite", {}).get(tier_key, 200)
	if not GameState.spend_gold(cost):
		_show_feedback("골드가 부족합니다! (스파링 초청비: %d골드)" % cost)
		return
	_do_action(VitalitySystem.ActionType.SPARRING, "스파링 (-%d골드)" % cost)

func _on_end_day() -> void:
	GameState.end_day()
	actions_today.clear()
	_update_slots()
	current_location = Location.HOME
	_refresh_all()
	_show_feedback("💤 Day %d 시작! 수면으로 스태미너 완전 회복, 체력 30%% 회복." % GameState.current_day)

# ── 팝업: 스킬 트리
func _on_skill_tree() -> void:
	var st := SKILL_TREE_SCENE.instantiate()
	add_child(st)

# ── 팝업: 상점
func _on_shop() -> void:
	var shop := SHOP_SCENE.instantiate()
	add_child(shop)
	shop.closed.connect(_on_shop_closed)

func _on_shop_closed() -> void:
	_refresh_all()

# ── 경기 신청 오버레이
func _on_match_open() -> void:
	var tier := GameState.current_tier
	var tier_data: Dictionary = TIER_ENEMIES.get(tier, {})
	var rival_id: String = tier_data.get("rival", "")
	var boss_id:  String = tier_data.get("boss",  "")
	btn_rival.disabled = rival_id.is_empty()
	var rival_beaten := GameState.rival_defeated_count > (tier - 1)
	btn_boss.disabled  = boss_id.is_empty() or not rival_beaten
	var req: int = GameState.WINS_TO_ADVANCE.get(tier, 999)
	match_info_lbl.text = "이번 티어 승리: %d / 라이벌 격파: %s\n%s" % [
		GameState.wins_this_tier,
		("✅" if rival_beaten else "❌"),
		("보스전 가능!" if rival_beaten and not boss_id.is_empty() else ""),
	]
	match_picker.visible = true

func _on_match_normal() -> void:
	var tier := GameState.current_tier
	var tier_data: Dictionary = TIER_ENEMIES.get(tier, {})
	var grunts: Array = tier_data.get("normal", [])
	if grunts.is_empty():
		_show_feedback("대전 상대가 없습니다.")
		match_picker.visible = false
		return
	GameState.current_enemy_id   = grunts[randi() % grunts.size()]
	GameState.current_match_type = "normal"
	match_picker.visible = false
	SceneManager.go_to("combat")

func _on_match_rival() -> void:
	var tier := GameState.current_tier
	var rival_id: String = TIER_ENEMIES.get(tier, {}).get("rival", "")
	if rival_id.is_empty():
		return
	GameState.current_enemy_id   = rival_id
	GameState.current_match_type = "rival"
	match_picker.visible = false
	SceneManager.go_to("combat")

func _on_match_boss() -> void:
	var tier := GameState.current_tier
	var boss_id: String = TIER_ENEMIES.get(tier, {}).get("boss", "")
	if boss_id.is_empty():
		return
	GameState.current_enemy_id   = boss_id
	GameState.current_match_type = "boss"
	match_picker.visible = false
	SceneManager.go_to("combat")

# ── UI 갱신
func _refresh_all() -> void:
	_refresh_hud()
	_refresh_stats()
	_refresh_location()
	lbl_sp.text = "스킬 포인트: %d" % GameState.skill_points

func _refresh_hud() -> void:
	lbl_day.text  = "Day %d" % GameState.current_day
	lbl_gold.text = "💰 %d" % GameState.gold
	const TIER_NAMES := ["", "길거리 파이터", "KFC 파이터", "UFC 파이터", "UFC 챔피언"]
	lbl_tier.text = TIER_NAMES[clamp(GameState.current_tier, 1, 4)]
	_update_time_label()
	_update_cur_hp_label()
	_update_cur_sta_label()

func _update_time_label() -> void:
	var h: float    = GameState.time_hours_left
	var full_h: int = int(h)
	var mins: int   = int((h - float(full_h)) * 60.0)
	lbl_time.text   = "⏰ %dh %02dm" % [full_h, mins]

func _update_cur_hp_label() -> void:
	var cur: float = GameState.cur_hp
	var mx: float  = GameState.get_hp_max()
	lbl_cur_hp.text = "❤️ %.0f/%.0f" % [cur, mx]

func _update_cur_sta_label() -> void:
	var cur: float = GameState.cur_stamina
	var mx: float  = GameState.get_stamina_max()
	lbl_cur_sta.text = "⚡ %.0f/%.0f" % [cur, mx]

func _refresh_stats() -> void:
	_set_stat_bar(pb_str, lbl_str, "STR", "힘 (STR)",      100)
	_set_stat_bar(pb_agi, lbl_agi, "AGI", "민첩 (AGI)",    100)
	_set_stat_bar(pb_sta, lbl_sta, "STA", "스태미나 (STA)", 100)
	_set_stat_bar(pb_tec, lbl_tec, "TEC", "기술 (TEC)",    100)
	_set_stat_bar(pb_hp,  lbl_hp,  "HP",  "체력 (HP)",     400)

func _set_stat_bar(bar: ProgressBar, lbl: Label, key: String, display: String, max_val: int) -> void:
	var v: float = GameState.stats.get(key, 0.0)
	bar.max_value = max_val
	bar.value     = v
	lbl.text      = "%s  %.0f" % [display, v]

func _update_slots() -> void:
	# 최근 3개 행동 표시 (슬롯은 행동 로그 역할)
	var count := actions_today.size()
	for i in range(slot_labels.size()):
		var log_idx: int = count - slot_labels.size() + i
		if log_idx >= 0 and log_idx < count:
			slot_labels[i].text = "[ %d ] %s" % [log_idx + 1, actions_today[log_idx]]
		else:
			slot_labels[i].text = "—"

# ── 시그널 핸들러
func _on_stat_changed(_stat: String, _val: float) -> void:
	_refresh_stats()

func _on_gold_changed(val: int) -> void:
	lbl_gold.text = "💰 %d" % val

func _on_time_changed(_hours: float) -> void:
	_update_time_label()

func _on_cur_hp_changed(_val: float, _max: float) -> void:
	_update_cur_hp_label()

func _on_cur_sta_changed(_val: float, _max: float) -> void:
	_update_cur_sta_label()

func _on_tier_advanced(new_tier: int) -> void:
	const TIER_NAMES := ["", "길거리 파이터", "KFC 파이터", "UFC 파이터", "UFC 챔피언"]
	_show_feedback("🎉 티어 승급! → %s" % TIER_NAMES[clamp(new_tier, 1, 4)])
	_refresh_hud()

# ── 피드백 애니메이션
func _show_feedback(msg: String) -> void:
	feedback.text = msg
	feedback.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(feedback, "modulate:a", 0.0, 0.5)
