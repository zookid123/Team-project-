import 'dart:math';
import 'package:app_project/domain/models/character.dart';
import 'package:app_project/domain/models/skill.dart';
import 'package:app_project/domain/models/card_reward.dart';

class BattleLog {
  final String message;
  final bool isSkill;
  final bool isCritical;

  BattleLog(this.message, {this.isSkill = false, this.isCritical = false});
}

enum BattlePhase {
  fighting,   // 전투 중
  cardSelect, // 카드 선택 (일반 몬스터 처치 후)
  startCardSelect, // 전투 시작 전 카드 선택
  victory,    // 보스 처치 → 런 승리
  defeat,     // 플레이어 사망 → 런 패배
}

class DungeonRun {
  final String stageId;
  final List<Character> monsterWave;
  int currentMonsterIndex = 0;
  final int initialCardPicks; // 시작 시 카드 선택 횟수

  DungeonRun({
    required this.stageId, 
    required this.monsterWave,
    this.initialCardPicks = 0,
  });

  Character? get currentMonster =>
      currentMonsterIndex < monsterWave.length
          ? monsterWave[currentMonsterIndex]
          : null;

  bool get isBossWave => currentMonsterIndex == monsterWave.length - 1;

  bool nextMonster() {
    currentMonsterIndex++;
    return currentMonsterIndex < monsterWave.length;
  }

  /// 스테이지 1-1: 슬라임 → 슬라임 → 슬라임 보스
  factory DungeonRun.stage1_1() => DungeonRun(
        stageId: '1-1',
        monsterWave: [
          Character.slime(),
          Character.slime(),
          Character.slimeBoss(),
        ],
      );

  /// 스테이지 1-2: 슬라임1 → 슬라임2 → 슬라임2 → 슬라임 보스
  factory DungeonRun.stage1_2() => DungeonRun(
        stageId: '1-2',
        monsterWave: [
          Character.slime(),
          Character.slime2(),
          Character.slime2(),
          Character.slimeBoss(),
        ],
      );

  /// 스테이지 1-3: 킹 슬라임 단독 보스전
  factory DungeonRun.stage1_3() => DungeonRun(
        stageId: '1-3',
        monsterWave: [
          Character.kingSlime(),
        ],
        initialCardPicks: 3,
      );

  /// 스테이지 2-1: 어두운 해골 던전
  factory DungeonRun.stage2_1() => DungeonRun(
        stageId: '2-1',
        monsterWave: [
          Character.skeleton(),
          Character.skeleton(),
          Character.skeletonBoss(),
        ],
      );
}

class BattleEngine {
  final Character player;
  final DungeonRun run;
  int remainingInitialPicks = 0; // 남은 시작 카드 선택 횟수

  // 애니메이션을 위한 콜백
  void Function()? onPlayerAttack;
  void Function()? onMonsterAttack;
  void Function(String skillId)? onSkillCast;
  void Function(String stageId)? onVictory;

  BattlePhase phase = BattlePhase.fighting;
  List<BattleLog> logs = [];
  List<CardReward> currentCards = [];
  List<CardReward> appliedCards = [];
  final Set<String> selectedCardIds = {};

  // 그래프를 위한 피해량 기록 (최근 30초)
  final List<DamagePoint> damageDealtHistory = [];
  final List<DamagePoint> damageTakenHistory = [];
  double totalElapsedSeconds = 0;

  // 신규 특수 효과용 상태
  double _firstMoveTimer = 0;
  double _wheelOfFateTimer = 0;
  double _wheelOfFateCooldown = 10.0;
  String? _activeWheelEffect;

  BattleEngine({required this.player, required this.run}) {
    remainingInitialPicks = run.initialCardPicks + player.relicStartCardBonus;
    if (remainingInitialPicks > 0) {
      phase = BattlePhase.startCardSelect;
      currentCards = CardReward.drawThree(excludeIds: selectedCardIds);
    }
  }

  Character? get currentMonster => run.currentMonster;

