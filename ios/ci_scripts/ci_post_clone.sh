#!/bin/sh

# 1. 홈브류를 통해 Flutter 설치 (또는 특정 경로 사용)
brew install --cask flutter

# 2. Flutter 경로 설정
export PATH="$PATH:/usr/local/bin"

# 3. Flutter 의존성 해결 및 프로젝트 구성
flutter pub get

# 4. CocoaPods 설치 및 업데이트
brew install cocoapods
pod install

# 5. Flutter 빌드에 필요한 xcconfig 파일 강제 생성
flutter build ios --config-only --release