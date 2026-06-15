import 'dart:math';

enum EquipmentType { sword, shield, helmet }

class Equipment {
  final String id;
  final String name;
  final EquipmentType type;
  final String grade; // C1, C2, ..., S4
  final int level;    // 1~16
  final double statValue;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.grade,
    required this.level,
    required this.statValue,
  });

  static int getLevelFromGrade(String grade) {
    final char = grade[0].toLowerCase();
    final num = int.parse(grade.substring(1));
    int base = 0;
    if (char == 'c') base = 0;
    else if (char == 'b') base = 4;
    else if (char == 'a') base = 8;
    else if (char == 's') base = 12;
    return base + num;
  }

  static String getGradeFromLevel(int level) {
    int group = (level - 1) ~/ 4;
    int num = (level - 1) % 4 + 1;
    String char = 'C';
    if (group == 1) char = 'B';
    else if (group == 2) char = 'A';
    else if (group == 3) char = 'S';
    return '$char$num';
  }

  factory Equipment.fromId(String id) {
    final parts = id.split('_');
    final typeStr = parts[0];
    final gradeStr = parts[1];
    
    EquipmentType type;
    if (typeStr == 'sword') type = EquipmentType.sword;
    else if (typeStr == 'shield') type = EquipmentType.shield;
    else type = EquipmentType.helmet;

    final level = getLevelFromGrade(gradeStr);
    
    double stat = 0;
    if (type == EquipmentType.sword) {
      stat = (5 + (level - 1) * 5 + (level * level * 2)).toDouble();
    } else if (type == EquipmentType.shield) {
      stat = (2 + (level - 1) * 3 + (level * level * 0.5)).toDouble();
    } else {
      stat = (50 + (level - 1) * 30 + (level * level * 10)).toDouble();
    }

    String typeName = '';
    if (type == EquipmentType.sword) typeName = '검';
    else if (type == EquipmentType.shield) typeName = '방패';
    else typeName = '투구';

    return Equipment(
      id: id,
      name: gradeStr.toUpperCase(),
      type: type,
      grade: gradeStr.toUpperCase(),
      level: level,
      statValue: stat,
    );
  }

  static String rollEquipmentId({EquipmentType? forceType}) {
    final rand = Random().nextInt(10000);
    int level = 1;
    if (rand < 9000) {
      // C등급 (90%)
      if (rand < 5000) level = 1;
      else if (rand < 7500) level = 2;
      else if (rand < 8500) level = 3;
      else level = 4;
    } else if (rand < 9600) {
      // B등급 (6%)
      final bRand = rand - 9000;
      if (bRand < 300) level = 5;
      else if (bRand < 450) level = 6;
      else if (bRand < 550) level = 7;
      else level = 8;
    } else if (rand < 9900) {
      // A등급 (3%)
      final aRand = rand - 9600;
      if (aRand < 150) level = 9;
      else if (aRand < 230) level = 10;
      else if (aRand < 275) level = 11;
      else level = 12;
    } else {
      // S등급 (1%)
      final sRand = rand - 9900;
      if (sRand < 50) level = 13;
      else if (sRand < 80) level = 14;
      else if (sRand < 95) level = 15;
      else level = 16;
    }

    final typeStr = forceType?.name ?? ['sword', 'shield', 'helmet'][Random().nextInt(3)];
    final gradeStr = getGradeFromLevel(level).toLowerCase();
    return '${typeStr}_$gradeStr';
  }

  String? get nextGradeId {
    if (level >= 16) return null;
    final nextLevel = level + 1;
    final nextGradeStr = getGradeFromLevel(nextLevel).toLowerCase();
    return '${type.name}_$nextGradeStr';
  }
}
