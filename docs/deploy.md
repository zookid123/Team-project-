# Deploy

## 빌드 & 배포 전체 흐름

```
코드 작성 → flutter build → 서명 → 배포 채널 업로드
```

---

## 1. 사전 준비

### Android
```bash
# 서명 키 생성 (최초 1회)
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

`android/key.properties` 파일 생성:
```
storePassword=<비밀번호>
keyPassword=<비밀번호>
keyAlias=upload
storeFile=upload-keystore.jks
```

> ⚠️ `key.properties` 와 `.jks` 파일은 절대 git에 올리지 마세요. `.gitignore`에 추가 필수.

### iOS (macOS 전용)
- Apple Developer 계정 필요
- Xcode → Signing & Capabilities → Team 설정

---

## 2. Android 빌드

### APK (테스트 배포용)
```bash
flutter build apk --release
```
결과물: `build/app/outputs/flutter-apk/app-release.apk`

### AAB (Play Store 배포용)
```bash
flutter build appbundle --release
```
결과물: `build/app/outputs/bundle/release/app-release.aab`

---

## 3. iOS 빌드 (macOS 전용)

```bash
flutter build ios --release
```

Xcode에서:
```
Product → Archive → Distribute App → TestFlight or App Store
```

---

## 4. 배포 채널

### Android — Firebase App Distribution (테스트용)
```bash
# Firebase CLI 설치
npm install -g firebase-tools
firebase login

# 배포
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_APP_ID> \
  --groups "testers"
```

### Android — Google Play (정식 배포)
1. [Google Play Console](https://play.google.com/console) 접속
2. 앱 선택 → 내부 테스트 → 새 버전 만들기
3. AAB 파일 업로드
4. 출시

### iOS — TestFlight
1. Xcode에서 Archive 후 App Store Connect 업로드
2. [App Store Connect](https://appstoreconnect.apple.com) → TestFlight → 빌드 확인
3. 테스터 초대

---

## 5. 버전 관리

`pubspec.yaml` 에서 버전 관리:
```yaml
version: 1.0.0+1
# 형식: 버전이름+빌드번호
# 예: 1.0.1+2
```

배포 전 버전 올리기:
```bash
# pubspec.yaml 수정 후
flutter build apk --release
```

---

## 6. 배포 전 체크리스트

- [ ] `flutter analyze` 오류 없음
- [ ] `flutter test` 전체 통과
- [ ] `pubspec.yaml` 버전 번호 올림
- [ ] 디버그 로그 (`print`, `debugPrint`) 제거
- [ ] API 키가 코드에 하드코딩되어 있지 않음
- [ ] Android 서명 키 설정 완료
- [ ] 실제 기기에서 릴리즈 빌드 테스트

---

## 7. 자주 묻는 문제

### Q1. `keystore` 파일을 잃어버렸어요
Play Store에 이미 올라간 앱은 같은 키로만 업데이트 가능합니다.
백업 필수 — 팀 공유 드라이브에 보관 권장.

### Q2. iOS 빌드 시 "No provisioning profile" 오류
Xcode → Preferences → Accounts → 본인 Apple ID 추가 후
Signing & Capabilities에서 Team 재선택.

### Q3. `flutter build` 시 Gradle 오류
```bash
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get
flutter build apk --release
```
