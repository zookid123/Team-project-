import 'dart:math';
import 'package:app_project/domain/models/character.dart';

enum SkillTriggerType {
  cooldown, // 쿨타임이 차면 자동 발동
  onHit,    // 평타 시 확률 발동
}

enum SkillEffectType {
  damage,  // 즉시 데미지
  heal,    // 회복
  buff,    // 공격력/방어력 증가
  dot,     // 지속 데미지 (독, 화상 등)
}

class Skill {
  final String id;
  final String name;
  final SkillTriggerType triggerType;
  final SkillEffectType effectType;
  double cooldownSeconds;  // cooldown 타입일 때 사용 (mutable for upgrades)
  final double triggerChance;    // onHit 타입일 때 사용 (0.0~1.0)
  double effectMultiplier; // 효과 배율 (mutable for upgrades)
  final double buffDuration;     // 버프/DoT 지속 시간 (초)

  double _cooldownTimer = 0;
  int upgradeLevel = 1; // 스킬 강화 단계

  Skill({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.effectType,
    this.cooldownSeconds = 5.0,
    this.triggerChance = 0.2,
    this.effectMultiplier = 1.5,
    this.buffDuration = 3.0,
    this.upgradeLevel = 1,
  });

  /// 쿨타임 진행. 발동 타이밍이면 true 반환
  bool tickCooldown(double dt, Character owner) {
    if (triggerType != SkillTriggerType.cooldown) return false;
    
    // 캐릭터의 쿨타임 감소율 적용 (예: 0.5 감소 시 2배 빠르게 참)
    final effectiveDt = dt / (1.0 - owner.cooldownReductionRate.clamp(0.0, 0.9));
    _cooldownTimer += effectiveDt;
    
    if (_cooldownTimer >= cooldownSeconds) {
      _cooldownTimer = 0;
      return true;
    }
    return false;
  }

  /// 쿨타임 즉시 초기화
  void resetCooldown() {
    _cooldownTimer = cooldownSeconds;
  }

  /// 쿨타임 일정 비율 감소 (0.5 = 50% 감소)
  void reduceCooldown(double ratio) {
    if (triggerType != SkillTriggerType.cooldown) return;
    _cooldownTimer += (cooldownSeconds * ratio);
    if (_cooldownTimer > cooldownSeconds) _cooldownTimer = cooldownSeconds;
  }

  /// 평타 시 확률 발동 체크
  bool checkOnHitTrigger() {
    if (triggerType != SkillTriggerType.onHit) return false;
    return Random().nextDouble() < triggerChance;
  }

  double get cooldownProgress =>
      (_cooldownTimer / cooldownSeconds).clamp(0.0, 1.0);

  // 사전 정의 스킬
  factory Skill.fireball() => Skill(
        id: 'fireball',
        name: '파이어볼',
        triggerType: SkillTriggerType.cooldown,
        effectType: SkillEffectType.damage,
        cooldownSeconds: 6.0,
        effectMultiplier: 2.5,
      );

  factory Skill.heal() => Skill(
        id: 'heal',
        name: '회복의 빛',
        triggerType: SkillTriggerType.cooldown,
        effectType: SkillEffectType.heal,
        cooldownSeconds: 10.0,
        effectMultiplier: 1.0,
      );

  factory Skill.poisonBlade() => Skill(
        id: 'poison_blade',
        name: '독날',
        triggerType: SkillTriggerType.onHit,
        effectType: SkillEffectType.dot,
        triggerChance: 0.15,
        effectMultiplier: 0.5,
        buffDuration: 3.0,
      );

  /// 킹 슬라임: 대지 강타
  factory Skill.earthSlam() => Skill(
        id: 'earth_slam',
        name: '대지 강타',
        triggerType: SkillTriggerType.cooldown,
        effectType: SkillEffectType.damage,
        cooldownSeconds: 8.0,
        effectMultiplier: 1.5,
      );

  /// 킹 슬라임: 슬라임 분열 (체력 30% 미만 시 1회성 버프)
  factory Skill.slimeSplit() => Skill(
        id: 'slime_split',
        name: '슬라임 분열',
        triggerType: SkillTriggerType.cooldown, // 로직에서 체력 체크로 제어
        effectType: SkillEffectType.buff,
        cooldownSeconds: 9999.0, // 자동 발동 방지
        effectMultiplier: 1.2, // 공격력 20% 증가
        buffDuration: 999.0, // 보스 사망 시까지 유지
      );

  /// 보스 스켈레톤: 영혼 수확 (강력한 일격 + 회복)
  factory Skill.soulReap() => Skill(
        id: 'soul_reap',
        name: '영혼 수확',
        triggerType: SkillTriggerType.cooldown,
        effectType: SkillEffectType.damage,
        cooldownSeconds: 12.0,
        effectMultiplier: 3.0,
      );

  /// 보스 스켈레톤: 뼈의 장벽 (일시적 방어력 대폭 증가)
  factory Skill.boneWall() => Skill(
        id: 'bone_wall',
        name: '뼈의 장벽',
        triggerType: SkillTriggerType.cooldown,
        effectType: SkillEffectType.buff,
        cooldownSeconds: 15.0,
        effectMultiplier: 2.0, // 방어력 2배
        buffDuration: 5.0,
      );
}
