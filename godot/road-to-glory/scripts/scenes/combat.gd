extends Control

# ── 노드 참조 ─────────────────────────────────────────────────────────────────
@onready var round_label:      Label         = $RoundLabel
@onready var player_name:      Label         = $PlayerPanel/PlayerName
@onready var player_sprite:    ColorRect     = $PlayerPanel/PlayerSprite
@onready var player_hp_label:  Label         = $PlayerPanel/PlayerHPLabel
@onready var player_hp_bar:    ProgressBar   = $PlayerPanel/PlayerHPBar
@onready var player_sta_label: Label         = $PlayerPanel/PlayerSTALabel
@onready var enemy_name:       Label         = $EnemyPanel/EnemyName
@onready var enemy_sprite:     ColorRect     = $EnemyPanel/EnemySprite
@onready var enemy_hp_label:   Label         = $EnemyPanel/EnemyHPLabel
@onready var enemy_hp_bar:     ProgressBar   = $EnemyPanel/EnemyHPBar
@onready var advantage_label:  Label         = $AdvantageLabel
@onready var strategy_panel:   VBoxContainer = $StrategyPanel
@onready var combat_log:       VBoxContainer = $CombatLog
@onready var log_vbox:         VBoxContainer = $CombatLog/LogScroll/LogVBox
@onready var btn_fight:        Button        = $BtnFight
@onready var result_overlay:   ColorRect     = $ResultOverlay
@onready var result_label:     Label         = $ResultOverlay/ResultLabel
@onready var btn_continue:     Button        = $ResultOverlay/BtnContinue
# 신규 연출 노드
@onready var stats_panel:      ColorRect     = $StatsPanel
@onready var stats_grid:       GridContainer = $StatsPanel/StatContainer/Margin/VBox/StatsGrid
@onready var round_banner:     Label         = $RoundBanner

# ── 전투 데이터 ───────────────────────────────────────────────────────────────
var enemy_data:      Dictionary              = {}
var enemy_class:     String                  = ""
var match_type:      String                  = "normal"
var chosen_strategy: CombatSystem.Strategy  = CombatSystem.Strategy.BALANCED
var match_result:    CombatSystem.MatchResult = null

# 스프라이트 원본 색 (히트 플래시 복원용)
var _player_col: Color = Color.GRAY
var _enemy_col:  Color = Color(0.7, 0.15, 0.15)

# ── 상수 ──────────────────────────────────────────────────────────────────────
const CLASS_COLORS := {
	"boxer":     Color(0.2, 0.4, 0.9),
	"wrestler":  Color(0.2, 0.6, 0.2),
	"jiu_jitsu": Color(0.6, 0.2, 0.6),
}
const CLASS_NAMES := {
	"boxer": "복서", "wrestler": "레슬러", "jiu_jitsu": "주짓떼로"
}

# 직업별 공격 기술명
const ATTACKS := {
	"boxer":     ["잽", "훅", "어퍼컷", "스트레이트", "바디샷", "카운터"],
	"wrestler":  ["더블레그 태클", "클린치 타격", "업어치기", "그라운드 펀치", "니킥"],
	"jiu_jitsu": ["가드 패스", "스윕", "트라이앵글 셋업", "암바 시도", "클린치 초크"],
}

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	enemy_data  = GameData.get_enemy_stats(GameState.current_enemy_id)
	match_type  = GameState.current_match_type
	enemy_class = enemy_data.get("class", "boxer")
	if enemy_class == "RIVAL":
		enemy_class = GameState.rival_class

	_setup_ui()
	_connect_buttons()
	_show_stats_panel()   # 비동기 — 스탯 비교 → 전략 선택으로 자동 전환

func _setup_ui() -> void:
	var pc := GameState.player_class
	var ec := enemy_class

	# 플레이어 패널
	player_name.text    = "나 (%s)" % CLASS_NAMES.get(pc, pc)
	_player_col         = CLASS_COLORS.get(pc, Color.GRAY)
	player_sprite.color = _player_col
	var p_hp: float     = GameState.stats.get("HP", 100.0)
	_update_player_hp(p_hp, p_hp)
	player_sta_label.text = "STA: %.0f / %.0f" % [GameState.cur_stamina, GameState.get_stamina_max()]

	# 적 패널
	enemy_name.text    = enemy_data.get("name", "상대")
	_enemy_col         = CLASS_COLORS.get(ec, Color(0.7, 0.15, 0.15))
	enemy_sprite.color = _enemy_col
	var e_hp: float    = float(enemy_data.get("HP", 100))
	_update_enemy_hp(e_hp, e_hp)

	# 상성 표시
	var adv := GameData.get_advantage(pc, ec)
	match adv:
		"favorable":
			advantage_label.text     = "✅ 상성 유리 (+20% 데미지)"
			advantage_label.modulate = Color(0.2, 1, 0.2)
		"unfavorable":
			advantage_label.text     = "⚠️ 상성 불리 (-20% 데미지)"
			advantage_label.modulate = Color(1, 0.4, 0.4)
		_:
			advantage_label.text     = "🔵 상성 동일"
			advantage_label.modulate = Color(0.7, 0.7, 1)

	round_label.text = "스탯 비교 중..." + _type_suffix()

	# 초기 가시성
	strategy_panel.visible = false
	combat_log.visible     = false
	btn_fight.visible      = false
	round_banner.visible   = false

