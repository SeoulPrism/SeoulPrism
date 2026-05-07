// 다이나믹 아일랜드 + 잠금화면 Live Activity.
// Dart 측 LiveActivityService 가 'seoul_prism/live_activity' MethodChannel 로 트리거.

import ActivityKit
import WidgetKit
import SwiftUI

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

struct RouteLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RouteLiveActivityAttributes.self) { context in
            // 잠금화면 / 배너 UI
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.headline)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(context.state.detail)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                        Text(context.attributes.destination)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.etaMinutes)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("분 후")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "tram.fill")
                        .font(.title2)
                        .foregroundColor(lineColor(context.state.lineColorHex))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.etaMinutes)분")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.headline)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        Text(context.state.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(context.attributes.destination)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("총 \(context.state.totalMinutes)분")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "tram.fill")
                    .foregroundColor(lineColor(context.state.lineColorHex))
            } compactTrailing: {
                Text("\(context.state.etaMinutes)분")
                    .font(.caption.bold())
            } minimal: {
                Text("\(context.state.etaMinutes)")
                    .font(.caption.bold())
                    .foregroundColor(lineColor(context.state.lineColorHex))
            }
            .keylineTint(lineColor(context.state.lineColorHex))
        }
    }

    private func lineColor(_ hex: String?) -> Color {
        guard let hex = hex else { return .white }
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard let v = UInt32(cleaned, radix: 16) else { return .white }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

// 미리보기용 stub
extension RouteLiveActivityAttributes {
    fileprivate static var preview: RouteLiveActivityAttributes {
        RouteLiveActivityAttributes(destination: "강남역")
    }
}

extension RouteLiveActivityAttributes.ContentState {
    fileprivate static var sample: RouteLiveActivityAttributes.ContentState {
        RouteLiveActivityAttributes.ContentState(
            headline: "143번 버스 → 강남역",
            detail: "143번 5분",
            etaMinutes: 5,
            lineColorHex: "#1565C0",
            totalMinutes: 28
        )
    }
}

#Preview("Notification", as: .content, using: RouteLiveActivityAttributes.preview) {
    RouteLiveActivityLiveActivity()
} contentStates: {
    RouteLiveActivityAttributes.ContentState.sample
}
