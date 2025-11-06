# 빌드 전 체크리스트

## 공통 체크리스트

### 환경 설정
- [ ] `.env.prod` 파일 존재 확인
- [ ] `VITE_API_BASE_URL` 프로덕션 URL 설정
- [ ] 모든 필수 환경변수 설정 완료

### Capacitor 설정
- [ ] `capacitor.config.ts` 확인
  - appId: `kr.co.hklogistics.baechaking.client`
  - appName: `배차킹`
  - webDir: `dist`

### 코드 품질
- [ ] `yarn type-check` 통과
- [ ] `yarn lint` 통과
- [ ] Critical 테스트 통과

### 버전 관리
- [ ] `package.json` 버전 업데이트
- [ ] CHANGELOG.md 업데이트 (선택)

## Android 체크리스트

### Gradle 설정
- [ ] `android/app/build.gradle` 확인
  - versionCode 증가
  - versionName 업데이트

### Signing 설정
- [ ] Release signing key 존재
- [ ] `android/key.properties` 설정 (또는 환경변수)
- [ ] ProGuard 설정 확인

### 권한 설정
- [ ] `android/app/src/main/AndroidManifest.xml` 확인
  - 필요한 권한만 선언
  - 불필요한 권한 제거

## iOS 체크리스트

### Xcode 프로젝트 설정
- [ ] General > Identity 확인
  - Display Name: `배차킹`
  - Bundle Identifier: `kr.co.hklogistics.baechaking.client`
  - Version: 업데이트
  - Build: 증가

### Signing 설정
- [ ] Signing & Capabilities 확인
- [ ] Provisioning Profile 선택
- [ ] Certificate 유효성 확인

### 권한 설정
- [ ] `ios/App/Info.plist` 확인
  - 카메라 권한 설명
  - 위치 권한 설명
  - 불필요한 권한 제거

### CocoaPods
- [ ] `ios/App/Podfile.lock` 최신 상태
- [ ] `pod install` 실행 완료
