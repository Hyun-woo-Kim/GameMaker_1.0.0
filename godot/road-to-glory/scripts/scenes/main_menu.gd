extends Control

func _ready() -> void:
	$VBox/BtnStart.pressed.connect(_on_start)
	$VBox/BtnContinue.pressed.connect(_on_continue)
	$VBox/BtnQuit.pressed.connect(_on_quit)

	# 세이브 파일 없으면 이어하기 비활성화
	$VBox/BtnContinue.disabled = not SaveManager.has_save()

func _on_start() -> void:
	SceneManager.go_to("character_select")

func _on_continue() -> void:
	if SaveManager.load_game():
		SceneManager.go_to("daily_life")
	else:
		push_warning("MainMenu: 세이브 파일 로드 실패")

func _on_quit() -> void:
	get_tree().quit()
