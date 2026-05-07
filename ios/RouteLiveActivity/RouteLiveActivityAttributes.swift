// Live Activity 데이터 정의.
// Runner (앱) 와 RouteLiveActivityExtension (Widget) 양쪽 target 에 모두 포함되어야 함.
// Apple 공식 권장: ActivityAttributes 는 두 모듈에 동일하게 컴파일됨.

import ActivityKit
import Foundation

struct RouteLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var headline: String       // 예: "143번 버스 → 강남역"
        var detail: String         // 예: "143번 5분"
        var etaMinutes: Int        // 다이나믹 아일랜드 minimal 영역 큰 숫자
        var lineColorHex: String?  // 노선 색 (#RRGGBB)
        var totalMinutes: Int      // 전체 길찾기 잔여 분
    }

    var destination: String  // 최종 도착지 (활동 동안 변하지 않음)
}
