# 로그라이크 던전 RPG — 자동전투

> 수백 번 달라지는 던전 속에서, 오직 나의 판단만이 전투를 이끈다.

## 한 줄 설명

자동전투로 진행되지만, 플레이어의 스킬 발동·타겟 지정이 결과를 결정하는 모바일 로그라이크 RPG.

## 플랫폼

**Flutter (Dart)** — iOS / Android

## 빠른 시작

```bash
git clone https://github.com/zookid123/Team-project-.git
cd Team-project-
flutter pub get
flutter run
```

## 문서

| 문서 | 내용 |
|------|------|
| [`docs/setup.md`](docs/setup.md) | 환경 설정 (zero → run) |
| [`docs/architecture.md`](docs/architecture.md) | 시스템 아키텍처 & 다이어그램 |
| [`docs/deploy.md`](docs/deploy.md) | 빌드 & 배포 절차 |
| [`docs/testing.md`](docs/testing.md) | 테스트 작성 & 실행 |
| [`.planning/00-vision.md`](.planning/00-vision.md) | 비전 & 문제 정의 |
| [`.planning/01-requirements.md`](.planning/01-requirements.md) | 사용자 시나리오 & MoSCoW |
| [`.planning/02-wbs.md`](.planning/02-wbs.md) | WBS & 간트 차트 |
| [`.planning/04-schedule.md`](.planning/04-schedule.md) | 6주 일정 |
| [`.planning/decisions/`](.planning/decisions/) | ADR (기술 결정 기록) |
| [`AGENTS.md`](AGENTS.md) | AI Agent 운영 헌법 |
| [`BONUS.md`](BONUS.md) | 가산점 신청 |

## 핵심 기능 (Must)

1. 자동전투 시스템
2. 전투 중 플레이어 개입 포인트 (스킬 발동·타겟 지정)
3. 절차적 던전 생성
4. 10~12분 런 완결 구조
5. 캐릭터 스킬 & 장비 시스템
6. 런 실패 후 메타 보상 (영구 해금)

## 기술 스택

| 항목 | 선택 | 근거 |
|------|------|------|
| 프레임워크 | Flutter (Dart) | 양 OS 동시 지원, Hot Reload |
| 상태관리 | Provider | Flutter 공식 권장, 낮은 학습 비용 |
| 로컬 저장 | Hive | Flutter 전용 최적화, 구조화 데이터 |
| 아키텍처 | Layered + MVVM | 6주 규모에 적합, 역할 분리 명확 |

## 프로젝트 구조

```
lib/
├── presentation/   # 화면 & 위젯
├── application/    # ViewModel (상태·흐름)
├── domain/         # 핵심 게임 로직
└── data/           # 저장·불러오기
```
