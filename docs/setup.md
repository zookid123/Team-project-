# Setup

새 사람이 이 문서만 보고 5분 안에 실행할 수 있어야 합니다.

---

## 1. 사전 요구사항

| 도구 | 권장 버전 | 확인 명령 | 설치 링크 |
|------|----------|----------|----------|
| Flutter | 3.x 이상 | `flutter --version` | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart | Flutter 포함 | `dart --version` | Flutter 설치 시 자동 포함 |
| Git | 2.40+ | `git --version` | [git-scm.com](https://git-scm.com) |
| Android Studio | 최신 Stable | `adb --version` | [developer.android.com](https://developer.android.com/studio) |
| Xcode | 15.0+ (macOS 전용) | `xcode-select --version` | Mac App Store |

---

## 2. 클론

```bash
git clone https://github.com/zookid123/Team-project-.git
cd Team-project-
```

---

## 3. 의존성 설치

```bash
flutter pub get
```

---

## 4. 환경 확인

```bash
flutter doctor
```

모든 항목에 ✅ 가 뜨면 준비 완료.
⚠️ 가 있으면 해당 항목 설치 후 다시 확인.

---

## 5. 첫 실행

```bash
# 에뮬레이터 또는 실제 기기 연결 후
flutter run
```

성공 시: 메인 메뉴 화면이 기기/에뮬레이터에 표시됩니다.

---

## 6. 플랫폼별 빌드

### Android

```bash
flutter build apk --release
# 결과물: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (macOS 전용)

```bash
flutter build ios --release
# Xcode에서 Runner.xcworkspace 열고 서명 후 빌드
```

---

## 7. 자주 묻는 문제 (FAQ)

### Q1. `flutter pub get` 실패해요
Flutter SDK 경로가 PATH에 등록되어 있는지 확인하세요.
```bash
which flutter   # macOS/Linux
where flutter   # Windows
```

### Q2. Android 에뮬레이터가 안 떠요
Android Studio → AVD Manager에서 에뮬레이터를 먼저 생성하세요.
API 레벨 30 이상 권장.

### Q3. iOS 빌드 시 인증서 오류
Xcode → Signing & Capabilities → Team을 개인 Apple ID로 설정.
`Automatically manage signing` 체크.

### Q4. `flutter doctor`에서 라이선스 오류
```bash
flutter doctor --android-licenses
# 모두 y 입력
```

### Q5. 저장 데이터 초기화가 필요해요
앱 설정 → 저장 데이터 삭제, 또는 에뮬레이터에서 앱 삭제 후 재설치.

---

## 8. 실행 성공 기준

| 항목 | 확인 방법 |
|------|----------|
| 메인 메뉴 화면 표시 | `flutter run` 후 기기에 화면 출력 |
| 던전 입장 가능 | 시작 버튼 탭 → 던전 화면 전환 |
| Hot Reload 동작 | 코드 수정 후 `r` 입력 → 즉시 반영 |
