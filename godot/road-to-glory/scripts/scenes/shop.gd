extends Control

signal closed

@onready var gold_label: Label        = $Background/VBox/GoldLabel
@onready var item_list:  VBoxContainer = $Background/VBox/ItemList
@onready var feedback:   Label        = $Background/VBox/FeedbackLabel
@onready var btn_close:  Button       = $Background/VBox/BtnClose

func _ready() -> void:
	_refresh_gold()
	_build_items()
	btn_close.pressed.connect(_on_close)

func _refresh_gold() -> void:
	gold_label.text = "보유 골드: 💰 %d" % GameState.gold

func _build_items() -> void:
	# 체육관 멤버십
	var mem_status := ""
	if GameState.has_gym_membership:
		mem_status = "유효 중 (%d일 남음)" % GameState.gym_membership_days
	_add_row("🏋️ 체육관 멤버십 (7일)", 300, "gym_membership", mem_status)

	# 집 운동기구
	var equip_data: Dictionary = GameData.economy.get("home_equipment", {})
	const DISPLAY := {
		"dumbbell_set":  "🏋️ 덤벨 세트 — 집에서 웨이트 가능 (STR 훈련)",
		"treadmill":     "🏃 트레드밀 — 집에서 달리기 가능 (AGI 훈련)",
		"sandbag":       "🥊 샌드백 — 집에서 백워크 가능",
		"full_home_gym": "🏠 홈짐 풀세트 — 이동비용 0 + 모든 훈련",
	}
	for key in ["dumbbell_set", "treadmill", "sandbag", "full_home_gym"]:
		var item: Dictionary = equip_data.get(key, {})
		var cost := int(item.get("cost", 9999))
		var owned: String = "✅ 보유 중" if GameState.home_equipment.get(key, false) else ""
		_add_row(DISPLAY.get(key, key), cost, key, owned)

func _add_row(display: String, cost: int, item_key: String, status: String) -> void:
	var sep := HSeparator.new()
	item_list.add_child(sep)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = "%s  [%d골드]" % [display, cost]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(lbl)

	if status != "":
		var st := Label.new()
		st.text = status
		st.add_theme_font_size_override("font_size", 14)
		st.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		hbox.add_child(st)
	else:
		var btn := Button.new()
		btn.text = "구매"
		btn.custom_minimum_size = Vector2(80, 40)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_buy.bind(item_key, cost, btn))
		hbox.add_child(btn)

	item_list.add_child(hbox)

func _on_buy(item_key: String, cost: int, btn: Button) -> void:
	var ok := false
	if item_key == "gym_membership":
		ok = GameState.buy_gym_membership()
	else:
		ok = GameState.buy_home_equipment(item_key)

	if ok:
		btn.text = "✅"
		btn.disabled = true
		_refresh_gold()
		_show_feedback("구매 완료! 💰 -%d골드" % cost)
	else:
		_show_feedback("골드가 부족합니다! (필요: %d골드)" % cost)

func _on_close() -> void:
	closed.emit()
	queue_free()

func _show_feedback(msg: String) -> void:
	feedback.text = msg
	feedback.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(feedback, "modulate:a", 0.0, 0.4)
