# SeoulPrism

서울시 공공데이터 실시간 3D 시각화 플랫폼. 지하철 열차의 실시간 위치를 OSM 선로 위에서 60fps로 재현한다.

## 개요

서울 지하철 16개 노선, 442개 역의 열차 운행을 3D 지도에 실시간으로 보여준다. 서울시 열린데이터 API에서 5분 주기로 위치를 수신하고, 시간표 기반 시뮬레이션과 프레임 보간으로 끊김 없는 애니메이션을 구현한다.

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                     App Shell                       │
│        Auth · HomeView · Settings · Profile         │
├─────────────────────────────────────────────────────┤
│                    Presentation                     │
│     SubwayOverlay · SubwayPanel · SearchBar         │
├─────────────────────────────────────────────────────┤
│                      Services                       │
│    TrainSimulator · TrainInterpolator               │
│    SeoulSubwayService · SeoulApiService             │
│    EnvironmentService · ClosureService              │
├─────────────────────────────────────────────────────┤
│                    Data / Models                    │
│    RouteGeometry · SubwayModels · SubwayData        │
│    SubwayGeoJsonLoader                              │
├─────────────────────────────────────────────────────┤
│                 Map Abstraction Layer               │
│          IMapController (Common Interface)          │
│              MapboxEngine (Primary)                 │
└─────────────────────────────────────────────────────┘
```

## 기술 스택

| 구분 | 기술 |
|------|------|
| Framework | Flutter (Dart) |
| Map | Mapbox Maps Flutter SDK |
| Auth/DB | Supabase |
| Data | 서울시 열린데이터 REST API |
| Geo | OpenStreetMap GeoJSON |

## 주요 기능

**지도 및 시각화**
- 서울 지하철 전 노선 실시간 열차 위치 (60fps 보간)
- OSM 실제 선로 곡선을 따르는 경로 추종
- 열차/역 클릭 시 카메라 추적 및 상세 정보 패널
- 배차간격 분석 기반 지연 감지 및 경고
- 일출/일몰 연동 자동 조명, 실시간 날씨 표시
- Demo 모드 (오프라인) / Live 모드 (API 연동) 전환

**인증**
- 이메일/비밀번호 로그인 및 회원가입
- Google, Apple 소셜 로그인
- 아이디 찾기, 비밀번호 재설정, 회원 탈퇴

## 데이터 소스

| API | 용도 |
|-----|------|
| OA-12601 | 열차 실시간 위치 (5분 주기) |
| OA-12764 | 역별 도착 예정 정보 |
| OA-15799 | 전체 역 도착정보 일괄 조회 |
| OA-22122 | 시설 임시폐쇄 안내 |
| Open-Meteo | 실시간 날씨 |

## 설정

`lib/core/api_keys.dart`에 키 입력:
```dart
class ApiKeys {
  static const String mapboxAccessToken = '...';
  static const String seoulApiKey = '...';
  static const String dataGoKrApiKey = '';
}
```

플랫폼별:
- Android: `gradle.properties`에 `MAPBOX_DOWNLOADS_TOKEN`
- iOS: Podfile 배포 타겟 15.0

## 폴더 구조

```
lib/
├── core/           # IMapController 인터페이스, API 키
├── map_engines/    # Mapbox 엔진 구현
├── models/         # 도메인 모델
├── data/           # 역/노선 정적 데이터, GeoJSON 로더
├── services/       # API 클라이언트, 시뮬레이터, 보간 엔진
├── theme/          # Material 3 Dark 테마
├── widgets/        # 지도 오버레이, 패널, 검색바
└── views/          # 인증, 홈, 지도, 프로필, 설정
```

## 로드맵

- [x] Mapbox 3D 지도 + 멀티 엔진 추상화
- [x] 서울시 API 연동 (5종)
- [x] 시간표 기반 60fps 보간 엔진
- [x] 16개 노선 442역 경로 시각화
- [x] 열차/역 인터랙션 및 카메라 추적
- [x] 지연 감지 시스템
- [x] 환경 시스템 (날씨, 조명)
- [x] 인증 (이메일, Google, Apple)
- [ ] 2~9호선 역간소요시간 실측 수집
- [ ] 혼잡도 히트맵
- [ ] 코레일 기차 모드
- [ ] AI 카메라 애니메이션
