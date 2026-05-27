extends Control

# ── 노드 참조
@onready var portrait_rect:   ColorRect = $PortraitRect
@onready var speaker_label:   Label     = $DialoguePanel/Margin/VBox/SpeakerLabel
@onready var script_label:    Label     = $DialoguePanel/Margin/VBox/ScriptLabel
@onready var btn_next:        Button    = $DialoguePanel/Margin/VBox/BtnNext
@onready var chapter_overlay: ColorRect = $ChapterOverlay
@onready var chapter_label:   Label     = $ChapterOverlay/ChapterLabel

# ── 상태
var current_id: String = ""
var _typing:    bool   = false
var _tween:     Tween  = null

# ── 챕터 종료 후 이어지는 전투 정보
const CHAPTER_COMBAT := {
	"CH1": { "enemy_id": "tier1_grunt_1",     "match_type": "normal" },
	"CH2": { "enemy_id": "tier2_grunt_1",     "match_type": "normal" },
	"CH3": { "enemy_id": "tier3_rival",       "match_type": "rival"  },
	"CH4": { "enemy_id": "tier4_rival_final", "match_type": "rival"  },
}

# ── 포트레이트 색
const PORTRAIT_COLORS := {
	"Broker": Color(0.75, 0.55, 0.15),
	"Thug":   Color(0.55, 0.12, 0.12),
	"Coach":  Color(0.25, 0.38, 0.58),
	"Rival":  Color(0.55, 0.12, 0.55),
}

# ── 화자 이름 색
const SPEAKER_COLORS := {
	"브로커": Color(1.0,  0.82, 0.35),
	"주인공": Color(0.45, 0.88, 1.0),
	"불량배": Color(1.0,  0.38, 0.38),
	"관장":   Color(0.55, 0.9,  0.55),
}

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	chapter_overlay.visible = false
	btn_next.visible        = false
	btn_next.pressed.connect(_advance)

func receive_data(data: Dictionary) -> void:
	current_id = data.get("start_id", "CH1_DLG_001")

	# 챕터 타이틀 → 논블로킹 오버레이 (대화와 동시 진행)
	if current_id.ends_with("_001"):
		var entry: Dictionary = GameData.dialogue.get(current_id, {})
		var chapter: String   = str(entry.get("chapter", ""))
		if chapter != "":
			_show_chapter_title(chapter)

	# 대화는 즉시 시작
	_load_dialogue(current_id)

# ── 챕터 타이틀 논블로킹 페이드 (대화 위에 오버레이)
func _show_chapter_title(chapter: String) -> void:
	chapter_overlay.visible    = true
	chapter_overlay.modulate.a = 0.0
	chapter_label.text         = chapter
	var tw := create_tween()
	tw.tween_property(chapter_overlay, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.0)
	tw.tween_property(chapter_overlay, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): chapter_overlay.visible = false)

# ── 대사 로드 및 표시
func _load_dialogue(id: String) -> void:
	var entry: Dictionary = GameData.dialogue.get(id, {})

	# 방어 코드: 데이터 없으면 오류 표시
	if entry.is_empty():
		push_error("Dialogue: 항목 없음 → [%s]  (data/json/dialogue.json 확인)" % id)
		speaker_label.text = "⚠️ 데이터 없음"
		script_label.text  = "대화 항목을 찾을 수 없습니다.\n[%s]" % id
		script_label.visible_characters = -1
		btn_next.visible   = true
		return

	btn_next.visible = false

	# 포트레이트 색 설정
	var portrait_str: String = str(entry.get("portrait", ""))
	var parts:        Array  = portrait_str.split("_")
	var portrait_key: String = parts[0] if parts.size() > 0 and portrait_str.length() > 0 else ""

	if portrait_key == "Player":
		match GameState.player_class:
			"boxer":     portrait_rect.color = Color(0.2, 0.4, 0.9)
			"wrestler":  portrait_rect.color = Color(0.2, 0.6, 0.2)
			"jiu_jitsu": portrait_rect.color = Color(0.6, 0.2, 0.6)
	else:
		portrait_rect.color = PORTRAIT_COLORS.get(portrait_key, Color(0.4, 0.4, 0.4))

	# 화자
	var speaker: String = str(entry.get("speaker", ""))
	speaker_label.text = speaker
	speaker_label.add_theme_color_override("font_color",
		SPEAKER_COLORS.get(speaker, Color(0.95, 0.95, 0.95)))

	# 타이핑 효과
	var script_text: String = str(entry.get("script", ""))
	_start_typewriter(script_text)

# ── 타이핑 효과
func _start_typewriter(text: String) -> void:
	script_label.text                = text
	script_label.visible_characters  = 0
	btn_next.visible                 = false
	_typing                          = true

	if _tween:
		_tween.kill()
	_tween = create_tween()
	var duration := float(text.length()) * 0.035
	_tween.tween_property(script_label, "visible_characters", text.length(), duration)
	_tween.tween_callback(_on_typing_done)

func _on_typing_done() -> void:
	_typing = false
	script_label.visible_characters = -1
	btn_next.visible = true

# ── 화면 탭/클릭 → 타이핑 즉시 완료 or 다음으로
# _unhandled_input 사용: 버튼(BtnNext)이 먼저 이벤트를 소비하므로
# 버튼 클릭 시에는 여기가 호출되지 않아 _advance() 이중 호출 방지
func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tapped = true
	elif event is InputEventScreenTouch:
		if event.pressed:
			tapped = true
	if not tapped:
		return
	get_viewport().set_input_as_handled()

	if _typing:
		if _tween:
			_tween.kill()
		_on_typing_done()
	else:
		_advance()

# ── 다음 대사로 진행
func _advance() -> void:
	var entry: Dictionary = GameData.dialogue.get(current_id, {})
	var next_id: String   = str(entry.get("next_id", ""))

	if next_id == "":
		_end_chapter()
		return

	var current_chapter: String = str(entry.get("chapter", ""))
	var next_entry: Dictionary  = GameData.dialogue.get(next_id, {})
	var next_chapter: String    = str(next_entry.get("chapter", ""))

	if next_chapter != current_chapter:
		_end_chapter()
		return

	current_id = next_id
	_load_dialogue(current_id)

# ── 챕터 종료 → 전투 씬 (챕터-적 매핑) or daily_life
func _end_chapter() -> void:
	if _tween:
		_tween.kill()

	var prefix: String          = current_id.substr(0, 3)
	var combat_data: Dictionary = CHAPTER_COMBAT.get(prefix, {})

	if not combat_data.is_empty():
		GameState.current_enemy_id   = str(combat_data.get("enemy_id",   "tier1_grunt_1"))
		GameState.current_match_type = str(combat_data.get("match_type", "normal"))
		SceneManager.go_to("combat")
	else:
		SceneManager.go_to("daily_life")
