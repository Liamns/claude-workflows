# 빌드 트러블슈팅 가이드

## 공통 문제

### 웹 빌드 실패

**증상**: `yarn build:prod` 실패

**원인 1: TypeScript 타입 에러**
```bash
# 진단
yarn type-check

# 해결
# 타입 에러 수정 후 재빌드
```

**원인 2: 환경변수 누락**
```bash
# 진단
cat .env.prod

# 해결
# .env.prod 파일에 모든 필수 환경변수 추가
```

**원인 3: 의존성 문제**
```bash
# 해결
rm -rf node_modules
yarn install
yarn build:prod
```

### Capacitor 동기화 실패

**증상**: `npx cap sync` 실패

**원인 1: 플러그인 버전 충돌**
```bash
# 진단
npx cap doctor

# 해결
npm update @capacitor/core @capacitor/cli
npx cap sync
```

**원인 2: dist 디렉토리 없음**
```bash
# 해결
yarn build:prod
npx cap sync
```

## Android 문제

### Gradle 빌드 실패

**증상**: Android Studio 빌드 에러

**원인 1: Gradle cache 문제**
```bash
# 해결
cd android
./gradlew clean
cd ..
npx cap sync android
```

**원인 2: JDK 버전 문제**
```bash
# 진단
java -version

# 해결
# JDK 17 설치 및 Android Studio에서 JDK 경로 설정
```

### Signing Key 에러

**증상**: Release 빌드 시 signing key 에러

**해결**:
1. Android Studio > Build > Generate Signed Bundle
2. Create new key store
3. 정보 입력 후 생성
4. `android/key.properties` 파일 생성:
   ```properties
   storeFile=my-release-key.keystore
   storePassword=password
   keyAlias=my-key-alias
   keyPassword=password
   ```

### ProGuard 에러

**증상**: Release 빌드 후 앱 크래시

**해결**:
`android/app/proguard-rules.pro`에 keep 규칙 추가:
```proguard
-keep class com.getcapacitor.** { *; }
-keep class capacitor.** { *; }
```

## iOS 문제

### Provisioning Profile 에러

**증상**: Code signing 에러

**해결**:
1. Xcode > Signing & Capabilities
2. "Automatically manage signing" 체크
3. Team 선택
4. Provisioning Profile 자동 생성 확인

### CocoaPods 에러

**증상**: `pod install` 실패

**해결 1: Repo 업데이트**
```bash
pod repo update
cd ios/App
pod install
```

**해결 2: Cache 삭제**
```bash
cd ios/App
rm -rf Pods
rm Podfile.lock
pod install
```

### Archive 실패

**증상**: Product > Archive 실패

**원인 1: 빌드 설정 문제**
- Scheme을 "App" (Release)로 설정
- Destination을 "Any iOS Device"로 설정

**원인 2: Bitcode 에러**
```
Build Settings > Enable Bitcode > NO
```

## 런타임 문제

### 앱 실행 시 흰 화면

**원인**: Capacitor 초기화 실패

**진단**:
```bash
# iOS
npx cap run ios

# Android
npx cap run android

# 로그 확인
```

**해결**:
1. `capacitor.config.ts` 확인
2. webDir이 `dist`인지 확인
3. 웹 빌드 후 재동기화

### 네이티브 플러그인 동작 안 함

**원인**: 권한 설정 누락

**Android 해결**:
`AndroidManifest.xml`에 권한 추가
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS 해결**:
`Info.plist`에 설명 추가
```xml
<key>NSCameraUsageDescription</key>
<string>사진 촬영을 위해 카메라 권한이 필요합니다</string>
```

### API 호출 실패

**원인**: 프로덕션 API URL 미설정

**해결**:
1. `.env.prod` 확인
2. `VITE_API_BASE_URL` 프로덕션 URL 설정
3. 재빌드 및 재배포
