// 홈화면 위젯 — "최근 길찾기 미리보기".
// App Group `group.com.seoul.prism.widget` UserDefaults 에서 마지막 페어 읽음.
// 누르면 com.seoul.prism://route?dep=...&arr=... 로 앱 진입 → 즉시 길찾기.

import WidgetKit
import SwiftUI

private let appGroupId = "group.com.seoul.prism.widget"

struct RecentRouteEntry: TimelineEntry {
    let date: Date
    let departure: String
    let arrival: String
    let depLat: Double?
    let depLng: Double?
    let arrLat: Double?
    let arrLng: Double?
}

struct RecentRouteProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentRouteEntry {
        RecentRouteEntry(
            date: Date(),
            departure: "강남역",
            arrival: "서울역",
            depLat: nil, depLng: nil, arrLat: nil, arrLng: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentRouteEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentRouteEntry>) -> Void) {
        // App Group UserDefaults 변경 시 SceneDelegate 가 reloadAllTimelines 호출.
        // 그 외엔 1시간마다 갱신.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [currentEntry()], policy: .after(next)))
    }

    private func currentEntry() -> RecentRouteEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return RecentRouteEntry(
            date: Date(),
            departure: defaults?.string(forKey: "recent_dep") ?? "",
            arrival: defaults?.string(forKey: "recent_arr") ?? "",
            depLat: defaults?.object(forKey: "recent_dep_lat") as? Double,
            depLng: defaults?.object(forKey: "recent_dep_lng") as? Double,
            arrLat: defaults?.object(forKey: "recent_arr_lat") as? Double,
            arrLng: defaults?.object(forKey: "recent_arr_lng") as? Double
        )
    }
}

struct RecentRouteEntryView: View {
    var entry: RecentRouteEntry

    var body: some View {
        if entry.departure.isEmpty || entry.arrival.isEmpty {
            // 페어 없을 때
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Seoul Vista")
                    .font(.headline)
                Text("길찾기 한 번 하면\n여기에 표시돼요")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Label("최근 길찾기", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 4)
                Text(entry.departure)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                Text(entry.arrival)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("탭해서 다시 검색")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetURL(buildLaunchURL(entry: entry))
        }
    }

    private func buildLaunchURL(entry: RecentRouteEntry) -> URL? {
        var comps = URLComponents()
        comps.scheme = "com.seoul.prism"
        comps.host = "route"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "dep", value: entry.departure),
            URLQueryItem(name: "arr", value: entry.arrival),
        ]
        if let v = entry.depLat { items.append(URLQueryItem(name: "dep_lat", value: String(v))) }
        if let v = entry.depLng { items.append(URLQueryItem(name: "dep_lng", value: String(v))) }
        if let v = entry.arrLat { items.append(URLQueryItem(name: "arr_lat", value: String(v))) }
        if let v = entry.arrLng { items.append(URLQueryItem(name: "arr_lng", value: String(v))) }
        comps.queryItems = items
        return comps.url
    }
}

struct RouteLiveActivity: Widget {
    let kind: String = "RouteLiveActivity"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentRouteProvider()) { entry in
            RecentRouteEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("최근 길찾기")
        .description("마지막에 검색한 출발/도착을 한 탭에 다시 시작")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    RouteLiveActivity()
} timeline: {
    RecentRouteEntry(
        date: .now,
        departure: "강남역",
        arrival: "서울역",
        depLat: nil, depLng: nil, arrLat: nil, arrLng: nil
    )
    RecentRouteEntry(
        date: .now,
        departure: "",
        arrival: "",
        depLat: nil, depLng: nil, arrLat: nil, arrLng: nil
    )
}
