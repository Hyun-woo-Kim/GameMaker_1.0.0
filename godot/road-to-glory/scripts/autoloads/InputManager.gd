## InputManager.gd
## 터치(모바일)와 마우스 클릭(PC)을 단일 인터페이스로 통합
## 모든 씬에서 InputManager.tap / InputManager.on_tap 으로 사용
extends Node

# 탭/클릭 이벤트 신호 — 씬에서 connect해서 사용
signal tapped(position: Vector2)
signal long_pressed(position: Vector2)

# 플랫폼 감지
var is_mobile: bool = false

# 롱프레스 설정
const LONG_PRESS_DURATION := 0.6   # 초
const TAP_MAX_MOVE       := 20.0   # 픽셀 — 이보다 많이 움직이면 탭 취소

var _press_start_pos: Vector2 = Vector2.ZERO
var _press_start_time: float  = 0.0
var _pressing: bool           = false
var _long_press_fired: bool   = false

func _ready() -> void:
	# OS 기반 플랫폼 감지
	is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _input(event: InputEvent) -> void:
	# ── 터치 이벤트 (모바일)
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_press_start(event.position)
		else:
			_on_press_end(event.position)

	# ── 마우스 이벤트 (PC) — 터치 에뮬레이션과 중복 방지
	elif event is InputEventMouseButton and not is_mobile:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press_start(event.position)
			else:
				_on_press_end(event.position)

func _process(delta: float) -> void:
	if not _pressing or _long_press_fired:
		return
	_press_start_time += delta
	if _press_start_time >= LONG_PRESS_DURATION:
		_long_press_fired = true
		long_pressed.emit(_press_start_pos)

func _on_press_start(pos: Vector2) -> void:
	_pressing         = true
	_press_start_pos  = pos
	_press_start_time = 0.0
	_long_press_fired = false

func _on_press_end(pos: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false
	if _long_press_fired:
		return
	# 이동 거리가 TAP_MAX_MOVE 이내면 탭으로 인식
	if _press_start_pos.distance_to(pos) <= TAP_MAX_MOVE:
		tapped.emit(pos)

# ── 헬퍼: Button 노드에 자동으로 터치 지원 추가 (선택적 사용)
# 버튼 노드는 Godot 자체적으로 터치를 지원하므로 별도 처리 불필요.
# 이 함수는 커스텀 Area2D 등에 탭 반응이 필요할 때 사용.
static func connect_tap_to_area(area: Area2D, callable: Callable) -> void:
	InputManager.tapped.connect(func(pos):
		var space := area.get_world_2d().direct_space_state
		var params := PhysicsPointQueryParameters2D.new()
		params.position = pos
		params.collide_with_areas = true
		var results := space.intersect_point(params)
		for r in results:
			if r["collider"] == area:
				callable.call(pos)
				break
	)
