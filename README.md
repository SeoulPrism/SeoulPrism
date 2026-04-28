# SeoulPrism

서울시 공공데이터를 **3D 지도 위에 실시간 시각화**하는 모바일 플랫폼이다. 서울 지하철 네트워크의 실시간 운행 상황을 60fps 보간 엔진으로 재현하며, MiniTokyo3D의 서울 버전을 Flutter 환경에서 구현하는 것을 목표로 한다.

## 핵심 가치

| 가치 | 설명 |
|------|------|
| **실시간성** | 서울시 열린데이터 API 5분 주기 수신 + 60fps 프레임 보간으로 끊김 없는 열차 이동 |
| **정밀성** | OSM 실제 노선 지오메트리 기반 경로 추종 — 직선이 아닌 실제 선로 곡선을 따라 이동 |
| **확장성** | 멀티 지도 엔진 추상화 계층을 통해 Mapbox, Google Maps, Naver Map 간 자유 전환 |
| **개방성** | 서울시 공공데이터(5종) 기반, 별도 수집 인프라 없이 운영 가능 |

---

## 기술 스택

- **Framework**: Flutter 3.x (Dart)
- **Map Engine**: Mapbox Maps Flutter SDK 2.x
- **Backend/Auth**: Supabase (PostgreSQL, Auth)
- **Data**: 서울시 열린데이터 광장 REST API (5종)
- **Geo**: OpenStreetMap GeoJSON (서울 지하철 노선 경로)
- **Rendering**: Material 3 Dark Theme, 60fps 애니메이션 타이머

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
│    MapboxEngine · GoogleMapEngine · NaverEngine     │
└─────────────────────────────────────────────────────┘
```

`IMapController` 인터페이스가 카메라 제어, 마커/폴리라인 관리, 3D 레이어 렌더링, 지하철 전용 확장을 통일된 API로 제공한다.

---

## 핵심 기능

### 실시간 열차 위치 시각화

서울 지하철 16개 노선(1~9호선, 경의중앙, 수인분당, 신분당 등)의 실시간 열차 위치를 3D 지도에 표시한다.

1. 서울시 API에서 5분 주기로 전체 열차 위치 스냅샷 수신
2. `TrainSimulator`가 시간표 기반 `position = f(현재시각)` 순수 함수로 외삽
3. `TrainInterpolator`가 OSM GeoJSON 지오메트리를 따라 프레임 단위 좌표 계산
4. 60fps 타이머로 매 프레임 마커 위치 갱신
5. API 갱신 시 1.5초 블렌딩으로 시각적 점프 방지

### 열차/역 인터랙션

- 열차 클릭 → 카메라 추적 (60fps), 노선색 발광 링 펄스
- 역 클릭 → 실시간 도착정보 패널 (카운트다운, 행선지, 급행/막차)
- 열차 상세 바텀 패널: 노선명, 방향, 이전역→현재역→다음역

### 실시간 지연 감지

- 배차간격 비교 방식으로 열차별 지연 시간 산출
- 지연 열차 3D 블록 빨간 톤 + 펄스 발광 링
- 컨트롤 패널에 "지연 열차 N대" 배너 자동 표시

### 환경 시스템

- 서울 좌표 기반 일출/일몰 자동 계산
- Open-Meteo API 실시간 날씨 (5분 주기)
- Mapbox Standard `lightPreset` 자동 전환 (dawn/day/dusk/night)

### 인증 시스템

- 이메일/비밀번호 회원가입·로그인
- Google / Apple 소셜 로그인
- 아이디 찾기 / 비밀번호 재설정
- 회원 탈퇴 (Apple 5.1.1 준수)

### 운영 모드

| 모드 | 설명 |
|------|------|
| **Live** | 서울시 API 실시간 데이터. 일일 쿼터 자동 관리 |
| **Demo** | 가상 열차 생성. 네트워크 없이 시연 가능 |

---

## 데이터 소스

| API 코드 | 명칭 | 용도 |
|-----------|------|------|
| OA-12601 | 지하철 실시간 열차 위치정보 | 열차 현재 위치 (5분 주기) |
| OA-12764 | 지하철 실시간 도착정보 | 특정 역 도착 예정 열차 |
| OA-15799 | 지하철 실시간 도착정보 (일괄) | 전체 역 일괄 조회 |
| OA-21213 | 지하철역 연계 지하도 공간정보 | 역 지하공간 WKT 좌표 |
| OA-22122 | 지하철 시설 임시폐쇄 정보 | 출입구 폐쇄 안내 |

OSM GeoJSON: 서울 지하철 전 노선 실제 선로 좌표 (13개 노선, 442역).

---

## 설정 방법

### API 키 설정

`lib/core/api_keys.dart` 생성 (`.gitignore` 처리됨):
```dart
class ApiKeys {
  static const String mapboxAccessToken = 'YOUR_MAPBOX_TOKEN';
  static const String seoulApiKey = 'YOUR_SEOUL_API_KEY';
  static const String dataGoKrApiKey = '';
}
```

### 플랫폼 설정

- **Android**: `gradle.properties`에 `MAPBOX_DOWNLOADS_TOKEN`, `minSdk 24`
- **iOS**: `Podfile` 배포 타겟 15.0, Info.plist 위치 권한

---

## 폴더 구조

```
lib/
├── core/               # 공통 인터페이스, API 키
├── map_engines/        # Mapbox 엔진 구현체
├── models/             # 지하철 도메인 모델
├── data/               # 노선 지오메트리, 역 데이터, GeoJSON 로더
├── services/           # API 연동, 열차 시뮬레이터, 보간 엔진
├── theme/              # Material 3 Dark 테마
├── widgets/            # 오버레이, 패널, 검색바
└── views/              # 인증, 홈, 지도, 프로필, 설정
```

## 로드맵

- [x] 멀티 지도 엔진 래퍼 아키텍처
- [x] Mapbox 3D 건물/지형/조명
- [x] 서울시 공공 API 5종 연동
- [x] MiniTokyo3D 스타일 보간 엔진 (OSM 기반)
- [x] 노선 경로 시각화 (16개 노선, 442역)
- [x] 실시간 열차 위치 오버레이 (60fps)
- [x] 열차/역 클릭 인터랙션 및 카메라 추적
- [x] 실시간 지연 감지 및 시각화
- [x] 환경 시스템 (날씨/일출·일몰/조명)
- [x] 인증 시스템 (이메일, Google, Apple)
- [x] iOS 26 리퀴드 글라스 UI
- [ ] 2~9호선 역간소요시간 수집 (시간표 API 실측)
- [ ] 혼잡도 히트맵 UI 개선
- [ ] 기차 모드 (코레일 API)
- [ ] AI Fly-To 시네마틱 카메라 애니메이션
- [ ] 따릉이 실시간 대여소 현황
- [ ] 도로 교통량 히트맵 오버레이

## 참고

- MiniTokyo3D: https://minitokyo3d.com
- 서울시 열린데이터 광장: https://data.seoul.go.kr
- OpenStreetMap: https://www.openstreetmap.org
