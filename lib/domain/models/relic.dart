import 'dart:math';

enum RelicGrade { common, rare, epic }

class Relic {
  final String id;
  final String name;
  final String description;
  final RelicGrade grade;
  final Map<int, double> levelValues; // 레벨별 효과 수치

  Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.grade,
    required this.levelValues,
  });

  /// 유물 레벨업에 필요한 개수
  static int getRequiredCountForLevel(int targetLevel) {
    if (targetLevel == 2) return 2;
    if (targetLevel == 3) return 5;
    if (targetLevel == 4) return 10;
    return 999; // 최대 레벨 초과
  }

  /// 현재 레벨에서의 효과 수치 반환
  double getValue(int level) {
    return levelValues[level] ?? levelValues[1] ?? 0.0;
  }

  static List<Relic> get allRelics => [
        // Common
        Relic(
          id: 'relic_atk',
          name: '힘의 반지',
          description: '공격력이 증가합니다.',
          grade: RelicGrade.common,
          levelValues: {1: 5.0, 2: 10.0, 3: 20.0, 4: 40.0},
        ),
        Relic(
          id: 'relic_def',
          name: '단단한 가죽',
          description: '방어력이 증가합니다.',
          grade: RelicGrade.common,
          levelValues: {1: 5.0, 2: 10.0, 3: 20.0, 4: 40.0},
        ),
        Relic(
          id: 'relic_hp',
          name: '생명의 정수',
          description: '최대 체력이 증가합니다.',
          grade: RelicGrade.common,
          levelValues: {1: 20.0, 2: 40.0, 3: 80.0, 4: 160.0},
        ),
        Relic(
          id: 'relic_crit_chance',
          name: '날카로운 안목',
          description: '치명타 확률이 증가합니다.',
          grade: RelicGrade.common,
          levelValues: {1: 0.10, 2: 0.15, 3: 0.20, 4: 0.30},
        ),
        Relic(
          id: 'relic_crit_mult',
          name: '파괴의 장갑',
          description: '치명타 피해량이 증가합니다.',
          grade: RelicGrade.common,
          levelValues: {1: 0.50, 2: 0.75, 3: 1.0, 4: 1.5},
        ),
        Relic(
          id: 'relic_atk_speed',
          name: '신속의 장화',
          description: '공격 속도가 증가합니다.',
          grade: RelicGrade.common,
          levelValues: {1: 0.10, 2: 0.15, 3: 0.20, 4: 0.30},
        ),
        // Rare
        Relic(
          id: 'relic_reroll',
          name: '운명의 주사위',
          description: '카드 리롤 횟수가 추가됩니다.',
          grade: RelicGrade.rare,
          levelValues: {1: 1.0, 2: 2.0, 3: 3.0, 4: 5.0},
        ),
        Relic(
          id: 'relic_stun_dmg',
          name: '처형자의 검',
          description: '기절한 적에게 추가 데미지를 입힙니다.',
          grade: RelicGrade.rare,
          levelValues: {1: 0.50, 2: 0.75, 3: 1.0, 4: 1.5},
        ),
        // Epic
        Relic(
          id: 'relic_extra_gold',
          name: '황금 고블린의 주머니',
          description: '스테이지 클리어 시 추가 골드를 획득합니다.',
          grade: RelicGrade.epic,
          levelValues: {1: 100.0, 2: 200.0, 3: 400.0, 4: 800.0},
        ),
        Relic(
          id: 'relic_start_card',
          name: '예지자의 서',
          description: '전투 시작 시 추가 카드를 선택합니다.',
          grade: RelicGrade.epic,
          levelValues: {1: 1.0, 2: 2.0, 3: 3.0, 4: 4.0},
        ),
      ];

  static Relic? fromId(String id) {
    try {
      return allRelics.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 소환 시 랜덤 유물 ID 반환
  static String rollRelicId() {
    final rand = Random().nextDouble();
    RelicGrade grade;
    if (rand < 0.05) {
      grade = RelicGrade.epic;
    } else if (rand < 0.20) {
      grade = RelicGrade.rare;
    } else {
      grade = RelicGrade.common;
    }

    final pool = allRelics.where((r) => r.grade == grade).toList();
    if (pool.isEmpty) return allRelics.first.id;
    return pool[Random().nextInt(pool.length)].id;
  }
}
