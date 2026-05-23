# Setup

새 사람이 이 문서만 보고 5분 안에 실행할 수 있어야 합니다.

---

## 1. 사전 요구사항

| 도구 | 권장 버전 | 확인 명령 | 설치 링크 |
|------|----------|----------|----------|
| Unity Hub | 최신 | Unity Hub 앱에서 확인 | [unity.com/download](https://unity.com/download) |
| Unity | 2022.3 LTS | Unity Hub에서 확인 | Unity Hub → Installs |
| Git | 2.40+ | `git --version` | [git-scm.com](https://git-scm.com) |
| Android Studio | 최신 Stable (Android 빌드 시) | `adb --version` | [developer.android.com](https://developer.android.com/studio) |
| Xcode | 15.0+ (iOS 빌드 시, macOS 전용) | `xcode-select --version` | Mac App Store |

---

## 2. 클론

```bash
git clone https://github.com/[팀 계정]/roguelike-dungeon-rpg.git
cd roguelike-dungeon-rpg
```

---

## 3. Unity에서 프로젝트 열기

1. Unity Hub 실행
2. **[Add]** 버튼 클릭 → 클론한 폴더 선택
3. Unity **2022.3 LTS** 버전으로 열기
4. 패키지 임포트 자동 진행 (최초 1~3분 소요, 기다리세요)

---

## 4. 첫 실행 확인

```
Project 창 → Assets/Scenes/MainMenu.unity 더블클릭
→ Play 버튼 클릭
→ 메인 메뉴 화면이 보이면 성공 ✅
```

---

## 5. 빌드 — Android

```
File > Build Settings > Android > [Switch Platform]
Player Settings > Package Name: com.[팀명].roguelike
[Build] > 출력 폴더 선택 > .apk 생성
```

**사전 조건**: Android Studio 설치 + SDK 경로를 Unity에 등록

```
Unity > Edit > Preferences > External Tools > Android SDK
```

---

## 6. 빌드 — iOS (macOS 전용)

```
File > Build Settings > iOS > [Switch Platform]
[Build] > Xcode 프로젝트 폴더 선택
→ Xcode에서 열기 > Signing 설정 > [Run]
```

---

## 7. 자주 묻는 문제 (FAQ)

### Q1. 패키지 임포트 중 에러가 나요
Unity 버전이 **2022.3 LTS**인지 먼저 확인하세요.  
`Window > Package Manager`에서 누락 패키지 수동 설치.

### Q2. Android 빌드 Gradle 동기화 실패
Android Studio 설치 후 SDK 경로를 Unity에 등록하세요.  
JDK 11 이상이 필요합니다.  
`Edit > Preferences > External Tools > JDK`

### Q3. iOS 빌드 인증서 오류
Xcode > **Signing & Capabilities** 탭에서  
Team을 **개인 Apple ID**로 설정, **Automatically manage signing** 체크.

### Q4. 씬 실행 시 NullReferenceException
Inspector에서 SerializeField 미연결 항목 확인.  
Prefab 참조가 끊겼을 경우 드래그로 재연결.

### Q5. 저장 데이터 초기화가 필요해요
아래 경로의 `save.json` 파일을 삭제 후 재실행:
```
# Windows
%USERPROFILE%\AppData\LocalLow\[회사명]\[게임명]\save.json

# macOS
~/Library/Application Support/[회사명]/[게임명]/save.json

# 또는 Unity 에디터에서
Application.persistentDataPath 를 Debug.Log로 출력 후 해당 경로 탐색
```

---

## 8. 실행 성공 기준

| 항목 | 확인 방법 |
|------|----------|
| 메인 메뉴 화면 표시 | Play 모드에서 MainMenu.unity 실행 |
| 던전 입장 가능 | 시작 버튼 → Dungeon.unity 전환 |
| 저장 데이터 생성 | `Application.persistentDataPath` 경로에 `save.json` 생성 확인 |