func _connect_buttons() -> void:
	$StrategyPanel/BtnAggressive.pressed.connect(_on_strategy.bind(CombatSystem.Strategy.AGGRESSIVE))
	$StrategyPanel/BtnBalanced.pressed.connect(_on_strategy.bind(CombatSystem.Strategy.BALANCED))
	$StrategyPanel/BtnDefensive.pressed.connect(_on_strategy.bind(CombatSystem.Strategy.DEFENSIVE))
	btn_fight.pressed.connect(_start_combat)
	btn_continue.pressed.connect(_on_continue)

# ── 스탯 비교 패널 ────────────────────────────────────────────────────────────

func _show_stats_panel() -> void:
	_build_stats_panel()
	stats_panel.visible    = true
	stats_panel.modulate.a = 0.0

	var tw_in := create_tween()
	tw_in.tween_property(stats_panel, "modulate:a", 1.0, 0.4)
	await tw_in.finished

	await get_tree().create_timer(2.2).timeout

	var tw_out := create_tween()
	tw_out.tween_property(stats_panel, "modulate:a", 0.0, 0.4)
	await tw_out.finished
	stats_panel.visible = false

	round_label.text       = "전략 선택" + _type_suffix()
	strategy_panel.visible = true

func _build_stats_panel() -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	var pc := GameState.player_class
	var ec := enemy_class

	# 헤더 행
	_stat_cell(stats_grid, "")
	_stat_cell(stats_grid, "나 (%s)" % str(CLASS_NAMES.get(pc, pc)),
		CLASS_COLORS.get(pc, Color.WHITE))
	_stat_cell(stats_grid, str(enemy_data.get("name", "상대")),
		CLASS_COLORS.get(ec, Color(0.9, 0.35, 0.35)))

	# 구분 행
	for _i in range(3):
		_stat_cell(stats_grid, "───", Color(0.38, 0.38, 0.38))

	# 스탯 비교 행
	for stat in ["STR", "AGI", "TEC", "HP"]:
		var p_val: float = GameState.stats.get(stat, 0.0)
		var e_val: float = float(enemy_data.get(stat, 10))
		var p_col := Color(0.35, 1.0, 0.45) if p_val >= e_val else Color(1.0, 0.42, 0.42)
		var e_col := Color(0.35, 1.0, 0.45) if e_val >= p_val else Color(1.0, 0.42, 0.42)
		_stat_cell(stats_grid, stat,            Color(0.82, 0.82, 0.82))
		_stat_cell(stats_grid, "%.0f" % p_val, p_col)
		_stat_cell(stats_grid, "%.0f" % e_val, e_col)

