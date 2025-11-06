// shared/ui/PlatformWrapper.tsx
import { usePlatformStore } from '@/app/model/stores';

interface PlatformWrapperProps {
  app?: React.ReactNode;
  web?: React.ReactNode;
  mobileWeb?: React.ReactNode;
  desktopWeb?: React.ReactNode;
}

export function PlatformWrapper({ app, web, mobileWeb, desktopWeb }: PlatformWrapperProps) {
  const platform = usePlatformStore((state) => state.platform);

  if (platform === 'app' && app) {
    return <>{app}</>;
  }

  if (platform === 'mobile-web' && mobileWeb) {
    return <>{mobileWeb}</>;
  }

  if (platform === 'desktop-web' && desktopWeb) {
    return <>{desktopWeb}</>;
  }

  if (web) {
    return <>{web}</>;
  }

  return null;
}
