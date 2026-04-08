# Seoul Prism (서울 프리즘) 🌈

**"복잡한 도시 데이터를 다각도로 투영하다, 실시간 3D 도시 데이터 가이드"**

Seoul Prism은 서울시 공공데이터를 3D 지도로 시각화하고, Gemini AI를 통해 사용자의 요구사항을 분석하여 동적인 데이터 레이어를 제어하는 플랫폼입니다.

## 🚀 프로젝트 개요
- **플랫폼**: Flutter (Android, iOS, Web)
- **핵심 목표**: 서울시의 다양한 데이터를 3D 레이어로 시각화하여 직관적인 도시 정보를 제공하고, AI 컨트롤러를 통해 맞춤형 정보를 탐색합니다.

## 🛠 기술 스택
- **Framework**: Flutter (Dart)
- **3D Map**: Mapbox Maps SDK for Flutter
- **AI Engine**: Google Gemini API (`google_generative_ai`)
- **Backend**: Supabase (PostgreSQL / PostGIS)
- **State Management**: Riverpod
- **Networking**: Dio (서울 열린데이터광장 API 연동)

## ✨ 핵심 기능
1. **3D 레이어링 시스템 (Multi-Layer Visualization)**
   - **안전 레이어**: 보안등/CCTV 위치 기반 위험도 분석 및 조도 시각화.
   - **활력 레이어**: 실시간 인구 혼잡도(Heatmap) 및 문화행사 정보.
   - **환경 레이어**: 미세먼지/소음 데이터 시각화.
   - **편의 레이어**: 배리어프리(경사로/엘리베이터) 수직 동선 시각화.

2. **AI 시티 컨트롤러 (Gemini AI Integration)**
   - 자연어 쿼리 분석을 통한 데이터 레이어 자동 활성화.
   - 지도 카메라 이동(flyTo) 및 이종 데이터 결합 분석 결과 제공.

## 📂 프로젝트 구조 (Proposed)
```text
lib/
├── models/      # 데이터 모델 (JSON 직렬화 등)
├── views/       # UI 화면 및 위젯
├── services/    # 외부 API 및 서비스 로직 (Mapbox, Gemini, Dio)
├── providers/   # 상태 관리 (Riverpod)
└── utils/       # 공통 유틸리티 및 상수
```

## 📊 데이터 출처
- **서울 열린데이터광장**: 실시간 도시데이터, 보안등/CCTV, 문화행사, 공공서비스 예약 등.
- **기타**: 상권 분석 서비스 및 대중교통 실시간 위치 정보.
