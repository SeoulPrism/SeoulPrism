# Seoul Vista

[![Download on the App Store](https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83)](https://apps.apple.com/us/app/seoul-vista/id6764241077)

서울시 공공데이터 실시간 3D 시각화 플랫폼. 지하철 열차의 실시간 위치를 OSM 선로 위에서 60fps로 재현하고, SNS 콘텐츠 기반 AI 하루 플랜을 생성한다.

## 개요

서울 지하철 16개 노선, 442개 역의 열차 운행을 3D 지도에 실시간으로 보여준다. 서울시 열린데이터 API에서 5분 주기로 위치를 수신하고, 시간표 기반 시뮬레이션과 프레임 보간으로 끊김 없는 애니메이션을 구현한다.

## 아키텍처

```
┌──────────────────────────────────────────────────────────┐
│                        App Shell                         │
│     Auth · HomeView · Settings · Profile · Notifications │
├──────────────────────────────────────────────────────────┤
│                      Presentation                        │
│   SubwayOverlay · SubwayPanel · SearchBar                │
│   SnsUploadView · SnsAnalysisView · DayPlanView          │
├──────────────────────────────────────────────────────────┤
│                        Services                          │
│   TrainSimulator · TrainInterpolator                     │
│   SeoulSubwayService · SeoulApiService                   │
│   EnvironmentService · ClosureService                    │
│   GeminiService · DayPlanService · DeviceProfileService  │
├──────────────────────────────────────────────────────────┤
│                      Data / Models                       │
│   RouteGeometry · SubwayModels · SubwayData              │
│   SnsContentModels · SubwayGeoJsonLoader                 │
├──────────────────────────────────────────────────────────┤
│                   Map Abstraction Layer                   │
│            IMapController (Common Interface)              │
│                MapboxEngine (Primary)                     │
├──────────────────────────────────────────────────────────┤
│                  Adaptive UI Layer                        │
│        iOS: Liquid Glass · Android: Material 3            │
│   AdaptiveTabBar · GlassContainer · GlassButton · etc.   │
└──────────────────────────────────────────────────────────┘
```

## 기술 스택

| 구분 | 기술 |
|------|------|
| Framework | Flutter (Dart) |
| Map | Mapbox Maps Flutter SDK |
| Auth/DB | Supabase |
| AI | Gemini 2.0 Flash (Vision + Text) |
| Data | 서울시 열린데이터 REST API |
| Geo | OpenStreetMap GeoJSON, Mapbox Geocoding |
| iOS UI | cupertino_native_better (Liquid Glass) |
| Android UI | Material 3 (Material You) |

## 주요 기능

### 지도 및 시각화
- 서울 지하철 전 노선 실시간 열차 위치 (60fps 보간)
- OSM 실제 선로 곡선을 따르는 경로 추종
- 열차/역 클릭 시 카메라 추적 및 상세 정보 패널
- 배차간격 분석 기반 지연 감지 및 경고
- 일출/일몰 연동 자동 조명, 실시간 날씨 표시
- Demo 모드 (오프라인) / Live 모드 (API 연동) 전환

### AI 플랜 (SNS 콘텐츠 분석)
- 이미지 + 텍스트 + URL 업로드 → Gemini Vision 분석
- 서울 장소/활동/분위기 자동 추출
- 편집 가능한 장소 리스트 (스와이프 삭제)
- 3가지 하루 플랜 자동 생성 (효율적 동선 / 여유로운 산책 / 맛집 중심)
- 실시간 지하철 경로 최적화 (Dijkstra + data.go.kr API)
- 3D 지도에 경로 + 마커 시각화

### 인증
- 이메일/비밀번호 로그인 및 회원가입
- Google, Apple 소셜 로그인
- 게스트(익명) 모드 — 30일 미사용 시 자동 삭제
- 아이디 찾기, 비밀번호 재설정, 회원 탈퇴

### Platform-Adaptive UI
- iOS: cupertino_native_better 리퀴드 글라스 디자인
- Android: Material 3 (Material You) 디자인
- 양 플랫폼 완전 독립 UI — adaptive 위젯 레이어로 분기

### 라이트/다크 모드
- 설정에서 라이트/다크 전환
- 지도 위 패널: 라이트 → 밝은 글라스 + 검정 글씨, 다크 → 어두운 글라스 + 흰 글씨
- 프로필/설정/알림 등 독립 페이지: colorScheme 기반 자동 대응

### 기기별 성능 최적화
- 앱 시작 시 기기 모델 자동 감지 (Samsung, Pixel, iPhone, iPad 등)
- 성능 등급별 FPS/폴링 주기 자동 설정
- 설정에서 FPS/네이버 폴링 슬라이더로 커스텀 조절 가능

## 다크/라이트 모드 주의사항

| 영역 | 다크모드 | 라이트모드 |
|------|---------|-----------|
| 지도 위 설정 패널 | 어두운 글라스 (black 40~65%) + 흰 글씨 | 밝은 글라스 (white 70~85%) + 검정 글씨 |
| 지도 위 AI 플랜 패널 | 위와 동일 | 위와 동일 |
| 지도 자체 (라이팅) | 시간 기반 독립 (dawn/day/dusk/night) | 시간 기반 독립 |
| 프로필/설정/알림 페이지 | colorScheme.surface (어두운 배경) | colorScheme.surface (밝은 배경) |
| 열차/역 상세 패널 | surfaceContainer 기반 | surfaceContainer 기반 |

> 지도 라이팅(주간/야간)과 앱 테마(다크/라이트)는 **독립적**으로 동작합니다.
> 예: 다크모드 + 주간 맵 = 밝은 지도 위에 어두운 패널

## 데이터 소스

| API | 용도 |
|-----|------|
| OA-12601 | 열차 실시간 위치 (5분 주기) |
| OA-12764 | 역별 도착 예정 정보 |
| OA-15799 | 전체 역 도착정보 일괄 조회 |
| OA-22122 | 시설 임시폐쇄 안내 |
| Open-Meteo | 실시간 날씨 |
| Gemini API | SNS 콘텐츠 분석 (Vision + Text) |
| Mapbox Geocoding | 장소명 → 좌표 변환 |

## 설정

`lib/core/api_keys.dart`에 키 입력 (gitignore 처리됨, 빌드 시 `--dart-define`으로 주입):
```dart
class ApiKeys {
  static const String mapboxAccessToken = '...';
  static const String supabaseUrl = '...';
  static const String supabaseAnonKey = '...';
  static const String seoulApiKey = '...';
  static const String geminiApiKey = '...';
}
```

플랫폼별:
- Android: `gradle.properties`에 `MAPBOX_DOWNLOADS_TOKEN`
- iOS: Podfile 배포 타겟 15.0
- Google 로그인: GCP에 Android SHA-1 등록 (디버그 + 릴리즈 + Play App Signing)

## 폴더 구조

```
lib/
├── core/             # IMapController 인터페이스, API 키
├── map_engines/      # Mapbox 엔진 구현
├── models/           # 도메인 모델 (지하철, SNS 콘텐츠)
├── data/             # 역/노선 정적 데이터, GeoJSON 로더
├── services/         # API 클라이언트, 시뮬레이터, 보간 엔진, AI, 기기 프로필
├── theme/            # Material 3 라이트/다크 테마
├── widgets/
│   ├── adaptive/     # Platform-adaptive 위젯 (iOS Glass / Android M3)
│   └── ...           # 지도 오버레이, 패널, 검색바
└── views/            # 인증, 홈, 지도, 프로필, 설정, AI 플랜, 알림
```

## 로드맵

- [x] Mapbox 3D 지도 + 멀티 엔진 추상화
- [x] 서울시 API 연동 (5종)
- [x] 시간표 기반 60fps 보간 엔진
- [x] 16개 노선 442역 경로 시각화
- [x] 열차/역 인터랙션 및 카메라 추적
- [x] 지연 감지 시스템
- [x] 환경 시스템 (날씨, 조명)
- [x] 인증 (이메일, Google, Apple) + 게스트 모드
- [x] Platform-adaptive UI (iOS Liquid Glass / Android Material 3)
- [x] 라이트/다크 모드
- [x] SNS AI 플랜 (Gemini Vision)
- [x] Gemini Live AI 음성 비서
- [x] 기기별 자동 성능 최적화
- [x] 혼잡도 히트맵
- [x] 길찾기 (지하철 + 자동차 + 도보, TMAP turn-by-turn)
- [x] 다이나믹 아일랜드 길찾기 라이브 액티비티
- [x] 온보딩 튜토리얼 + 시그니처 로딩 시퀀스
- [x] 여행 탭 (저장 장소 기반 하루 플랜)
- [x] **App Store 출시** (2026-05)
- [ ] 2~9호선 역간소요시간 실측 수집
- [ ] 코레일 기차 모드
- [ ] AI 카메라 애니메이션
- [ ] 버스 오프라인 데이터 + 통합 길찾기

## 버전

| 버전 | 내용 |
|------|------|
| v1.0.0-beta | 초기 릴리즈 (지도 + 인증 + 민감정보 제거) |
| v1.0.0-beta3 | Platform-adaptive UI 시스템 |
| v1.0.0-beta4 | Android Google 로그인 수정 |
| v1.0.0-beta5 | AI 플랜 + 라이트/다크 모드 + 기기별 성능 최적화 + 검색 개선 |
| v1.0.1-beta | Gemini Live AI 음성 비서 통합 |
| v1.0.2 | Apple 심사 재제출 + 길찾기 능동화 + 다이나믹 아일랜드 + 게스트 모드 |
| v1.0.3 | 온보딩 튜토리얼 + 여행 탭(저장 장소 기반 하루 플랜) + 설정 통합 + 디버그 로그 토글 |
| **v1.0.3 (출시)** | **App Store 정식 출시 — Seoul Vista** |