  void _startNextWave() {
    _firstMoveTimer = player.hasFirstMove ? 5.0 : 0;
    player.precisionShootingBonus = 0;
    _wheelOfFateCooldown = 10.0;
    _wheelOfFateTimer = 0;
    _activeWheelEffect = null;
  }

  /// 매 프레임 호출 (dt: 경과 시간 초 단위)
  void tick(double dt) {
    if (phase != BattlePhase.fighting) return;

    totalElapsedSeconds += dt;
    _cleanupHistory();

    // 0. 특수 효과 타이머
    if (_firstMoveTimer > 0) _firstMoveTimer -= dt;
    if (player.hasWheelOfFate) {
      _wheelOfFateCooldown -= dt;
      if (_wheelOfFateCooldown <= 0) {
        _wheelOfFateCooldown = 10.0;
        _wheelOfFateTimer = 5.0;
        final r = Random().nextInt(3);
        if (r == 0) {
          _activeWheelEffect = 'attack';
          player.addBuff(ActiveBuff(name: '운명의 수레바퀴(공격)', attackMultiplier: 2.0, remainingSeconds: 5.0));
          _log('🎡 운명의 수레바퀴: 공격력 2배!');
        } else if (r == 1) {
          _activeWheelEffect = 'defense';
          player.addBuff(ActiveBuff(name: '운명의 수레바퀴(방어)', defenseMultiplier: 2.0, remainingSeconds: 5.0));
          _log('🎡 운명의 수레바퀴: 방어력 2배!');
        } else {
          _activeWheelEffect = 'heal';
          _log('🎡 운명의 수레바퀴: 재생!');
        }
      }
      if (_wheelOfFateTimer > 0) {
        _wheelOfFateTimer -= dt;
        if (_activeWheelEffect == 'heal') {
          player.heal(player.maxHp * 0.1 * dt);
        }
        if (_wheelOfFateTimer <= 0) _activeWheelEffect = null;
      }
    }

    final monster = currentMonster;
    if (monster == null) return;

    // 1. DoT/버프 틱
    final playerDot = player.tickEffects(dt);
    final monsterDot = monster.tickEffects(dt);
    if (playerDot > 0) _log('플레이어가 지속 피해 ${playerDot.toStringAsFixed(1)}를 받았습니다.');
    if (monsterDot > 0) _log('${monster.name}이(가) 지속 피해 ${monsterDot.toStringAsFixed(1)}를 받았습니다.');

    // 2. 플레이어 평타
    double playerSpeedMult = 1.0;
    if (_firstMoveTimer > 0) playerSpeedMult += 0.5;
    if (player.hasOverload) playerSpeedMult += 1.0;

    if (player.tickAttack(dt, speedMultiplier: playerSpeedMult)) {
      _doAttack(attacker: player, target: monster);
      if (!monster.isAlive) { _onMonsterDead(); return; }
    }

    // 3. 몬스터 평타
    if (monster.tickAttack(dt)) {
      _doAttack(attacker: monster, target: player);
      if (!player.isAlive) { _onPlayerDead(); return; }
    }

    // 4. 스킬 쿨타임 틱
    for (final skill in player.skills) {
      if (skill.tickCooldown(dt, player)) {
        _activateSkill(skill, caster: player, target: monster);
        if (!monster.isAlive) { _onMonsterDead(); return; }
      }
    }

    // 몬스터 스킬 처리 + 킹 슬라임 특수 패턴 (분열)
    if (monster.id == 'slime_boss2' && monster.hpRatio < 0.3) {
      final splitSkill = monster.skills.where((s) => s.id == 'slime_split').firstOrNull;
      // 아직 분열 버프가 없다면 발동
      if (splitSkill != null && !monster.activeBuffs.any((b) => b.name == splitSkill.name)) {
        _log('📢 [킹 슬라임] 분열! 작은 슬라임들을 소환하여 공격력이 강화됩니다!');
        _activateSkill(splitSkill, caster: monster, target: player);
      }
    }

    for (final skill in monster.skills) {
      if (skill.id == 'slime_split') continue; // 위에서 특수 패턴으로 처리
      if (skill.tickCooldown(dt, monster)) {
        _activateSkill(skill, caster: monster, target: player);
        if (!player.isAlive) { _onPlayerDead(); return; }
      }
    }

    // 5. 사망 체크
    if (!player.isAlive) {
      _onPlayerDead();
    } else if (!monster.isAlive) {
      _onMonsterDead();
    }
  }

