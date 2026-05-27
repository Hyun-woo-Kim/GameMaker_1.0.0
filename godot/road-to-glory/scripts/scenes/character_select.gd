extends Control

# ══════════════════════════════════════════════════════════════════
# 전투 직통 테스트 플래그
# true  → 클래스 선택 즉시 전투 씬 (대화·데일리라이프 스킵)
# false → 정식 흐름 (대화 → 전투 → 데일리라이프)
const DEBUG_COMBAT_DIRECT := true
const DEBUG_ENEMY_ID      := "tier1_grunt_1"   # 테스트할 적 ID
const DEBUG_MATCH_TYPE    := "normal"
# ══════════════════════════════════════════════════════════════════

# 중복 선택 방지 (버튼 + 카드 gui_input 이중 발화 차단)
var _selected := false

# 카드 노드 → 직업 ID 매핑
const CLASS_MAP := {
	"BoxerCard":    "boxer",
	"WrestlerCard": "wrestler",
	"JiuJitsuCard": "jiu_jitsu",
}

func _ready() -> void:
	# 각 카드의 선택 버튼에 연결
	for card_name in CLASS_MAP.keys():
		var class_id: String = CLASS_MAP[card_name]
		var btn: Button      = get_node("ClassContainer/%s/VBox/BtnSelect" % card_name)
		btn.pressed.connect(_on_class_selected.bind(class_id))

		# 카드 전체 탭도 터치로 반응하게
		var card: Control = get_node("ClassContainer/" + card_name)
		card.gui_input.connect(_on_card_input.bind(class_id))

func _on_card_input(event: InputEvent, class_id: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_on_class_selected(class_id)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_class_selected(class_id)

func _on_class_selected(class_id: String) -> void:
	if _selected:
		return
	_selected = true
	GameState.setup(class_id)

	if DEBUG_COMBAT_DIRECT:
		# ── 전투 직통 (테스트용) ──────────────────────────────
		GameState.current_enemy_id   = DEBUG_ENEMY_ID
		GameState.current_match_type = DEBUG_MATCH_TYPE
		SceneManager.go_to("combat")
	else:
		# ── 정식 흐름: 챕터1 대화 → 전투 → 데일리라이프 ────────
		SceneManager.go_to("dialogue", {"start_id": "CH1_DLG_001"})
