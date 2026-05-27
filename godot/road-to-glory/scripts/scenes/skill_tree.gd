extends Control

signal closed

@onready var title_label: Label         = $Background/VBox/TitleLabel
@onready var sp_label:    Label         = $Background/VBox/SPLabel
@onready var grid:        GridContainer = $Background/VBox/SkillGrid
@onready var btn_close:   Button        = $Background/VBox/BtnClose

func _ready() -> void:
	var pc := GameState.player_class
	title_label.text = "%s 스킬 트리" % _class_display(pc)
	_refresh_sp()
	_build_grid()
	btn_close.pressed.connect(_on_close)

func _class_display(c: String) -> String:
	match c:
		"boxer":     return "복서"
		"wrestler":  return "레슬러"
		"jiu_jitsu": return "주짓떼로"
	return c

func _refresh_sp() -> void:
	sp_label.text = "보유 SP: %d" % GameState.skill_points

func _build_grid() -> void:
	for child in grid.get_children():
		child.queue_free()

	var pc := GameState.player_class
	var skills: Dictionary = GameData.skills.get(pc, {})

	# row×3+col 순서로 정렬
	var sorted: Array = skills.values()
	sorted.sort_custom(func(a, b): return (a.row * 3 + a.col) < (b.row * 3 + b.col))

	for skill in sorted:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 82)
		btn.add_theme_font_size_override("font_size", 13)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var is_unlocked  := skill.id in GameState.unlocked_skills
		var reqs_met     := _requirements_met(skill)
		var can_unlock   := not is_unlocked and reqs_met and GameState.skill_points > 0

		btn.text = "%s\n%s" % [skill.name, _effect_text(skill.get("effect", {}))]
		btn.disabled = is_unlocked or not can_unlock

		if is_unlocked:
			btn.modulate = Color(1.0, 0.85, 0.2)
		elif reqs_met:
			btn.modulate = Color(0.3, 1.0, 0.5) if GameState.skill_points > 0 else Color(0.7, 0.9, 0.7)
		else:
			btn.modulate = Color(0.45, 0.45, 0.45)

		btn.pressed.connect(_on_skill_pressed.bind(skill.id))
		grid.add_child(btn)

func _requirements_met(skill: Dictionary) -> bool:
	for req in skill.get("requires", []):
		if not req in GameState.unlocked_skills:
			return false
	return true

func _effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = []
	for key in effect:
		match key:
			"AGI":               parts.append("AGI +%s" % effect[key])
			"STR":               parts.append("STR +%s" % effect[key])
			"STA":               parts.append("STA +%s" % effect[key])
			"TEC":               parts.append("TEC +%s" % effect[key])
			"HP":                parts.append("HP +%s" % effect[key])
			"atk_bonus":         parts.append("ATK +%.0f%%" % (effect[key] * 100))
			"dodge_bonus":       parts.append("회피 +%.0f%%" % (effect[key] * 100))
			"combo_mult":        parts.append("콤보 +%.0f%%" % (effect[key] * 100))
			"crit_mult":         parts.append("크리티컬 ×%.1f" % effect[key])
			"ko_chance":         parts.append("KO확률 +%.0f%%" % (effect[key] * 100))
			"takedown_chance":   parts.append("테이크다운 +%.0f%%" % (effect[key] * 100))
			"damage_reduce":     parts.append("피해감소 +%.0f%%" % (effect[key] * 100))
			"sub_gauge_rate":    parts.append("서브미션율 +%.0f%%" % (effect[key] * 100))
			"sub_finish_chance": parts.append("서브미션 +%.0f%%" % (effect[key] * 100))
			"counter_bonus":     parts.append("카운터 +%.0f%%" % (effect[key] * 100))
			"STA_drain":         parts.append("STA감소 %s" % effect[key])
	return ", ".join(parts)

func _on_skill_pressed(skill_id: String) -> void:
	if GameState.unlock_skill(skill_id):
		_refresh_sp()
		_build_grid()

func _on_close() -> void:
	closed.emit()
	queue_free()
