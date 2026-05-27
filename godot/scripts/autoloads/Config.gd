## Config.gd
## 자주 수정하지 않는 게임 설정값. Godot Inspector 또는 config.cfg 파일로 수정.
## 자주 바뀌는 수치(공격력 등)는 JSON 데이터 파일에서 관리.
extends Node

# ── 전투 설정
@export var combat_rounds: int       = 3
@export var max_dodge_rate: float    = 0.40   # 최대 회피율 40% 캡
@export var dodge_coefficient: float = 0.60   # 회피율 계산 보정 계수

# ── 스탯 감소 설정
@export var decay_STR: float = 0.5
@export var decay_AGI: float = 0.7
@export var decay_TEC: float = 0.3
@export var sta_low_threshold: float = 20.0   # STA < 이 값이면 감소 2배

# ── 활력 설정
@export var vitality_max: int         = 100
@export var travel_cost_one_way: int  = 15    # 편도 이동 활력 소모
@export var action_cost_weight: int   = 20    # 웨이트 활력 소모
@export var action_cost_sparring: int = 25    # 스파링 활력 소모
@export var action_cost_run: int      = 10    # 달리기 활력 소모
@export var action_cost_parttime: int = 20    # 아르바이트 활력 소모
@export var rest_vitality_restore: int= 30    # 휴식 시 활력 회복량

# ── 경제 설정
@export var gym_membership_cost: int  = 300   # 주간 도장 멤버십
@export var gym_membership_days: int  = 7
@export var parttime_gold_min: int    = 50
@export var parttime_gold_max: int    = 100
@export var diet_cost: int            = 50    # 식단 1회 비용
@export var sparring_invite_cost_base: int = 100  # 티어1 스파링 초청 기본 비용

# ── 상성 배율
@export var advantage_mult: float    = 1.20
@export var disadvantage_mult: float = 0.80

# ── 성장 공식 설정
@export var diminishing_returns_exp: float = 0.40  # 수확 체감 지수

const CONFIG_PATH = "user://config.cfg"

func _ready() -> void:
	_load_from_file()

func _load_from_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return  # 파일 없으면 @export 기본값 사용
	combat_rounds         = cfg.get_value("combat",  "rounds",         combat_rounds)
	max_dodge_rate        = cfg.get_value("combat",  "max_dodge_rate", max_dodge_rate)
	decay_STR             = cfg.get_value("decay",   "STR",            decay_STR)
	decay_AGI             = cfg.get_value("decay",   "AGI",            decay_AGI)
	decay_TEC             = cfg.get_value("decay",   "TEC",            decay_TEC)
	vitality_max          = cfg.get_value("vitality","max",            vitality_max)
	travel_cost_one_way   = cfg.get_value("vitality","travel_one_way", travel_cost_one_way)
	gym_membership_cost   = cfg.get_value("economy", "gym_cost",       gym_membership_cost)

func save_to_file() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("combat",  "rounds",         combat_rounds)
	cfg.set_value("combat",  "max_dodge_rate", max_dodge_rate)
	cfg.set_value("decay",   "STR",            decay_STR)
	cfg.set_value("decay",   "AGI",            decay_AGI)
	cfg.set_value("decay",   "TEC",            decay_TEC)
	cfg.set_value("vitality","max",            vitality_max)
	cfg.set_value("vitality","travel_one_way", travel_cost_one_way)
	cfg.set_value("economy", "gym_cost",       gym_membership_cost)
	cfg.save(CONFIG_PATH)
