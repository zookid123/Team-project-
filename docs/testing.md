# Testing

## 테스트 전략 개요

| 종류 | 도구 | 대상 |
|------|------|------|
| 단위 테스트 | `flutter test` | Domain 로직, ViewModel |
| 위젯 테스트 | `flutter test` | UI 컴포넌트 |
| 통합 테스트 | `flutter test integration_test` | 전체 앱 흐름 |

---

## 1. 테스트 실행

### 전체 테스트 실행
```bash
flutter test
```

### 특정 파일만 실행
```bash
flutter test test/domain/auto_battle_engine_test.dart
```

### 커버리지 포함 실행
```bash
flutter test --coverage
```

커버리지 리포트 확인:
```bash
# lcov 설치 후
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 2. 테스트 디렉토리 구조

```
test/
├── domain/
│   ├── auto_battle_engine_test.dart
│   ├── dungeon_generator_test.dart
│   └── balance_config_test.dart
├── application/
│   ├── battle_view_model_test.dart
│   └── meta_view_model_test.dart
├── widget/
│   ├── battle_hud_test.dart
│   └── main_menu_test.dart
└── helpers/
    └── test_helpers.dart

integration_test/
└── app_test.dart
```

---

## 3. 단위 테스트 작성 규칙

**파일명**: `{클래스명}_test.dart`  
**위치**: `test/` 아래 레이어 구조 그대로

### 예시 — AutoBattleEngine 단위 테스트

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/domain/auto_battle_engine.dart';

void main() {
  group('AutoBattleEngine', () {
    late AutoBattleEngine engine;

    setUp(() {
      engine = AutoBattleEngine();
    });

    test('스킬 발동 시 데미지가 0보다 커야 한다', () {
      final result = engine.executeSkill('fireball', target: 'enemy_1');
      expect(result.damage, greaterThan(0));
    });

    test('HP가 0 이하면 전투 종료로 판정한다', () {
      final result = engine.checkBattleEnd(playerHp: 0, enemyHp: 100);
      expect(result, BattleResult.defeat);
    });
  });
}
```

---

## 4. 위젯 테스트 작성 규칙

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/presentation/widgets/battle_hud.dart';

void main() {
  testWidgets('BattleHUD에 HP 바가 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BattleHUD(playerHp: 80, maxHp: 100),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('80 / 100'), findsOneWidget);
  });
}
```

---

## 5. 통합 테스트

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('메인 메뉴에서 던전 입장까지 흐름', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 메인 메뉴 확인
    expect(find.text('던전 시작'), findsOneWidget);

    // 던전 입장 버튼 탭
    await tester.tap(find.text('던전 시작'));
    await tester.pumpAndSettle();

    // 던전 화면 확인
    expect(find.byType(BattleHUD), findsOneWidget);
  });
}
```

통합 테스트 실행:
```bash
flutter test integration_test/app_test.dart
```

---

## 6. 테스트 작성 기준

### 반드시 테스트해야 하는 것
- Domain 로직 (전투 계산, 던전 생성 규칙, 밸런스 수치)
- ViewModel의 상태 변화 로직
- 저장/불러오기 (SaveRepository)

### 테스트 하면 좋은 것
- 주요 화면 위젯 렌더링
- 사용자 인터랙션 흐름

### 테스트 안 해도 되는 것
- Flutter 기본 위젯 동작
- 외부 라이브러리 내부 로직

---

## 7. 발표 Q&A 대비

**"테스트는 어떻게 실행하나요?"**
```bash
flutter test
```

**"어떤 것을 테스트했나요?"**
> Domain 레이어의 핵심 게임 로직(전투 계산, 던전 생성)을 단위 테스트로,
> 주요 화면 렌더링을 위젯 테스트로 검증했습니다.

**"커버리지는 얼마나 되나요?"**
```bash
flutter test --coverage
```