  void _doAttack({required Character attacker, required Character target}) {
    // 과부하: 공격 시 현재 HP 1% 소모
    if (attacker.isPlayer && attacker.hasOverload) {
      final hpLoss = attacker.currentHp * 0.01;
      attacker.currentHp = (attacker.currentHp - hpLoss).clamp(1.0, attacker.maxHp);
    }

    // 가시 갑옷: 보스(적)가 플레이어를 공격할 때 보스의 방어력 영구 감소
    if (target.isPlayer && target.hasThornsArmor && !attacker.isPlayer) {
      attacker.baseDefense = (attacker.baseDefense - 1.0).clamp(0.0, double.infinity);
    }

    double damageMult = 1.0;
    // 처형자 효과: 적 HP 20% 이하일 때 공격력 보너스
    if (target.hpRatio <= 0.2 && attacker.executerBonus > 0) {
      damageMult += attacker.executerBonus;
    }

    final result = attacker.rollAttack();
    double finalDamage = result.damage * damageMult;

    // 기절한 적에게 추가 데미지 (유물 효과)
    if (target.stunTimer > 0 && attacker.relicStunExtraDamageRatio > 0) {
      finalDamage *= (1.0 + attacker.relicStunExtraDamageRatio);
    }

    final damage = target.takeDamage(
      finalDamage,
      ignoreDefense: attacker.ignoreEnemyDefense,
    );

    // 기록 추가
    if (attacker.isPlayer) {
      damageDealtHistory.add(DamagePoint(totalElapsedSeconds, damage, isCritical: result.isCritical));
      onPlayerAttack?.call(); // 플레이어 공격 애니메이션 트리거
    } else {
      damageTakenHistory.add(DamagePoint(totalElapsedSeconds, damage, isCritical: result.isCritical));
      onMonsterAttack?.call(); // 몬스터 공격 애니메이션 트리거 (나중에 사용)
    }

    final critText = result.isCritical ? ' [치명타!]' : '';
    _log(
      '${attacker.name}이(가) ${target.name}에게 ${damage.toStringAsFixed(0)} 피해!$critText',
      isCritical: result.isCritical,
    );

    // 반격 처리 (확률 체크 및 카드별 반사 비율 적용)
    if (target.counterChance > 0 && Random().nextDouble() < target.counterChance) {
      // 가장 최근에 적용된 반격 카드의 비율을 찾거나 기본값 사용
      final counterCard = appliedCards.where((c) => c.id == 'counter').lastOrNull;
      final ratio = counterCard?.counterRatio ?? 0.5;
      
      final reflectDamage = damage * ratio;
      final actualReflect = attacker.takeDamage(reflectDamage, ignoreDefense: true);
      _log('⚔️ ${target.name}의 반격! ${attacker.name}에게 ${actualReflect.toStringAsFixed(0)} 피해!');
      if (attacker.isPlayer) {
        damageTakenHistory.add(DamagePoint(totalElapsedSeconds, actualReflect, isSkill: false));
      } else {
        damageDealtHistory.add(DamagePoint(totalElapsedSeconds, actualReflect, isSkill: false));
      }
    }

    // 흡혈 처리
    if (attacker.lifestealRatio > 0) {
      final healed = attacker.heal(damage * attacker.lifestealRatio);
      if (healed > 0) _log('💚 흡혈로 ${healed.toStringAsFixed(0)} HP 회복');
    }

    // 기절 일격 처리 (카드 등으로 추가된 기절 확률 체크)
    if (attacker.isPlayer && selectedCardIds.contains('stun_strike')) {
      if (Random().nextDouble() < 0.10) {
        target.stunTimer = 1.5;
        _log('🌀 기절 일격! ${target.name}이(가) 1.5초간 기절했습니다.');
      }
    }

    // 평타 기반 onHit 스킬 체크 (플레이어만)
    if (attacker.isPlayer) {
      for (final skill in attacker.skills) {
        if (skill.checkOnHitTrigger()) {
          _activateSkill(skill, caster: attacker, target: target);
        }
      }
    }
  }

