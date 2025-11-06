---
name: platform-detection
description: Capacitor 플랫폼별 조건부 렌더링 패턴을 제공합니다. app/desktop-web/mobile-web 감지 및 네이티브 API 사용 시 웹 폴백을 자동으로 생성합니다. Major/Minor 워크플로우에서 사용됩니다.
allowed-tools: Read, Write, Grep
---

# Platform Detection Skill

Capacitor 플랫폼 감지 및 조건부 렌더링 패턴을 자동화합니다.

## 실행 조건

다음 요청 시 자동으로 실행됩니다:
- "플랫폼별 UI 분기"
- "모바일 앱과 웹 분리"
- "Capacitor 네이티브 API 사용"

## 플랫폼 종류

프로젝트는 3가지 플랫폼을 지원합니다:

- **app**: Capacitor 모바일 앱 (Android/iOS)
- **desktop-web**: 데스크톱 브라우저
- **mobile-web**: 모바일 브라우저

## usePlatformStore 활용

```typescript
import { usePlatformStore } from '@/app/model/stores';

function Component() {
  const platform = usePlatformStore((state) => state.platform);

  if (platform === 'app') {
    return <NativeComponent />;
  }

  if (platform === 'mobile-web') {
    return <MobileWebComponent />;
  }

  return <DesktopComponent />;
}
```

## 조건부 렌더링 패턴

### 1. if 문 분기

```typescript
export function CameraFeature() {
  const platform = usePlatformStore((state) => state.platform);

  if (platform === 'app') {
    return <NativeCamera />;
  }

  return <WebFileUpload />;
}
```

### 2. PlatformWrapper 컴포넌트

```typescript
// shared/ui/PlatformWrapper.tsx (생성 필요)
interface Props {
  app?: React.ReactNode;
  web?: React.ReactNode;
  mobileWeb?: React.ReactNode;
  desktopWeb?: React.ReactNode;
}

export function PlatformWrapper({ app, web, mobileWeb, desktopWeb }: Props) {
  const platform = usePlatformStore((state) => state.platform);

  if (platform === 'app' && app) return <>{app}</>;
  if (platform === 'mobile-web' && mobileWeb) return <>{mobileWeb}</>;
  if (platform === 'desktop-web' && desktopWeb) return <>{desktopWeb}</>;
  if (web) return <>{web}</>;

  return null;
}

// 사용
<PlatformWrapper
  app={<NativeCamera />}
  web={<WebFileUpload />}
/>
```

## 네이티브 API with 웹 폴백

### 카메라 API

```typescript
// features/camera/model/useCamera.ts
import { Camera, CameraResultType } from '@capacitor/camera';
import { usePlatformStore } from '@/app/model/stores';

export function useCamera() {
  const platform = usePlatformStore((state) => state.platform);

  const takePicture = async () => {
    if (platform !== 'app') {
      // 웹 폴백: file input
      return await webFilePicker();
    }

    const image = await Camera.getPhoto({
      quality: 90,
      allowEditing: false,
      resultType: CameraResultType.Uri,
    });

    return image.webPath;
  };

  return { takePicture };
}

// 웹 폴백 구현
async function webFilePicker(): Promise<string> {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) {
        const url = URL.createObjectURL(file);
        resolve(url);
      } else {
        reject('No file selected');
      }
    };
    input.click();
  });
}
```

### 위치 정보 API

```typescript
// features/location/model/useGeolocation.ts
import { Geolocation } from '@capacitor/geolocation';
import { usePlatformStore } from '@/app/model/stores';

export function useGeolocation() {
  const platform = usePlatformStore((state) => state.platform);

  const getCurrentPosition = async () => {
    if (platform !== 'app') {
      // 웹 폴백: navigator.geolocation
      return new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(
          (pos) => resolve({
            latitude: pos.coords.latitude,
            longitude: pos.coords.longitude,
          }),
          reject
        );
      });
    }

    const position = await Geolocation.getCurrentPosition();
    return {
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
    };
  };

  return { getCurrentPosition };
}
```

## 플랫폼별 스타일

### Tailwind 조건부 클래스

```typescript
import { cn } from '@/shared/lib/utils';

export function ResponsiveLayout({ children }: Props) {
  const platform = usePlatformStore((state) => state.platform);

  return (
    <div
      className={cn(
        'container',
        platform === 'mobile-web' && 'px-4',
        platform === 'desktop-web' && 'max-w-7xl mx-auto px-8',
        platform === 'app' && 'safe-area-inset'
      )}
    >
      {children}
    </div>
  );
}
```

### CSS Safe Area (iOS)

```css
/* iOS 노치 대응 */
.safe-area-inset {
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  padding-left: env(safe-area-inset-left);
  padding-right: env(safe-area-inset-right);
}
```

## 템플릿

**templates/platform-wrapper.tsx**: PlatformWrapper 컴포넌트 템플릿

## 보고 형식

```markdown
## ✅ 플랫폼 감지 설정 완료

### 생성된 파일
- shared/ui/PlatformWrapper.tsx (조건부 렌더링 컴포넌트)
- features/camera/model/useCamera.ts (네이티브 + 웹 폴백)

### 플랫폼 분기
- app: Native Camera API
- web: File input 폴백

### 테스트
- Android: ✅ 네이티브 카메라 동작
- iOS: ✅ 네이티브 카메라 동작
- Web: ✅ 파일 선택 폴백 동작
```
