// 다이나믹 아일랜드 + 잠금화면 Live Activity 데이터 정의.
//
// 적용 방법:
//   1. Xcode → File → New → Target → Widget Extension 으로 새 target 생성
//      (이름 예: "RouteLiveActivity", "Include Live Activity" 체크).
//   2. 생성된 target 폴더에 이 파일과 RouteLiveActivityWidget.swift 를 추가.
//   3. Runner 의 AppDelegate.swift 의 startActivity/updateActivity/stopActivity 주석 블록 활성화.
//   4. Widget Extension target 의 Info.plist 에 NSSupportsLiveActivities = true 추가.

import Foundation
import ActivityKit

@available(iOS 16.1, *)
public struct RouteActivityAttributes: ActivityAttributes {
    public typealias ContentState = RouteContentState

    public struct RouteContentState: Codable, Hashable {
        public var headline: String       // 예: "143번 버스 → 강남역"
        public var detail: String         // 예: "143번 5분"
        public var etaMinutes: Int        // 다이나믹 아일랜드 minimal 영역 큰 숫자
        public var lineColorHex: String?  // 노선 색 (#RRGGBB)
        public var totalMinutes: Int      // 전체 길찾기 잔여 분

        public init(
            headline: String,
            detail: String,
            etaMinutes: Int,
            lineColorHex: String?,
            totalMinutes: Int
        ) {
            self.headline = headline
            self.detail = detail
            self.etaMinutes = etaMinutes
            self.lineColorHex = lineColorHex
            self.totalMinutes = totalMinutes
        }
    }

    public var destination: String  // 최종 도착지 — 활동 동안 변하지 않음

    public init(destination: String) {
        self.destination = destination
    }
}