  void _activateSkill(Skill skill, {required Character caster, required Character target}) {
    if (caster.isPlayer) {
      onSkillCast?.call(skill.id);
    }

    // 즉시 효과가 필요한 스킬들만 여기서 처리
    switch (skill.effectType) {
      case SkillEffectType.damage:
        if (skill.id == 'fireball') {
          // 파이어볼은 발사체 충돌 시 applyDelayedSkillDamage 호출로 처리
        } else {
          final dmg = target.takeDamage(caster.effectiveAttack * skill.effectMultiplier);
          if (caster.isPlayer) {
            damageDealtHistory.add(DamagePoint(totalElapsedSeconds, dmg, isSkill: true));
          } else {
            damageTakenHistory.add(DamagePoint(totalElapsedSeconds, dmg, isSkill: true));
          }
          _log('✨ [${skill.name}]! ${target.name}에게 ${dmg.toStringAsFixed(0)} 피해!', isSkill: true);

          // 대지 강타: 1초 기절
          if (skill.id == 'earth_slam') {
            target.stunTimer = 1.0;
            _log('🌀 [대지 강타]로 인해 ${target.name}이(가) 1초간 기절했습니다!');
          }
        }

      case SkillEffectType.heal:
        final healed = caster.heal(caster.maxHp * 0.2);
        _log('💚 [${skill.name}]으로 ${healed.toStringAsFixed(0)} HP 회복!', isSkill: true);

      case SkillEffectType.buff:
        caster.addBuff(ActiveBuff(
          name: skill.name,
          attackMultiplier: skill.effectMultiplier,
          defenseMultiplier: 1.0,
          remainingSeconds: skill.buffDuration,
        ));
        _log('🔥 [${skill.name}] 발동! ${caster.name}이(가) 강화되었습니다!', isSkill: true);

      case SkillEffectType.dot:
        target.addDot(DotEffect(
          name: skill.name,
          damagePerSecond: caster.effectiveAttack * skill.effectMultiplier,
          remainingSeconds: skill.buffDuration,
        ));
        _log('☠️ [${skill.name}]! ${target.name}에게 지속 피해를 입힙니다.', isSkill: true);
    }

    // 마력 역류: 스킬 사용 시 20% 확률로 쿨타임 초기화
    if (caster.isPlayer && caster.hasManaBackflow && skill.triggerType == SkillTriggerType.cooldown) {
      if (Random().nextDouble() < 0.20) {
        skill.resetCooldown();
        _log('🌀 마력 역류! [${skill.name}] 쿨타임이 즉시 초기화되었습니다!', isSkill: true);
      }
    }
  }

  /// 발사체가 목표에 닿았을 때 호출하여 실제 데미지를 입힘
  void applyDelayedSkillDamage(String skillId, Character caster, Character target) {
    final skill = caster.skills.where((s) => s.id == skillId).firstOrNull;
    if (skill == null) return;

    double damageMult = 1.0;
    if (target.hpRatio <= 0.2 && caster.executerBonus > 0) {
      damageMult += caster.executerBonus;
    }

    final dmg = target.takeDamage(caster.effectiveAttack * skill.effectMultiplier * damageMult);
    
    if (caster.isPlayer) {
      damageDealtHistory.add(DamagePoint(totalElapsedSeconds, dmg, isSkill: true));
    } else {
      damageTakenHistory.add(DamagePoint(totalElapsedSeconds, dmg, isSkill: true));
    }
    
    _log('✨ [${skill.name}] 명중! ${target.name}에게 ${dmg.toStringAsFixed(0)} 피해!', isSkill: true);
  }

