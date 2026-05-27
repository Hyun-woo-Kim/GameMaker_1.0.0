## SceneManager.gd
## 씬 전환을 관리하는 싱글톤 — 페이드 인/아웃 포함
extends Node

signal scene_changed(scene_name: String)

const SCENES := {
	"main_menu":       "res://scenes/main_menu.tscn",
	"character_select":"res://scenes/character_select.tscn",
	"dialogue":        "res://scenes/dialogue.tscn",
	"daily_life":      "res://scenes/daily_life.tscn",
	"combat":          "res://scenes/combat.tscn",
}

var _current_scene: String = ""
var _transition_overlay: ColorRect = null
var _transitioning: bool = false   # 전환 중 중복 호출 방지

func _ready() -> void:
	# 페이드용 오버레이 생성
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color.BLACK
	_transition_overlay.modulate.a = 0.0
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.z_index = 100
	add_child(_transition_overlay)

func go_to(scene_key: String, data: Dictionary = {}) -> void:
	if _transitioning:
		return  # 전환 중 중복 호출 무시
	if not SCENES.has(scene_key):
		push_error("SceneManager: 알 수 없는 씬 키 → " + scene_key)
		return
	_transition_to(SCENES[scene_key], scene_key, data)

func _transition_to(path: String, key: String, data: Dictionary) -> void:
	_transitioning = true

	# 페이드 아웃
	var tween := create_tween()
	tween.tween_property(_transition_overlay, "modulate:a", 1.0, 0.25)
	await tween.finished

	get_tree().change_scene_to_file(path)
	_current_scene = key

	# 씬 로드 후 데이터 전달
	await get_tree().process_frame
	await get_tree().process_frame  # 씬 _ready() 완료 보장
	var root_scene := get_tree().current_scene
	if root_scene and root_scene.has_method("receive_data"):
		root_scene.receive_data(data)

	# 페이드 인
	var tween2 := create_tween()
	tween2.tween_property(_transition_overlay, "modulate:a", 0.0, 0.25)
	await tween2.finished
	_transitioning = false
	scene_changed.emit(key)

func get_current() -> String:
	return _current_scene
