# ADR-0002: 상태 관리 방식

- **상태**: Accepted
- **날짜**: 2026-05-19
- **결정자**: 팀

## 배경

던전 상태·캐릭터 스탯·메타 진행 데이터를 Flutter에서 어떻게 관리할 것인지 결정이 필요했다.
Flutter의 상태 관리 라이브러리 중 프로젝트 규모에 맞는 것을 선택해야 했다.

## 고려한 대안

### 대안 A: setState (Flutter 기본)
- 장점: 별도 라이브러리 없음, 즉시 사용 가능
- 단점: 화면 간 상태 공유 어려움, 코드가 복잡해지면 관리 불가

### 대안 B: Provider
- 장점: Flutter 공식 권장, 학습 비용 낮음, 간단한 구조
- 단점: 복잡한 상태 로직에서 ChangeNotifier가 비대해짐

### 대안 C: Riverpod
- 장점: Provider 개선판, 타입 안전, 테스트 용이, 컴파일 타임 오류 감지
- 단점: Provider보다 학습 비용 높음, 초반 설정 복잡

## 결정

**Provider** 를 선택한다.

## 이유

- 6주 프로젝트에서 학습 비용이 낮은 것이 중요
- Flutter 공식 문서에서 권장하는 방식
- AI Agent의 Provider 코드 생성 품질이 높고 예제가 풍부
- 프로젝트 규모(10화면 미만)에서 Riverpod의 복잡성은 오버엔지니어링

## 결과

**긍정:**
- 빠른 학습과 즉시 적용 가능
- 공식 문서 및 예제 풍부
- ViewModel 패턴과 자연스럽게 연결

**부정 / 제약:**
- 복잡한 비동기 상태 처리 시 코드가 길어질 수 있음
- 대규모 확장 시 Riverpod으로 마이그레이션 필요할 수 있음

## 60초 발표 요약

> "Flutter 상태관리로 setState, Provider, Riverpod을 검토했습니다.
> 6주 프로젝트에서 학습 비용이 낮고 Flutter 공식 권장 방식인 Provider를 선택했습니다.
> Riverpod이 더 강력하지만 현재 규모에서는 오버엔지니어링이라 판단했습니다."

## 후속 작업

- [ ] pubspec.yaml에 provider 패키지 추가
- [ ] BattleViewModel, DungeonViewModel, MetaViewModel ChangeNotifier로 구현
- [ ] MultiProvider로 앱 최상단에서 주입
