## combat_system.gd
## 전투 데미지 계산, 상성 적용, 라운드 진행을 담당하는 시스템
extends RefCounted
class_name CombatSystem

enum Strategy { AGGRESSIVE, BALANCED, DEFENSIVE }

# 전투 결과를 담는 구조체
class RoundResult:
	var player_damage: float = 0.0
	var enemy_damage:  float = 0.0
	var player_dodged: bool  = false
	var enemy_dodged:  bool  = false
	var special_triggered: String = ""  # 고유 메카닉 발동명

class MatchResult:
	var player_won: bool = false
	var rounds: Array[RoundResult] = []
	var player_hp_remaining: float = 0.0
	var enemy_hp_remaining:  float = 0.0
	var finish_type: String = "decision"  # "ko" | "submission" | "decision"

# ─────────────────────────────────────────────────────────────────────────────

static func simulate_match(
		player_stats: Dictionary,
		player_class: String,
		enemy_stats: Dictionary,
		enemy_class: String,
		player_strategy: Strategy = Strategy.BALANCED
) -> MatchResult:

	var result := MatchResult.new()
	var p_hp: float = player_stats.get("HP", 100.0)
	var e_hp: float = enemy_stats.get("HP", 100.0)

	var advantage := GameData.get_advantage(player_class, enemy_class)
	var advantage_mult := GameData.get_class_advantage_mult(advantage)
	var disadvantage_mult := GameData.get_class_advantage_mult(
		GameData.get_advantage(enemy_class, player_class)
	)

	for round_num in range(Config.combat_rounds):
		if p_hp <= 0 or e_hp <= 0:
			break

		var round_result := _simulate_round(
			player_stats, player_class, advantage_mult, player_strategy,
			enemy_stats,  enemy_class,  disadvantage_mult
		)
		result.rounds.append(round_result)

		p_hp -= round_result.enemy_damage
		e_hp -= round_result.player_damage

		# KO 체크
		if p_hp <= 0:
			result.finish_type = "ko"
			break
		if e_hp <= 0:
			result.finish_type = "ko"
			break

		# 서브미션 체크 (주짓떼로 전용)
		if round_result.special_triggered == "submission_finish":
			result.finish_type = "submission"
			e_hp = 0.0
			break

	result.player_hp_remaining = maxf(0.0, p_hp)
	result.enemy_hp_remaining  = maxf(0.0, e_hp)
	result.player_won = p_hp > e_hp
	return result


static func _simulate_round(
		p_stats: Dictionary, p_class: String, p_adv_mult: float, strategy: Strategy,
		e_stats: Dictionary, e_class: String, e_adv_mult: float
) -> RoundResult:

	var r := RoundResult.new()

	# 전략 배율
	var p_atk_mult: float
	var p_def_mult: float
	match strategy:
		Strategy.AGGRESSIVE: p_atk_mult = 1.15; p_def_mult = 0.85
		Strategy.DEFENSIVE:  p_atk_mult = 0.85; p_def_mult = 1.15
		_:                   p_atk_mult = 1.00; p_def_mult = 1.00

	# 기본 공격력 계산
	var p_atk := _calc_atk(p_stats, p_class) * p_adv_mult * p_atk_mult
	var e_atk := _calc_atk(e_stats, e_class) * e_adv_mult  # 적은 항상 balanced

	# 크리티컬 판정
	if randf() < _crit_chance(p_stats):
		p_atk *= 1.5
	if randf() < _crit_chance(e_stats):
		e_atk *= 1.5

	# 회피 판정
	r.player_dodged = randf() < _dodge_rate(p_stats, e_stats)
	r.enemy_dodged  = randf() < _dodge_rate(e_stats, p_stats)

	r.player_damage = 0.0 if r.player_dodged else e_atk * p_def_mult
	r.enemy_damage  = 0.0 if r.enemy_dodged  else p_atk

	# 직업 고유 메카닉
	r.special_triggered = _check_special(p_class, p_stats, r)

	return r


static func _calc_atk(stats: Dictionary, class_id: String) -> float:
	var str_val := float(stats.get("STR", 10))
	var tec_val := float(stats.get("TEC", 10))
	var job_mult := _get_job_mult(class_id, stats)
	return (str_val * 1.5 + tec_val * 0.5) * job_mult


static func _get_job_mult(class_id: String, stats: Dictionary) -> float:
	match class_id:
		"boxer":
			# 복서: AGI 보너스 (빠른 공격 횟수)
			var agi_bonus := float(stats.get("AGI", 10)) / 100.0 * 0.2
			return 1.0 + agi_bonus
		"wrestler":
			return 1.1  # STR 비중 높음
		"jiu_jitsu":
			return 0.9  # 서브미션 게이지로 보완
	return 1.0


static func _crit_chance(stats: Dictionary) -> float:
	return float(stats.get("TEC", 10)) / 200.0


static func _dodge_rate(defender: Dictionary, attacker: Dictionary) -> float:
	var def_agi := float(defender.get("AGI", 10))
	var att_agi := float(attacker.get("AGI", 10))
	var rate := def_agi / (def_agi + att_agi) * Config.dodge_coefficient
	return minf(rate, Config.max_dodge_rate)


static func _check_special(class_id: String, stats: Dictionary, r: RoundResult) -> String:
	match class_id:
		"boxer":
			# 콤보 카운터: 회피 안 당했을 때 데미지 10% 추가
			if not r.enemy_dodged:
				r.enemy_damage *= 1.1
			return "combo"
		"wrestler":
			# 테이크다운: 15% 확률로 추가 타격
			if randf() < 0.15:
				r.enemy_damage += float(stats.get("STR", 10)) * 0.5
				return "takedown"
		"jiu_jitsu":
			# 서브미션 게이지: TEC 기반 누적 (간이 구현)
			var finish_chance := float(stats.get("TEC", 10)) / 300.0
			if randf() < finish_chance:
				return "submission_finish"
	return ""