func _stat_cell(grid: GridContainer, text: String, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	grid.add_child(lbl)

# ── 전략 선택 ─────────────────────────────────────────────────────────────────

func _on_strategy(s: CombatSystem.Strategy) -> void:
	chosen_strategy = s
	var names := ["공격적", "균형", "방어적"]
	round_label.text = "전략: %s 선택됨" % names[s]
	$StrategyPanel/BtnAggressive.modulate = Color.WHITE
	$StrategyPanel/BtnBalanced.modulate   = Color.WHITE
	$StrategyPanel/BtnDefensive.modulate  = Color.WHITE
	match s:
		CombatSystem.Strategy.AGGRESSIVE: $StrategyPanel/BtnAggressive.modulate = Color(1, 0.8, 0.2)
		CombatSystem.Strategy.BALANCED:   $StrategyPanel/BtnBalanced.modulate   = Color(0.2, 1, 0.5)
		CombatSystem.Strategy.DEFENSIVE:  $StrategyPanel/BtnDefensive.modulate  = Color(0.4, 0.7, 1)
	btn_fight.visible = true

# ── 전투 시작 ─────────────────────────────────────────────────────────────────

func _start_combat() -> void:
	strategy_panel.visible = false
	btn_fight.visible      = false
	combat_log.visible     = true

	var enemy_stats_dict: Dictionary = {}
	for key in ["STR", "AGI", "STA", "TEC", "HP"]:
		enemy_stats_dict[key] = float(enemy_data.get(key, 10))

	match_result = CombatSystem.simulate_match(
		GameState.stats,
		GameState.player_class,
		enemy_stats_dict,
		enemy_class,
		chosen_strategy
	)

	await _animate_rounds()
	_show_result()

# ── 라운드 배너 플래시 ────────────────────────────────────────────────────────

func _flash_round_banner(text: String) -> void:
	round_banner.text       = text
	round_banner.modulate.a = 0.0
	round_banner.visible    = true
	var tw := create_tween()
	tw.tween_property(round_banner, "modulate:a", 1.0, 0.15)
	tw.tween_interval(0.45)
	tw.tween_property(round_banner, "modulate:a", 0.0, 0.15)
	await tw.finished
	round_banner.visible = false

# ── 라운드 애니메이션 ─────────────────────────────────────────────────────────

func _animate_rounds() -> void:
	var p_hp_start: float = GameState.stats.get("HP", 100.0)
	var e_hp_start: float = float(enemy_data.get("HP", 100))
	var p_hp := p_hp_start
	var e_hp := e_hp_start

	player_hp_bar.max_value = p_hp_start
	enemy_hp_bar.max_value  = e_hp_start

	for i in range(match_result.rounds.size()):
		var rr: CombatSystem.RoundResult = match_result.rounds[i]

		round_label.text = "라운드 %d / %d" % [i + 1, Config.combat_rounds]
		await _flash_round_banner("ROUND  %d" % (i + 1))

		# 적 공격 로그
		if rr.player_dodged:
			_add_log("🔵  슬쩍 피했다!", Color(0.4, 0.82, 1.0))
		else:
			_flash_sprite(player_sprite, _player_col)
			_add_log("⚔️  상대의 %s  →  내 HP -%d" % [
				_attack_name(enemy_class), int(rr.player_damage)
			], _dmg_color(rr.player_damage, p_hp_start))

		# 플레이어 공격 로그
		if rr.enemy_dodged:
			_add_log("🟠  상대가 회피!", Color(1.0, 0.65, 0.25))
		else:
			_flash_sprite(enemy_sprite, _enemy_col)
			_add_log("💥  %s  →  상대 HP -%d" % [
				_attack_name(GameState.player_class), int(rr.enemy_damage)
			], _dmg_color(rr.enemy_damage, e_hp_start))

		# 고유 메카닉 연출
		match rr.special_triggered:
			"combo":
				_add_log("     ✨  COMBO!  연속 타격 +10%", Color(1.0, 0.92, 0.2))
			"takedown":
				_add_log("     💪  테이크다운!  추가 타격!", Color(1.0, 0.62, 0.2))
			"submission_finish":
				_add_log("     🔒  서브미션 피니시!",        Color(0.85, 0.25, 0.95))

		# HP 차감 + 스무스 업데이트
		p_hp -= rr.player_damage
		e_hp -= rr.enemy_damage
		await _tween_hp_bars(maxf(0.0, p_hp), p_hp_start, maxf(0.0, e_hp), e_hp_start)
		await _scroll_log()

		# KO / 서브미션 조기 종료
		if match_result.finish_type in ["ko", "submission"] \
				and i == match_result.rounds.size() - 1:
			_add_log("")
			if match_result.player_won:
				_add_log("🏆  KO / 서브미션 — 승리!", Color(1.0, 0.9, 0.1))
			else:
				_add_log("💀  KO / 서브미션 — 패배...", Color(1.0, 0.3, 0.3))
			await _scroll_log()
			return

		_add_log("─── 라운드 종료 ───", Color(0.42, 0.42, 0.42))
		await get_tree().create_timer(0.35).timeout

	if match_result.finish_type == "decision":
		_add_log("")
		var won := match_result.player_won
		_add_log("⚖️  3라운드 판정 — " + ("승리!" if won else "패배..."),
			Color(1.0, 0.85, 0.3) if won else Color(1.0, 0.38, 0.38))
		await _scroll_log()

# ── 보조 함수 ─────────────────────────────────────────────────────────────────

# HP 바 동시 트윈 (0.4초)
func _tween_hp_bars(p_hp: float, p_max: float, e_hp: float, e_max: float) -> void:
	player_hp_label.text = "HP: %d / %d" % [int(p_hp), int(p_max)]
	enemy_hp_label.text  = "HP: %d / %d" % [int(e_hp), int(e_max)]
	var tw := create_tween().set_parallel()
	tw.tween_property(player_hp_bar, "value", p_hp, 0.4)
	tw.tween_property(enemy_hp_bar,  "value", e_hp, 0.4)
	await tw.finished

# 로그 스크롤 최하단
func _scroll_log() -> void:
	await get_tree().process_frame
	var scroll: ScrollContainer = $CombatLog/LogScroll
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# 로그 항목 추가
func _add_log(text: String, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_vbox.add_child(lbl)

# HP 바 즉시 업데이트 (초기화용)
func _update_player_hp(current: float, maximum: float) -> void:
	player_hp_bar.max_value = maximum
	player_hp_bar.value     = current
	player_hp_label.text    = "HP: %d / %d" % [int(current), int(maximum)]

func _update_enemy_hp(current: float, maximum: float) -> void:
	enemy_hp_bar.max_value = maximum
	enemy_hp_bar.value     = current
	enemy_hp_label.text    = "HP: %d / %d" % [int(current), int(maximum)]

# 피격 시 흰색 플래시 → 원래 색으로 복원 (논블로킹)
func _flash_sprite(sprite: ColorRect, original: Color) -> void:
	sprite.color = Color(1.0, 1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(sprite, "color", original, 0.18)

# 직업별 랜덤 공격 기술명
func _attack_name(class_id: String) -> String:
	var list: Array = ATTACKS.get(class_id, ["타격"])
	return str(list[randi() % list.size()])

# 피해량에 따른 색상 (강타=빨강, 중타=주황, 경타=흰색)
func _dmg_color(damage: float, max_hp: float) -> Color:
	if max_hp <= 0.0:
		return Color.WHITE
	var ratio := damage / max_hp
	if ratio > 0.28:
		return Color(1.0, 0.30, 0.30)
	elif ratio > 0.13:
		return Color(1.0, 0.72, 0.20)
	return Color(0.90, 0.90, 0.90)

# 경기 종류 접미사
func _type_suffix() -> String:
	match match_type:
		"rival": return " [라이벌전]"
		"boss":  return " [보스전]"
	return ""

# ── 결과 표시 ─────────────────────────────────────────────────────────────────

func _show_result() -> void:
	var won: bool      = match_result.player_won
	var is_rival: bool = bool(enemy_data.get("is_rival", false))

	var econ: Dictionary         = GameData.economy.get("match_rewards", {})
	var tier_key := "tier%d" % GameState.current_tier
	var tier_rewards: Dictionary = econ.get(tier_key, {})
	var gold_reward := 0
	var sp_reward   := 0
	match match_type:
		"normal":
			gold_reward = int(tier_rewards.get("normal_win", 100))
			sp_reward   = 0
		"rival":
			gold_reward = int(tier_rewards.get("rival_win", 200))
			sp_reward   = 1
		"boss":
			gold_reward = int(tier_rewards.get("boss_win", 300))
			sp_reward   = 2
	if not won:
		gold_reward = 0
		sp_reward   = 0

	GameState.record_match_result(won, sp_reward, gold_reward, is_rival)

	# 전투 후 체력/스태미너 소모 적용
	var total_damage_taken: float = 0.0
	for rr: CombatSystem.RoundResult in match_result.rounds:
		total_damage_taken += rr.player_damage
	var round_count: int = match_result.rounds.size()
	var hp_cost: float   = total_damage_taken * Config.combat_hp_loss_pct
	var sta_cost: float  = float(round_count) * Config.combat_sta_per_round
	GameState.consume_hp(hp_cost)
	GameState.consume_stamina(sta_cost)
	player_sta_label.text = "STA: %.0f / %.0f" % [GameState.cur_stamina, GameState.get_stamina_max()]

	result_overlay.visible    = true
	result_overlay.modulate.a = 0.0
	if won:
		result_label.text = "🏆 VICTORY!\n+%d골드  +%dSP\n❤️ -%.0f  ⚡ -%.0f" % [gold_reward, sp_reward, hp_cost, sta_cost]
		result_label.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
	else:
		result_label.text = "💀 DEFEAT...\n다시 도전하자\n❤️ -%.0f  ⚡ -%.0f" % [hp_cost, sta_cost]
		result_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	var tw := create_tween()
	tw.tween_property(result_overlay, "modulate:a", 1.0, 0.5)

func _on_continue() -> void:
	SceneManager.go_to("daily_life")