  /// 카드 선택 적용
  void applyCard(CardReward card) {
    if (phase != BattlePhase.cardSelect && phase != BattlePhase.startCardSelect) return;
    appliedCards.add(card);
    selectedCardIds.add(card.id);

    switch (card.type) {
      case CardType.statUp:
        if (card.attackMultiplierBonus != 0) {
          player.tempAttackMultiplier += card.attackMultiplierBonus;
        }
        if (card.attackBonus != 0) {
          player.tempAttackMultiplier += card.attackBonus / player.baseAttack;
        }
        if (card.defenseBonus != 0) {
          if (card.defenseBonus.abs() < 1.0) {
            player.tempDefenseMultiplier += card.defenseBonus;
          } else {
            player.tempDefenseMultiplier += card.defenseBonus / player.baseDefense;
          }
        }
        if (card.maxHpBonus != 0) {
          if (card.maxHpBonus > 0) {
            player.maxHp += card.maxHpBonus;
            player.currentHp += card.maxHpBonus;
            _log('🃏 [${card.name}]으로 최대 HP ${card.maxHpBonus.toInt()} 증가!');
          } else {
            double reduction = player.maxHp * card.maxHpBonus.abs();
            player.maxHp -= reduction;
            player.currentHp = player.currentHp.clamp(0, player.maxHp);
            _log('🃏 [${card.name}]으로 최대 HP ${(card.maxHpBonus.abs() * 100).toInt()}% 감소!');
          }
        }
        if (card.attackSpeedBonus != 0) {
          player.attackInterval *= (1.0 - card.attackSpeedBonus);
          _log('🃏 [${card.name}]으로 공격 속도 ${(card.attackSpeedBonus * 100).toInt()}% 증가!');
        }

      case CardType.heal:
        final healed = player.heal(player.maxHp * card.healRatio);
        _log('🃏 [${card.name}]으로 ${healed.toStringAsFixed(0)} HP 회복!');

      case CardType.critUp:
        player.critChance += card.critChanceBonus;
        player.critMultiplier += card.critMultiplierBonus;

      case CardType.critEffect:
        player.critChance += card.critChanceBonus;
        player.lifestealRatio += card.critHealRatio;

      case CardType.newSkill:
        if (card.skill != null) {
          player.skills.add(card.skill!);
          _log('🃏 [${card.name}] 획득!');
        }

      case CardType.resetCooldown:
        player.cooldownReductionRate = (1.0 - (1.0 - player.cooldownReductionRate) * 0.5);
        _log('🃏 [${card.name}] 발동! 모든 스킬 쿨타임 50% 영구 감소!');

      case CardType.skillUpgrade:
        if (card.targetSkillId == 'fireball') {
          var fireball = player.skills.where((s) => s.id == 'fireball').firstOrNull;
          if (fireball == null) {
            fireball = Skill.fireball();
            player.skills.add(fireball);
          }
          fireball.effectMultiplier *= 1.5;
          fireball.cooldownSeconds *= 0.7;
          fireball.upgradeLevel = 2;
          _log('🃏 [${card.name}] 적용! 파이어볼 II로 강화되었습니다!');
        }

      case CardType.special:
        if (card.hasDeathsDoor) player.hasDeathsDoor = true;
        if (card.lifestealRatio > 0) player.lifestealRatio += card.lifestealRatio;
        if (card.damageReduction > 0) player.damageReduction += card.damageReduction;
        if (card.ignoreEnemyDefense) {
          player.ignoreEnemyDefense = true;
          player.hasNoDefense = true;
        }
        if (card.rageAttackBonus > 0) {
          player.rageAttackBonus += card.rageAttackBonus;
          _log('🃏 [${card.name}] 적용! HP 50% 이하일 때 공격력이 대폭 상승합니다.');
        }
        if (card.executerBonus > 0) {
          player.executerBonus += card.executerBonus;
          _log('🃏 [${card.name}] 적용! 적 HP 20% 이하일 때 마무리 일격이 강력해집니다.');
        }
        if (card.counterChance > 0) {
          player.counterChance = card.counterChance;
          _log('🃏 [${card.name}] 적용! 피격 시 반격이 활성화되었습니다.');
        }
        if (card.isShieldCard) {
          _log('🃏 [${card.name}] 적용! 다음 전투부터 보호막이 생성됩니다.');
        }
        if (card.isStunStrike) {
          _log('🃏 [${card.name}] 적용! 평타 공격 시 기절 확률이 추가되었습니다.');
        }

        // 신규 특수 카드들
        if (card.hasFirstMove) player.hasFirstMove = true;
        if (card.hasSteelEcho) player.hasSteelEcho = true;
        if (card.hasThornsArmor) player.hasThornsArmor = true;
        if (card.hasManaBackflow) player.hasManaBackflow = true;
        if (card.hasWheelOfFate) player.hasWheelOfFate = true;
        if (card.hasOverload) player.hasOverload = true;
        if (card.hasPrecisionShooting) player.hasPrecisionShooting = true;
    }

    _log('🃏 [${card.name}] 적용!');

    if (phase == BattlePhase.startCardSelect) {
      remainingInitialPicks--;
      if (remainingInitialPicks > 0) {
        currentCards = CardReward.drawThree(excludeIds: selectedCardIds);
        _log('🃏 카드 $remainingInitialPicks장을 더 선택하세요!');
        return;
      } else {
        phase = BattlePhase.fighting;
        _startNextWave();
        _log('--- 전투 시작! ${run.currentMonster!.name} 등장! ---');
      }
    } else {
      if (run.nextMonster()) {
        phase = BattlePhase.fighting;
        _startNextWave();
        _log('--- ${run.currentMonster!.name} 등장! ---');
      } else {
        phase = BattlePhase.victory;
        _log('🏆 던전 클리어! 승리!');
        onVictory?.call(run.stageId);
      }
    }

    if (phase == BattlePhase.fighting && selectedCardIds.contains('shield')) {
      player.shieldHp = player.maxHp * 0.15;
      _log('🛡️ 방어막 생성! (${player.shieldHp.toStringAsFixed(0)} HP)');
    }
  }

