# ADR-0003: 로컬 저장 방식

- **상태**: Accepted
- **날짜**: 2026-05-19
- **결정자**: 팀

## 배경

메타 진행 데이터(영구 해금·스탯·런 기록)를 Flutter에서 기기에 어떻게 저장할 것인지 결정이 필요했다.
외부 서버 없이 로컬에서 완결되는 저장 방식을 채택해야 했다.

## 고려한 대안

### 대안 A: SharedPreferences
- 장점: Flutter 기본 제공, 즉시 사용, 코드 간단
- 단점: Key-Value 구조라 복잡한 중첩 데이터 저장에 부적합

### 대안 B: Hive
- 장점: 빠른 NoSQL 로컬 DB, 구조화 저장, Flutter 최적화
- 단점: 어댑터 코드 생성 필요, 초기 설정 복잡

### 대안 C: SQLite (sqflite 패키지)
- 장점: 관계형 데이터, 쿼리 가능
- 단점: 6주 프로젝트에 과도한 복잡성, SQL 작성 부담

## 결정

**Hive** 를 선택한다.

## 이유

- 메타 진행 데이터는 캐릭터·해금 목록·런 기록 등 구조가 복잡해 SharedPreferences 한계 초과
- Hive는 Flutter/Dart 전용으로 최적화되어 있고 성능이 빠름
- JSON 직렬화보다 타입 안전하게 데이터 모델 관리 가능
- SQLite보다 설정이 간단하고 Dart 코드와 자연스럽게 연동

## 결과

**긍정:**
- 구조화된 데이터 저장 가능 (캐릭터, 해금, 런 기록)
- 빠른 읽기/쓰기 성능
- Flutter 생태계에 최적화

**부정 / 제약:**
- 어댑터(TypeAdapter) 코드 생성 필요 (`build_runner` 실행)
- 스키마 변경 시 마이그레이션 처리 필요

## 60초 발표 요약

> "로컬 저장으로 SharedPreferences, Hive, SQLite를 검토했습니다.
> SharedPreferences는 Key-Value 한계가 있고, SQLite는 복잡도가 높아,
> Flutter 전용으로 최적화된 Hive를 선택했습니다.
> 타입 안전하게 구조화 데이터를 저장할 수 있어 메타 진행 데이터 관리에 적합합니다."

## 후속 작업

- [ ] pubspec.yaml에 hive, hive_flutter, build_runner 추가
- [ ] 캐릭터·해금·런 기록 TypeAdapter 생성
- [ ] SaveRepository 구현 및 앱 시작 시 Hive.initFlutter() 호출
