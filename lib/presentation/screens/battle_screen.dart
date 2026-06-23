import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/battle_engine.dart';
import '../../domain/models/character.dart';
import '../../domain/models/card_reward.dart';
import '../../domain/models/skill.dart';

class BattleScreen extends StatefulWidget {
  final BattleEngine engine;

  const BattleScreen({super.key, required this.engine});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  int _rerollCount = 0;

  bool _isPaused = false;
  bool _showSettings = false;
  double _gameSpeed = 1.0; // 게임 속도 (1.0 또는 1.5)
  int _logTabIndex = 0; // 0: 로그, 1: 캐릭터 정보

  // BGM 관련
  late AudioPlayer _bgmPlayer;
  double _bgmVolume = 0.5;
  bool _isBgmEnabled = true;

  // 공격 애니메이션 관련
  int _playerAtkFrame = -1; // -1: Idle, 0~3: 공격 중
  double _atkFrameTimer = 0;
  final double _frameDuration = 0.08; // 프레임당 0.08초

  // 발사체 애니메이션 관련
  final List<_Projectile> _projectiles = [];

  // 회복 이펙트 관련
  double _healTimer = 0;
  bool _showHealEffect = false;

  @override
  void initState() {
    super.initState();
    _bgmPlayer = AudioPlayer();
    _loadSettingsAndPlayBgm();
    
    // 엔진 콜백 연결
    widget.engine.onPlayerAttack = () {
      setState(() {
        _playerAtkFrame = 0;
        _atkFrameTimer = 0;
      });
    };

    widget.engine.onSkillCast = (skillId) {
      if (skillId == 'fireball') {
        // 파이어볼 스킬 찾아서 레벨 확인
        final fireball = widget.engine.player.skills.firstWhere((s) => s.id == 'fireball');
        final isUpgraded = fireball.upgradeLevel > 1;
        final size = isUpgraded ? 187.5 : 125.0; // 1.5배 크기 증가

        setState(() {
          _projectiles.add(_Projectile(
            imagePath: 'assets/fireball.png',
            startX: 0.3, // 플레이어 위치 (비율)
            startY: 0.5,
            endX: 0.7,   // 몬스터 위치 (비율)
            endY: 0.5,
            duration: 0.55, 
            size: size,
            onImpact: () {
              final monster = widget.engine.currentMonster;
              if (monster != null) {
                widget.engine.applyDelayedSkillDamage(
                  'fireball', 
                  widget.engine.player, 
                  monster
                );
              }
            },
          ));
        });
      } else if (skillId == 'heal') {
        setState(() {
          _showHealEffect = true;
          _healTimer = 1.0; // 1초 동안 표시
        });
      }
    };

    widget.engine.onVictory = (stageId) {
      _updateProgress(stageId);
    };

    _ticker = createTicker((elapsed) {
      double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      dt *= _gameSpeed; // 배속 적용
      
      if (!_isPaused && widget.engine.phase == BattlePhase.fighting) {
        widget.engine.tick(dt);
        
        // 공격 애니메이션 프레임 업데이트
        if (_playerAtkFrame >= 0) {
          _atkFrameTimer += dt;
          if (_atkFrameTimer >= _frameDuration) {
            _atkFrameTimer = 0;
            _playerAtkFrame++;
            if (_playerAtkFrame >= 4) { // 가로 4칸
              _playerAtkFrame = -1; // 애니메이션 종료
            }
          }
        }

        // 발사체 업데이트
        if (_projectiles.isNotEmpty) {
          setState(() {
            _projectiles.removeWhere((p) => p.update(dt));
          });
        }

        // 회복 이펙트 업데이트
        if (_showHealEffect) {
          _healTimer -= dt;
          if (_healTimer <= 0) {
            setState(() {
              _showHealEffect = false;
            });
          }
        }
      }
      _lastElapsed = elapsed;
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _showSettings = _isPaused;
    });
  }

  void _onResume() {
    setState(() {
      _isPaused = false;
      _showSettings = false;
    });
  }

