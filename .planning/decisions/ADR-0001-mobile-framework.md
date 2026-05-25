# ADR-0001: 모바일 프레임워크 선택

- **상태**: Accepted
- **날짜**: 2026-05-19
- **결정자**: 팀

## 배경

iOS/Android 동시 지원이 필요하며, 자동전투 UI 렌더링과 절차적 던전 화면을 처리해야 한다.
크로스플랫폼 프레임워크(Flutter, React Native)와 네이티브(Android/iOS) 중 선택이 필요했다.

## 고려한 대안

### 대안 A: Flutter (Dart)
- 장점: 단일 코드로 양 OS, Hot Reload로 빠른 개발, 위젯 시스템 풍부, AI 학습데이터 多
- 단점: Dart 학습 필요, 네이티브 모듈 깊게 다루려면 결국 Kotlin/Swift 필요

### 대안 B: React Native (TypeScript)
- 장점: JS/TS 친숙하면 빠른 진입, Expo로 쉬운 환경 구축, npm 생태계 거대
- 단점: 네이티브 브릿지 디버깅 어려움, 성능 민감 영역 한계

### 대안 C: Android Native (Kotlin)
- 장점: OS 풀 액세스, 성능 최상
- 단점: iOS 별도 개발 필요, 6주 내 양 OS 지원 불가

## 결정

**Flutter (Dart)** 를 선택한다.

## 이유

- iOS/Android 동시 지원이 필수인데 6주 일정상 네이티브 양쪽 개발은 불가능
- Flutter는 단일 코드베이스로 양 OS 빌드 가능하고 Hot Reload로 개발 속도가 빠름
- 게임 수준의 고성능 렌더링보다 UI 반응성이 중요한 로그라이크 RPG에 적합
- AI Agent의 Flutter 학습 데이터가 풍부해 코드 생성 품질이 높음

## 결과

**긍정:**
- iOS/Android 단일 코드베이스 유지
- Hot Reload로 UI 반복 작업 속도 향상
- 풍부한 위젯으로 배틀 HUD·메타 화면 빠르게 구현 가능

**부정 / 제약:**
- Dart 문법 학습 초기 비용
- 복잡한 게임 이펙트는 Flutter 한계 있음 → 단순 2D UI로 설계

## 60초 발표 요약

> "저희 팀은 6주 안에 iOS/Android 모두 데모해야 했기 때문에,
> 네이티브 개발 대신 단일 코드베이스로 양 OS를 지원하는 Flutter를 선택했습니다.
> React Native도 검토했지만, Flutter가 UI 위젯 시스템이 더 풍부하고
> Hot Reload로 개발 속도가 빠르다고 판단했습니다."

## 후속 작업

- [ ] Flutter 3.x LTS 버전으로 프로젝트 초기화
- [ ] iOS / Android 빌드 환경 세팅 (flutter doctor 통과)
- [ ] Hello World 화면 빌드 성공 확인
