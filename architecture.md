# Architecture

## 앱 목적

자동전투로 진행되는 로그라이크 던전 RPG.  
플레이어의 판단(스킬 발동·타겟 지정)이 결과를 결정한다.

---

## 전체 레이어 구조

```mermaid
flowchart TD
    subgraph P["🖥️ Presentation"]
        direction LR
        S1[MainMenu]
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
        DA1[SaveManager]
        DA2[ScriptableObjects]
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
    participant SaveMgr       as SaveManager<br/>(Data)

    플레이어  ->> BattleHUD    : 스킬 버튼 터치
    BattleHUD ->> BattleVM    : OnSkillTapped(skillId)
    BattleVM  ->> BattleEngine: ExecuteSkill(skillId, target)
    BattleEngine -->> BattleVM: DamageResult
    BattleVM  -->> BattleHUD  : UI 상태 갱신
    BattleEngine ->> SaveMgr  : FlushRunState()
    SaveMgr   -->> BattleEngine: 저장 완료
```

---

## 디렉토리 구조

```
Assets/
├── Scenes/                     # Presentation
│   ├── MainMenu.unity
│   ├── Dungeon.unity
│   └── MetaProgress.unity
├── UI/                         # Presentation
│   ├── BattleHUD.prefab
│   └── RunResult.prefab
├── Scripts/
│   ├── ViewModels/             # ViewModel
│   │   ├── BattleViewModel.cs
│   │   ├── DungeonViewModel.cs
│   │   └── MetaViewModel.cs
│   ├── Domain/                 # Domain
│   │   ├── AutoBattleEngine.cs
│   │   ├── DungeonGenerator.cs
│   │   └── BalanceConfig.cs
│   └── Data/                   # Data
│       ├── SaveManager.cs
│       └── MetaUnlockData.cs
└── SO/                         # ScriptableObject
    ├── CharacterDataSO.asset
    ├── SkillDataSO.asset
    └── RelicDataSO.asset
```

---

## 새 기능 추가 시 파일 위치

| 추가하려는 것 | 위치 |
|-------------|------|
| 새 화면 / UI | `Assets/Scenes` 또는 `Assets/UI` |
| 화면 상태·흐름 로직 | `Assets/Scripts/ViewModels` |
| 게임 규칙·밸런스 수치 | `Assets/Scripts/Domain` |
| 저장·불러오기·SO 정의 | `Assets/Scripts/Data` 또는 `Assets/SO` |

---

## 미결 이슈

- [ ] 씬 전환 방식 — Additive Load vs Single Load
- [ ] 던전 생성 알고리즘 — BSP vs Cellular Automata
- [ ] 이펙트 성능 예산 결정
