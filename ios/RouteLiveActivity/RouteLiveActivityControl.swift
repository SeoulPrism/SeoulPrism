// 제어 센터 (Control Center) 위젯 — iOS 18+.
// "Seoul Vista 지도 열기" 버튼 — 누르면 com.seoul.prism://map URL 로 앱 진입.

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct RouteLiveActivityControl: ControlWidget {
    static let kind: String = "com.seoul.prism.RouteLiveActivity.openMap"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenSeoulVistaMapIntent()) {
                Label("Seoul Vista", systemImage: "map.fill")
            }
        }
        .displayName("Seoul Vista 지도")
        .description("제어 센터에서 빠르게 지도 열기")
    }
}

@available(iOS 18.0, *)
struct OpenSeoulVistaMapIntent: AppIntent {
    static let title: LocalizedStringResource = "Seoul Vista 지도 열기"
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        return .result(opensIntent: OpenURLIntent(URL(string: "com.seoul.prism://map")!))
    }
}