  void _onExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('포기하시겠습니까?', style: TextStyle(color: Colors.white)),
        content: const Text('현재 진행 중인 런을 포기하고 홈으로 돌아갑니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              _stopBgm();
              Navigator.pop(context); // 팝업 닫기
              Navigator.pop(context); // 전투 종료
            },
            child: const Text('나가기', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettingsAndPlayBgm() async {
    final prefs = await SharedPreferences.getInstance();
    double vol = prefs.getDouble('bgmVolume') ?? 0.5;
    bool enabled = prefs.getBool('isBgmEnabled') ?? true;
    
    if (mounted) {
      setState(() {
        _bgmVolume = vol;
        _isBgmEnabled = enabled;
      });
    }

    if (enabled) {
      try {
        // 이미 재생 중이면 볼륨만 조절하고 리턴
        if (_bgmPlayer.state == PlayerState.playing) {
          await _bgmPlayer.setVolume(vol);
          return;
        }

        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.setVolume(vol);
        await _bgmPlayer.play(AssetSource('127. Attack of The Trolls.mp3'));
      } catch (e) {
        debugPrint('Battle BGM Error: $e');
      }
    }
  }

  Future<void> _stopBgm() async {
    await _bgmPlayer.stop();
  }

  @override
  void dispose() {
    _stopBgm();
    _bgmPlayer.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _onReroll() {
    int maxRerolls = 1 + widget.engine.player.relicRerollBonus;
    if (_rerollCount >= maxRerolls) return;
    setState(() {
      widget.engine.currentCards = CardReward.drawThree(excludeIds: widget.engine.selectedCardIds);
      _rerollCount++;
    });
  }

  Future<void> _updateProgress(String stageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      final data = doc.data() ?? {};
      
      final List<String> clearedStages = List<String>.from(data['clearedStages'] ?? []);
      final bool isFirstClear = !clearedStages.contains(stageId);
      final int baseGold = isFirstClear ? 1000 : 500;
      final int extraGold = widget.engine.player.relicExtraGold;
      final int rewardGold = baseGold + extraGold;
      final int currentGold = data['gold'] ?? 0;

      // 현재 클리어한 스테이지에 따라 다음 스테이지 해금
      String? nextStage;
      if (stageId == '1-1') nextStage = '1-2';
      if (stageId == '1-2') nextStage = '1-3';
      if (stageId == '1-3') nextStage = '2-1';

      final Map<String, dynamic> updates = {
        'lastClearedStage': stageId,
        'gold': currentGold + rewardGold,
      };

      if (isFirstClear) {
        updates['clearedStages'] = FieldValue.arrayUnion([stageId]);
      }

      if (nextStage != null) {
        updates['unlockedStages'] = FieldValue.arrayUnion([nextStage]);
        debugPrint('Stage $nextStage unlocked!');
      }

      await userRef.update(updates);
      debugPrint('Gold reward added: $rewardGold (Base: $baseGold, Relic extra: $extraGold)');
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final player = engine.player;
    final monster = engine.currentMonster;

    return Scaffold(
      body: Stack(
        children: [
          // 1. 배경
          Positioned.fill(
            child: Image.asset(
              widget.engine.run.stageId.startsWith('2-') ? 'assets/stage2.png' : 'assets/stage1.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 미니맵 (진행상황)
          SafeArea(child: _buildMinimap(engine)),

          // 배속 버튼 (좌측 상단)
          Positioned(
            top: 70,
            left: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _gameSpeed = _gameSpeed == 1.0 ? 1.5 : 1.0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gameSpeed > 1.0 ? Colors.yellowAccent : Colors.white, width: 1.5),
                ),
                child: Text(
                  'x${_gameSpeed.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _gameSpeed > 1.0 ? Colors.yellowAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // 설정 버튼 (우측 상단)
          Positioned(
            top: 70,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 30),
              onPressed: _togglePause,
            ),
          ),

          // 3. 전투 영역
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCharacter(player, isPlayer: true),
                      if (_showHealEffect) _buildHealEffect(),
                    ],
                  ),
                ),
                if (monster != null) Expanded(child: _buildCharacter(monster, isPlayer: false)),
              ],
            ),
          ),

          // 3.1 발사체 레이어
          ..._projectiles.map((p) => _buildProjectile(p)),

          // 4. 획득한 카드 아이콘 영역
          _buildAppliedCardsArea(engine),

