# Architecture

## 앱 목적

자동전투로 진행되는 로그라이크 던전 RPG.
플레이어의 판단(스킬 발동·타겟 지정)이 결과를 결정한다.

---

## 플랫폼

**Flutter (Dart)** — iOS / Android 동시 지원
- 근거: [ADR-0001](./../.planning/decisions/ADR-0001-mobile-framework.md)

---

## 레이어 구조

```mermaid
flowchart TD
    subgraph P["🖥️ Presentation"]
        direction LR
        S1[MainMenuScreen]
        S2[DungeonScreen]
        S3[BattleHUD]
        S4[MetaScreen]
    end

    subgraph VM["⚙️ ViewModel"]
        direction LR
        V1[DungeonViewModel]
        V2[BattleViewModel]
        V3[MetaViewModel]
    end

    subgraph D["🧠 Domain"]
        direction LR
        D1[DungeonGenerator]
        D2[AutoBattleEngine]
        D3[BalanceConfig]
    end

    subgraph DA["💾 Data"]
        direction LR
        DA1[SaveRepository]
        DA2[LocalDataSource]
    end

    P  -->|"이벤트 전달"| VM
    VM -->|"유스케이스 호출"| D
    D  -->|"저장 / 읽기"| DA

    style P  fill:#FAECE7,stroke:#D85A30,color:#712B13
    style VM fill:#EEEDFE,stroke:#7F77DD,color:#3C3489
    style D  fill:#E1F5EE,stroke:#1D9E75,color:#085041
    style DA fill:#FAEEDA,stroke:#EF9F27,color:#633806
```

---

## 사용자 액션 흐름

> 플레이어가 전투 중 스킬을 발동하는 순간

```mermaid
sequenceDiagram
    actor 플레이어
    participant BattleHUD     as BattleHUD<br/>(Presentation)
    participant BattleVM      as BattleViewModel<br/>(ViewModel)
    participant BattleEngine  as AutoBattleEngine<br/>(Domain)
    participant SaveRepo      as SaveRepository<br/>(Data)

    플레이어  ->> BattleHUD    : 스킬 버튼 탭
    BattleHUD ->> BattleVM    : onSkillTapped(skillId)
    BattleVM  ->> BattleEngine: executeSkill(skillId, target)
    BattleEngine -->> BattleVM: DamageResult
    BattleVM  -->> BattleHUD  : state 갱신 (Provider)
    BattleEngine ->> SaveRepo : flushRunState()
    SaveRepo  -->> BattleEngine: 저장 완료
```

---

## 디렉토리 구조

```
lib/
├── main.dart
├── app.dart
├── presentation/             # Presentation
│   ├── screens/
│   │   ├── main_menu_screen.dart
│   │   ├── dungeon_screen.dart
│   │   └── meta_screen.dart
│   └── widgets/
│       └── battle_hud.dart
├── application/              # ViewModel
│   ├── battle_view_model.dart
│   ├── dungeon_view_model.dart
│   └── meta_view_model.dart
├── domain/                   # Domain
│   ├── auto_battle_engine.dart
│   ├── dungeon_generator.dart
│   └── balance_config.dart
└── data/                     # Data
    ├── save_repository.dart
    └── local_data_source.dart
```

---

## 새 기능 추가 시 파일 위치

| 추가하려는 것 | 위치 |
|-------------|------|
| 새 화면 | `lib/presentation/screens/` |
| 화면 상태·흐름 로직 | `lib/application/` |
| 게임 규칙·밸런스 수치 | `lib/domain/` |
| 저장·불러오기 | `lib/data/` |

---

## 미결 이슈

- [ ] 상태관리 라이브러리 확정 — Provider vs Riverpod (ADR-0002)
- [ ] 로컬 저장 방식 확정 — SharedPreferences vs Hive (ADR-0003)
- [ ] 던전 생성 알고리즘 — BSP vs Cellular Automata
