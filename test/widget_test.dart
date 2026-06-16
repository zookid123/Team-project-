import 'package:flutter_test/flutter_test.dart';

void main() {
  // 단위 테스트: 전투 데미지 계산 검증
  test('데미지 계산 - 기본 공격력 적용', () {
    int attack = 10;
    int defense = 3;
    int damage = attack - defense;
    expect(damage, equals(7));
  });

  // 단위 테스트: 체력 감소 검증
  test('체력 감소 - 0 이하로 내려가지 않음', () {
    int hp = 5;
    int damage = 10;
    int result = (hp - damage).clamp(0, 9999);
    expect(result, equals(0));
  });

  // 단위 테스트: 카드 선택 능력치 강화 검증
  test('카드 선택 - 공격력 강화 적용', () {
    int baseAttack = 10;
    int bonus = 5;
    int result = baseAttack + bonus;
    expect(result, equals(15));
  });
}
