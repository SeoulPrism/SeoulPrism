import WidgetKit
import SwiftUI

@main
struct RouteLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        // 홈화면 위젯 — 최근 길찾기 미리보기
        RouteLiveActivity()
        // 잠금화면/다이나믹 아일랜드 — 진행 중 길찾기
        RouteLiveActivityLiveActivity()
        // 제어 센터 — 지도 열기 (iOS 18+)
        if #available(iOS 18.0, *) {
            RouteLiveActivityControl()
        }
    }
}
