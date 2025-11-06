---
name: mobile-build
description: Android/iOS 앱 빌드 자동화를 제공합니다. 웹 빌드 → Capacitor 동기화 → 네이티브 빌드 과정을 자동화하며, 빌드 전 체크리스트 및 트러블슈팅 가이드를 제공합니다. Major/Minor 워크플로우에서 사용됩니다.
allowed-tools: Bash(yarn build*), Bash(npx cap*), Read
---

# Mobile Build Skill

Android/iOS 앱 빌드 프로세스를 자동화합니다.

## 실행 조건

다음 요청 시 자동으로 실행됩니다:
- "Android 빌드"
- "iOS 빌드"
- "앱 배포"
- "Capacitor 동기화"

## 빌드 프로세스

### Android 빌드

**Step 1: 웹 빌드**
```bash
yarn build:prod
```

**Step 2: Capacitor 동기화**
```bash
npx cap sync android
```

**Step 3: Android Studio 열기**
```bash
npx cap open android
```

Android Studio에서:
1. Build > Generate Signed Bundle / APK
2. APK 선택
3. Signing key 설정
4. Release variant 선택
5. 빌드 실행

### iOS 빌드

**Step 1: 웹 빌드**
```bash
yarn build:prod
```

**Step 2: Capacitor 동기화**
```bash
npx cap sync ios
```

**Step 3: Xcode 열기**
```bash
npx cap open ios
```

Xcode에서:
1. Product > Archive
2. Signing & Capabilities 확인
3. Archive 실행
4. Distribute App

## 빌드 전 체크리스트

### 공통

- [ ] `.env.prod` 파일 확인
- [ ] `VITE_API_BASE_URL` 프로덕션 URL 설정
- [ ] `capacitor.config.ts` 앱 ID 및 이름 확인
- [ ] 버전 번호 업데이트

### Android

- [ ] `android/app/build.gradle` 버전 코드/이름 확인
- [ ] Signing key 설정 (`release` buildType)
- [ ] ProGuard 설정 확인 (난독화)
- [ ] 권한 설정 (`AndroidManifest.xml`)

### iOS

- [ ] Xcode 프로젝트 General > Identity 확인
- [ ] Signing & Capabilities 설정
- [ ] Provisioning Profile 선택
- [ ] 권한 설정 (`Info.plist`)

## 빌드 자동화 스크립트

```bash
#!/bin/bash
# scripts/build-android.sh

echo "🔨 Android 빌드 시작..."

# Step 1: 웹 빌드
echo "📦 웹 빌드 중..."
yarn build:prod

if [ $? -ne 0 ]; then
  echo "❌ 웹 빌드 실패"
  exit 1
fi

# Step 2: Capacitor 동기화
echo "🔄 Capacitor 동기화 중..."
npx cap sync android

if [ $? -ne 0 ]; then
  echo "❌ Capacitor 동기화 실패"
  exit 1
fi

# Step 3: Android Studio 열기
echo "🚀 Android Studio 열기..."
npx cap open android

echo "✅ 빌드 준비 완료. Android Studio에서 APK를 생성하세요."
```

```bash
#!/bin/bash
# scripts/build-ios.sh

echo "🔨 iOS 빌드 시작..."

# Step 1: 웹 빌드
echo "📦 웹 빌드 중..."
yarn build:prod

if [ $? -ne 0 ]; then
  echo "❌ 웹 빌드 실패"
  exit 1
fi

# Step 2: Capacitor 동기화
echo "🔄 Capacitor 동기화 중..."
npx cap sync ios

if [ $? -ne 0 ]; then
  echo "❌ Capacitor 동기화 실패"
  exit 1
fi

# Step 3: Xcode 열기
echo "🚀 Xcode 열기..."
npx cap open ios

echo "✅ 빌드 준비 완료. Xcode에서 Archive를 실행하세요."
```

## 트러블슈팅

### 웹 빌드 실패

**문제**: TypeScript 타입 에러
```bash
yarn type-check  # 타입 에러 확인
```

**문제**: 환경변수 누락
```bash
cat .env.prod  # 환경변수 확인
```

### Capacitor 동기화 실패

**문제**: 플러그인 버전 충돌
```bash
npx cap doctor  # Capacitor 상태 진단
```

**해결**: 플러그인 재설치
```bash
rm -rf node_modules
yarn install
npx cap sync
```

### Android 빌드 실패

**문제**: Gradle 빌드 에러
```bash
cd android
./gradlew clean
cd ..
npx cap sync android
```

**문제**: Signing key 에러
- Android Studio > Build > Generate Signed Bundle 에서 key 생성

### iOS 빌드 실패

**문제**: Provisioning Profile 에러
- Xcode > Signing & Capabilities 에서 Automatically manage signing 체크

**문제**: CocoaPods 에러
```bash
cd ios/App
pod install
cd ../..
```

## 참고 파일

- **checklists/pre-build.md**: 빌드 전 체크리스트
- **checklists/troubleshooting.md**: 트러블슈팅 가이드

## 보고 형식

```markdown
## ✅ 모바일 빌드 완료

### 플랫폼
- Android: ✅ APK 생성 완료
- iOS: ✅ Archive 생성 완료

### 빌드 정보
- App ID: kr.co.hklogistics.baechaking.client
- Version: 1.0.0 (Build 1)
- 환경: Production

### 빌드 산출물
- Android: app-release.apk
- iOS: baechaking.ipa

### 다음 단계
1. 내부 테스트 배포
2. Play Store / App Store 업로드
```
