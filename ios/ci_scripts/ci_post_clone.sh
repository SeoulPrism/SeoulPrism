#!/bin/sh

# 에러 발생 시 즉시 중단
set -e

# 1. 프로젝트 루트로 이동 (ios/ci_scripts 기준 상위의 상위)
cd ../..

# 2. Flutter SDK 다운로드 (이미 있으면 스킵)
git clone https://github.com/flutter/flutter.git -b stable $HOME/developer/flutter
export PATH="$PATH:$HOME/developer/flutter/bin"

# 3. Flutter 환경 확인 및 의존성 설치
flutter precache
flutter pub get

# 4. CocoaPods 설치 (Xcode Cloud 환경에 맞춰 설치)
# 기본적으로 CocoaPods은 설치되어 있으나, 경로 확인을 위해 실행
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# 5. iOS 빌드 설정 파일 생성 (핵심: Generated.xcconfig 생성)
cd ios
pod install
flutter build ios --config-only --release --no-tree-shake-icons

exit 0