  void _onMonsterDead() {
    _log('💀 ${currentMonster!.name} 처치!');
    
    // 불사의 의지: 처치 시 회복
    if (player.undyingHealRatio > 0) {
      final healed = player.heal(player.maxHp * player.undyingHealRatio);
      if (healed > 0) _log('🃏 [불사의 의지] 발동! ${healed.toStringAsFixed(0)} HP 회복');
    }

    if (run.isBossWave) {
      phase = BattlePhase.victory;
      _log('🏆 보스 처치! 던전 클리어!');
      onVictory?.call(run.stageId);
    } else {
      _startNextWave();
      phase = BattlePhase.cardSelect;
      currentCards = CardReward.drawThree(excludeIds: selectedCardIds);
      _log('🃏 카드 3장 중 하나를 선택하세요!');
    }
  }

  void _onPlayerDead() {
    phase = BattlePhase.defeat;
    _log('💔 플레이어 사망. 런 실패...');
  }

  void _log(String msg, {bool isSkill = false, bool isCritical = false}) {
    logs.add(BattleLog(msg, isSkill: isSkill, isCritical: isCritical));
    if (logs.length > 100) logs.removeAt(0);
  }

  void _cleanupHistory() {
    final threshold = totalElapsedSeconds - 30;
    damageDealtHistory.removeWhere((p) => p.time < threshold);
    damageTakenHistory.removeWhere((p) => p.time < threshold);
  }
}

class DamagePoint {
  final double time;
  final double damage;
  final bool isCritical;
  final bool isSkill;

  DamagePoint(this.time, this.damage, {this.isCritical = false, this.isSkill = false});
}
