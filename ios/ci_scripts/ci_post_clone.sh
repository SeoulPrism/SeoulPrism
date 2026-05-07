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

# 4-1. firebase_options.dart 생성 (gitignore 되어 있으므로 CI 에서 환경변수로 복원).
# main.dart 가 이 파일을 import 하므로 누락 시 빌드 즉시 실패.
if [ -n "$FIREBASE_OPTIONS_BASE64" ]; then
  echo "$FIREBASE_OPTIONS_BASE64" | base64 -D > lib/firebase_options.dart
  echo "firebase_options.dart generated from env"
else
  echo "error: FIREBASE_OPTIONS_BASE64 not set — main.dart 의 firebase_options import 가 깨짐"
  exit 1
fi

# 5. Flutter 환경 확인 및 의존성 설치 (DNS 간헐 실패 대비 재시도)
MAX_RETRIES=5
RETRY_DELAY=10

for i in $(seq 1 $MAX_RETRIES); do
  echo "Flutter precache attempt $i/$MAX_RETRIES..."
  if flutter precache --ios; then
    echo "Flutter precache succeeded on attempt $i"
    break
  fi
  if [ $i -eq $MAX_RETRIES ]; then
    echo "Flutter precache failed after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "Retrying in ${RETRY_DELAY}s..."
  sleep $RETRY_DELAY
  RETRY_DELAY=$((RETRY_DELAY * 2))
done

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
