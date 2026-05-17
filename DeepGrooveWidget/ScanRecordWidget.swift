import WidgetKit
import SwiftUI

struct ScanRecordEntry: TimelineEntry {
    let date: Date
}

struct ScanRecordProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScanRecordEntry {
        ScanRecordEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScanRecordEntry) -> Void) {
        completion(ScanRecordEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScanRecordEntry>) -> Void) {
        completion(Timeline(entries: [ScanRecordEntry(date: .now)], policy: .never))
    }
}

struct ScanRecordWidgetView: View {
    let entry: ScanRecordEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) {
                Image("WidgetArt")
                    .resizable()
                    .scaledToFill()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: "camera.fill")
                .symbolRenderingMode(.monochrome)
                .font(.title2)
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .symbolRenderingMode(.monochrome)
                Text("Scan Record")
                    .font(.headline)
            }
        default:
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 13, weight: .semibold))
                    Text("Scan Record")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 14)
            }
        }
    }
}

struct ScanRecordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ScanRecordWidget", provider: ScanRecordProvider()) { entry in
            ScanRecordWidgetView(entry: entry)
                .widgetURL(URL(string: "deepgroove://add?source=camera")!)
        }
        .configurationDisplayName("Scan Record")
        .description("Tap to open the camera and identify a record with AI.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
