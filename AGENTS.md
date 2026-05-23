# AGENTS.md

> 이 파일은 AI Agent가 매 턴 자동으로 참조하는 프로젝트 헌법입니다.
> 모든 AI Agent는 코드 작성·문서 수정·리뷰 전에 이 파일을 먼저 읽어야 합니다.

---

## 프로젝트 정체성

- **이름**: 로그라이크 던전 RPG (자동전투)
- **플랫폼**: Flutter (Dart) — iOS / Android
- **핵심 가치**: 자동전투이지만 플레이어의 판단이 결과를 결정한다

---

## 아키텍처 원칙

- **레이어**: Presentation → ViewModel → Domain → Data (단방향 의존)
- **상태관리**: Provider (ChangeNotifier 기반)
- **로컬 저장**: Hive
- **역방향 의존 금지**: Data가 Domain을 참조하면 안 됨

### 파일 위치 규칙

| 추가하려는 것 | 위치 |
|-------------|------|
| 새 화면 | `lib/presentation/screens/` |
| 상태·흐름 로직 | `lib/application/` |
| 게임 규칙·밸런스 | `lib/domain/` |
| 저장·불러오기 | `lib/data/` |
| 테스트 | `test/{레이어}/` |

---

## 코드 작성 규칙

- **언어**: Dart (Flutter 3.x)
- **네이밍**: 파일명 `snake_case`, 클래스명 `PascalCase`, 변수 `camelCase`
- **주석**: 공개 메서드에는 doc comment (`///`) 작성
- `print()` 대신 `debugPrint()` 사용
- 하드코딩 금지 — 밸런스 수치는 `BalanceConfig`에 집중 관리

---

## 문서 작성 규칙

- 모든 문서는 **한국어**로 작성
- 명령어는 복붙 가능하게 코드 블록으로 작성
- 새 기술 결정은 반드시 `.planning/decisions/ADR-NNNN-*.md` 로 기록
- 문서 수정 시 관련 ADR과 일관성 유지

---

## 금지 사항

- Unity·C#·Assets/ 관련 코드 또는 문서 작성 금지 (Flutter 프로젝트임)
- `git push --force` 는 긴급 상황 외 사용 금지
- API 키·비밀번호를 코드에 하드코딩 금지
- `.jks` 키스토어 파일을 git에 커밋 금지

---

## 참조 문서

| 문서 | 역할 |
|------|------|
| `docs/architecture.md` | 레이어 구조·다이어그램 |
| `docs/setup.md` | 환경 설정 (zero → run) |
| `docs/deploy.md` | 빌드·배포 절차 |
| `docs/testing.md` | 테스트 작성·실행 |
| `.planning/decisions/` | 기술 결정 기록 (ADR) |
