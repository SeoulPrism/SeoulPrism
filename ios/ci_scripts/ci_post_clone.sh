#!/bin/sh

# 에러 발생 시 즉시 중단
set -e

# 1. 프로젝트 루트로 이동 (ios/ci_scripts 기준 상위의 상위)
cd ../..

# 2. Flutter SDK 다운로드 (이미 있으면 스킵)
if [ ! -d "$HOME/developer/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable $HOME/developer/flutter
fi
export PATH="$PATH:$HOME/developer/flutter/bin"

# 3. api_keys.dart 생성 (gitignore 되어있으므로 CI에서 생성)
mkdir -p lib/core
cat > lib/core/api_keys.dart << 'DART'
class ApiKeys {
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: '',
  );
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String seoulApiKey = String.fromEnvironment(
    'SEOUL_API_KEY',
    defaultValue: '',
  );
  static const String dataGoKrApiKey = String.fromEnvironment(
    'DATA_GO_KR_API_KEY',
    defaultValue: '',
  );
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
DART

# 4. GoogleService-Info.plist 생성 (환경변수에서 디코딩)
if [ -n "$GOOGLE_SERVICE_INFO_BASE64" ]; then
  echo "$GOOGLE_SERVICE_INFO_BASE64" | base64 -D > ios/Runner/GoogleService-Info.plist
  echo "GoogleService-Info.plist generated from env"
else
  echo "warning: GOOGLE_SERVICE_INFO_BASE64 not set, Firebase may not work"
fi

# 5. Flutter 환경 확인 및 의존성 설치
flutter precache --ios
flutter pub get

# 6. Generated.xcconfig에 올바른 FLUTTER_ROOT 설정
FLUTTER_ROOT="$(which flutter | xargs dirname | xargs dirname)"
echo "FLUTTER_ROOT=$FLUTTER_ROOT" > ios/Flutter/Generated.xcconfig
flutter build ios --config-only --release --no-tree-shake-icons

# 7. CocoaPods 설치
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods 2>/dev/null || true
cd ios
pod install

exit 0