          // 5. 스킬 쿨타임 영역 & 6. 전투 로그 영역 (탭 포함)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSkillArea(player),
                _buildLogAndGraphArea(engine),
              ],
            ),
          ),

          // 설정 오버레이
          if (_showSettings) _buildSettingsOverlay(),

          // 카드 선택 오버레이
          if (engine.phase == BattlePhase.cardSelect || engine.phase == BattlePhase.startCardSelect)
            _buildCardSelectionOverlay(engine),

          // 승리/패배 오버레이
          if (engine.phase == BattlePhase.victory || engine.phase == BattlePhase.defeat)
            _buildResultOverlay(engine),
        ],
      ),
    );
  }

  Widget _buildMinimap(BattleEngine engine) {
    final run = engine.run;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 4,
            width: 260,
            color: Colors.white24,
          ),
          SizedBox(
            width: 260,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(run.monsterWave.length, (index) {
                final isCurrent = index == run.currentMonsterIndex;
                final isDone = index < run.currentMonsterIndex;
                final monster = run.monsterWave[index];
                
                String iconPath = 'assets/slime1.png';
                if (monster.id == 'slime_boss') {
                  iconPath = 'assets/slime_boss.png';
                } else if (monster.id == 'slime_boss2') {
                  iconPath = 'assets/slime_boss2.png';
                } else if (monster.id == 'slime2') {
                  iconPath = 'assets/slime2.png';
                } else if (monster.id == 'skel1') {
                  iconPath = 'assets/skel1.png';
                } else if (monster.id == 'skel_boss') {
                  iconPath = 'assets/skel_boss.png';
                }

                return Transform.scale(
                  scale: isCurrent ? 1.5 : 1.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? Colors.amber : Colors.black45,
                      border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Opacity(
                      opacity: isDone ? 0.4 : 1.0,
                      child: Image.asset(iconPath),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter(Character character, {required bool isPlayer}) {
    String imagePath;
    if (isPlayer) {
      imagePath = 'assets/character.png';
    } else {
      if (character.id == 'slime_boss2') {
        // 킹 슬라임 이미지 적용
        imagePath = (_playerAtkFrame >= 0) ? 'assets/slime_boss2_dam.png' : 'assets/slime_boss2.png';
      } else if (character.id == 'slime_boss') {
        // 보스 슬라임 이미지 적용
        imagePath = (_playerAtkFrame >= 0) ? 'assets/slime_boss_dam.png' : 'assets/slime_boss.png';
      } else if (character.id == 'slime2') {
        // 파란 슬라임 이미지 적용
        imagePath = (_playerAtkFrame >= 0) ? 'assets/slime2_dam.png' : 'assets/slime2.png';
      } else if (character.id == 'skel1') {
        // 스켈레톤 이미지 적용
        imagePath = (_playerAtkFrame >= 0) ? 'assets/skel1_dam.png' : 'assets/skel1.png';
      } else if (character.id == 'skel_boss') {
        // 보스 스켈레톤 이미지 적용
        imagePath = (_playerAtkFrame >= 0) ? 'assets/skel_boss_dam.png' : 'assets/skel_boss.png';
      } else {
        // 일반 슬라임 이미지 적용
        imagePath = (_playerAtkFrame >= 0) ? 'assets/slime1_dam.png' : 'assets/slime1.png';
      }
    }

    Widget imageWidget;
    
    if (isPlayer && _playerAtkFrame >= 0) {
      // 4개의 개별 이미지를 프레임에 따라 교체 (m1~m4)
      // _playerAtkFrame은 0, 1, 2, 3 값을 가짐
      String atkImagePath = 'assets/character_atk_m${_playerAtkFrame + 1}.png';
      
      imageWidget = Padding(
        padding: const EdgeInsets.only(bottom: 75, left: 10), // 하단 여백을 10 더 늘림
        child: Image.asset(
          atkImagePath,
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        ),
      );
    } else {
      // 평상시
      imageWidget = Image.asset(
        imagePath,
        width: 250,
        height: 250,
        fit: BoxFit.contain,
      );
      
      // 슬라임2(파란 슬라임)의 경우 크기를 약간 줄임 (0.8배)
      if (!isPlayer && character.id == 'slime2') {
        imageWidget = Transform.scale(
          scale: 0.8,
          child: imageWidget,
        );
      }
      
      // 킹 슬라임(slime_boss2)의 경우 크기 조정
      if (!isPlayer && character.id == 'slime_boss2') {
        // 피격 시 이미지가 커 보이는 것을 방지하기 위해 피격 이미지는 0.75배, 평상시는 0.95배 적용
        double bossScale = (_playerAtkFrame >= 0) ? 0.75 : 0.95;
        imageWidget = Transform.scale(
          scale: bossScale,
          child: imageWidget,
        );
      }

      // 스켈레톤(skel1)의 경우 크기를 절반으로 줄임 (0.5배)
      if (!isPlayer && character.id == 'skel1') {
        imageWidget = Transform.scale(
          scale: 0.5,
          child: imageWidget,
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HP Bar
        SizedBox(
          width: 160,
          child: Column(
            children: [
              Text(
                '${character.currentHp.toInt()} / ${character.maxHp.toInt()}${character.shieldHp > 0 ? ' (+${character.shieldHp.toInt()})' : ''}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Shield Progress (Total = HP + Shield)
                    LinearProgressIndicator(
                      value: ((character.currentHp + character.shieldHp) / character.maxHp).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                    // Actual HP Progress
                    LinearProgressIndicator(
                      value: character.hpRatio,
                      minHeight: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        character.dotEffects.isNotEmpty 
                          ? Colors.green 
                          : (isPlayer ? Colors.blue : Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 이미지 영역을 고정 (250에 맞춤)
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              imageWidget,
              // 슬라임 분열 효과 (미니 슬라임들)
              if (character.id == 'slime_boss2' && character.activeBuffs.any((b) => b.name == '슬라임 분열')) ...[
                Positioned(
                  left: 0,
                  bottom: 10,
                  child: Image.asset('assets/mini_slime.png', width: 60, height: 60),
                ),
                Positioned(
                  right: 0,
                  bottom: 10,
                  child: Image.asset('assets/mini_slime.png', width: 60, height: 60),
                ),
                Positioned(
                  left: 70,
                  bottom: -5,
                  child: Image.asset('assets/mini_slime.png', width: 50, height: 50),
                ),
              ],
              if (character.stunTimer > 0)
                Positioned(
                  top: 0,
                  child: Image.asset(
                    'assets/faint_effect.png',
                    width: 120,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (!isPlayer)
          Text(
            character.name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)]),
          ),
      ],
    );
  }

  Widget _buildAppliedCardsArea(BattleEngine engine) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 100), // 좌측 사이드 중상단 배치
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: engine.appliedCards.map((card) {
            Color gradeColor = _getGradeColor(card.grade);
            return GestureDetector(
              onTap: () => _showCardInfo(card),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(color: gradeColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    card.name[0],
                    style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCardInfo(CardReward card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(card.name, style: TextStyle(color: _getGradeColor(card.grade))),
        content: Text(card.description, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  Widget _buildSkillArea(Character player) {
    // 파이어볼과 회복의 빛만 표시하도록 필터링
    final visibleSkills = player.skills.where((s) => s.id == 'fireball' || s.id == 'heal').toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: visibleSkills.map((skill) {
          final isReady = skill.cooldownProgress >= 1.0 || skill.triggerType == SkillTriggerType.onHit;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 기본 아이콘 배경 및 아이콘
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isReady ? Colors.cyanAccent : Colors.white24,
                          width: isReady ? 2 : 1,
                        ),
                        boxShadow: isReady ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Center(
                          child: _buildSkillIcon(skill),
                        ),
                      ),
                    ),
                    
                    // 쿨타임 오버레이 (시계 방향 쉐이딩)
                    if (skill.triggerType == SkillTriggerType.cooldown && !isReady)
                      IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            size: const Size(60, 60),
                            painter: SkillCooldownPainter(skill.cooldownProgress),
                          ),
                        ),
                      ),
                    
                    // 준비 안 된 스킬의 어두운 오버레이 (onHit 스킬 등)
                    if (!isReady && skill.triggerType != SkillTriggerType.cooldown)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  skill.name,
                  style: TextStyle(
                    color: isReady ? Colors.white : Colors.white54,
                    fontSize: 11,
                    fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogAndGraphArea(BattleEngine engine) {
    return Container(
      width: double.infinity,
      height: 160,
      color: Colors.black87,
      child: Column(
        children: [
          // 탭 헤더
          Container(
            height: 35,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Row(
              children: [
                _buildTabItem(0, '전투 로그'),
                _buildTabItem(1, '캐릭터 정보'),
              ],
            ),
          ),
          // 탭 내용
          Expanded(
            child: _logTabIndex == 0 
              ? _buildLogContent(engine)
              : _buildStatsContent(engine),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(BattleEngine engine) {
    final p = engine.player;
    
    // 공격 속도 계산 (초당 공격 횟수)
    final attackSpeed = 1.0 / p.attackInterval;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 왼쪽 열
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatRow(Icons.favorite, '최대 체력', p.maxHp.toInt().toString()),
                      _buildStatRow(Icons.colorize, '공격력', p.effectiveAttack.toInt().toString()),
                      _buildStatRow(Icons.speed, '공격 속도', '${attackSpeed.toStringAsFixed(2)} /s'),
                    ],
                  ),
                ),
                // 구분선
                Container(width: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 10)),
                // 오른쪽 열
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatRow(Icons.shield, '방어력', p.effectiveDefense.toInt().toString()),
                      _buildStatRow(Icons.bolt, '치명타 확률', '${(p.critChance * 100).toInt()}%'),
                      _buildStatRow(Icons.trending_up, '치명타 배율', '${p.critMultiplier.toStringAsFixed(1)}x'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 쿨타임 감소 정보 (있을 경우만 표시)
          if (p.cooldownReductionRate > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '스킬 쿨타임 감소: ${(p.cooldownReductionRate * 100).toInt()}%',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _logTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _logTabIndex = index),
        child: Container(
          alignment: Alignment.center,
          color: isSelected ? Colors.white10 : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.yellowAccent : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent(BattleEngine engine) {
    final lastLogs = engine.logs.reversed.take(20).toList().reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lastLogs.length,
      itemBuilder: (context, index) {
        final log = lastLogs[index];
        Color textColor = Colors.white;
        if (log.isSkill) textColor = Colors.yellowAccent;
        if (log.isCritical) textColor = Colors.redAccent;
        return Text(
          log.message,
          style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
        );
      },
    );
  }

  Widget _buildSettingsOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('설정', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _onResume,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onResume,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('전투 재개', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _onExit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                ),
                child: const Text('홈으로 나가기', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSelectionOverlay(BattleEngine engine) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '카드 선택',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: engine.currentCards.map((card) {
                  return GestureDetector(
                    onTap: () => engine.applyCard(card),
                    child: Container(
                      width: 140,
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getGradeColor(card.grade), width: 3),
                      ),
                      child: Column(
                        children: [
                          Text(
                            card.grade.name.toUpperCase(),
                            style: TextStyle(color: _getGradeColor(card.grade), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 10),
                          Text(
                            card.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            card.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _rerollCount >= (1 + engine.player.relicRerollBonus) ? null : _onReroll,
              child: Opacity(
                opacity: _rerollCount >= (1 + engine.player.relicRerollBonus) ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _rerollCount >= (1 + engine.player.relicRerollBonus) 
                        ? [Colors.grey[800]!, Colors.grey[700]!]
                        : [Colors.indigo[900]!, Colors.blue[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _rerollCount >= (1 + engine.player.relicRerollBonus) ? Colors.white24 : Colors.cyanAccent,
                      width: 2,
                    ),
                    boxShadow: _rerollCount >= (1 + engine.player.relicRerollBonus) ? [] : [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh, 
                        color: _rerollCount >= (1 + engine.player.relicRerollBonus) ? Colors.white38 : Colors.cyanAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '리롤 (${_rerollCount}/${1 + engine.player.relicRerollBonus})',
                        style: TextStyle(
                          color: _rerollCount >= (1 + engine.player.relicRerollBonus) ? Colors.white38 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay(BattleEngine engine) {
    final isVictory = engine.phase == BattlePhase.victory;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2), // 상단 여백 추가하여 전체적으로 위로 밀어올림
            Image.asset(
              isVictory ? 'assets/victory.png' : 'assets/defeat.png',
              width: 500,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10), // 간격을 40에서 10으로 줄임
            GestureDetector(
              onTap: () {
                _stopBgm();
                Navigator.pop(context);
              },
              child: Image.asset(
                'assets/gotohome_button.png',
                width: 280,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(flex: 3), // 하단에 더 큰 여백을 주어 버튼이 위로 올라오게 함
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(CardGrade grade) {
    switch (grade) {
      case CardGrade.common: return Colors.grey;
      case CardGrade.rare:   return Colors.blue;
      case CardGrade.epic:   return const Color(0xFFFFD700); // Gold
    }
  }

  Widget _buildSkillIcon(Skill skill) {
    if (skill.id == 'fireball') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/fireball.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          if (skill.upgradeLevel > 1)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'II',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      );
    } else if (skill.id == 'heal') {
      return Image.asset(
        'assets/heal_light.png',
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      );
    }
    // 기본값: 첫 글자 텍스트
    return Text(
      skill.name[0],
      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProjectile(_Projectile p) {
    return Positioned(
      left: MediaQuery.of(context).size.width * p.currentX - (p.size / 2),
      top: MediaQuery.of(context).size.height * p.currentY - (p.size / 2),
      child: Image.asset(
        p.imagePath,
        width: p.size,
        height: p.size,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildHealEffect() {
    return Opacity(
      opacity: _healTimer.clamp(0.0, 1.0),
      child: Image.asset(
        'assets/heal_light.png',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      ),
    );
  }
}

class SkillCooldownPainter extends CustomPainter {
  final double progress;

  SkillCooldownPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 1.2; // 전체 영역을 덮도록 충분히 크게 설정

    // 남은 쿨타임만큼 부채꼴로 가림 (시계 방향)
    final sweepAngle = 2 * 3.141592 * (1.0 - progress);
    final startAngle = -3.141592 / 2 + (2 * 3.141592 * progress);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(SkillCooldownPainter oldDelegate) => oldDelegate.progress != progress;
}

class DamageGraphPainter extends CustomPainter {
  final List<DamagePoint> dealt;
  final List<DamagePoint> taken;
  final double currentTime;

  DamageGraphPainter({
    required this.dealt,
    required this.taken,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintDealt = Paint()
      ..color = Colors.blueAccent.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final paintTaken = Paint()
      ..color = Colors.redAccent.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final startTime = currentTime - 30;
    
    // 축 그리기
    final axisPaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    // 최대 데미지 계산 (Y축 스케일링용)
    double maxDmg = 50.0;
    for (var p in dealt) {
      if (p.damage > maxDmg) maxDmg = p.damage;
    }
    for (var p in taken) {
      if (p.damage > maxDmg) maxDmg = p.damage;
    }
    maxDmg *= 1.2;

    const double barWidth = 3.0;

    void drawBars(List<DamagePoint> points, Paint barPaint) {
      for (var p in points) {
        final x = ((p.time - startTime) / 30.0) * size.width;
        final barHeight = (p.damage / maxDmg) * size.height;
        
        canvas.drawRect(
          Rect.fromLTWH(x - (barWidth / 2), size.height - barHeight, barWidth, barHeight),
          barPaint,
        );
      }
    }

    drawBars(dealt, paintDealt);
    drawBars(taken, paintTaken);
  }

  @override
  bool shouldRepaint(DamageGraphPainter oldDelegate) => true;
}

class _Projectile {
  final String imagePath;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double duration;
  final double size;
  final VoidCallback? onImpact;
  double _elapsed = 0;

  _Projectile({
    required this.imagePath,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.duration,
    required this.size,
    this.onImpact,
  });

  bool update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) {
      onImpact?.call();
      return true;
    }
    return false;
  }

  double get currentX => startX + (endX - startX) * (_elapsed / duration).clamp(0.0, 1.0);
  double get currentY => startY + (endY - startY) * (_elapsed / duration).clamp(0.0, 1.0);
}
