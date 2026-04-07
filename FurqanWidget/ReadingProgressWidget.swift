import WidgetKit
import SwiftUI

// MARK: - Reading Progress Entry

struct ReadingProgressEntry: TimelineEntry {
    let date: Date
    let todayPages: Int
    let streak: Int
    let totalPages: Int
    let completionPercentage: Double
}

// MARK: - Provider

struct ReadingProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadingProgressEntry {
        ReadingProgressEntry(date: Date(), todayPages: 5, streak: 3, totalPages: 42, completionPercentage: 7.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingProgressEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingProgressEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> ReadingProgressEntry {
        let defaults = UserDefaults(suiteName: "group.com.mehdi.furqan")
        return ReadingProgressEntry(
            date: Date(),
            todayPages: defaults?.integer(forKey: "widget_today_pages") ?? 0,
            streak: defaults?.integer(forKey: "widget_streak") ?? 0,
            totalPages: defaults?.integer(forKey: "widget_total_pages") ?? 0,
            completionPercentage: defaults?.double(forKey: "widget_completion") ?? 0
        )
    }
}

// MARK: - Widget Views

struct ReadingProgressWidgetEntryView: View {
    var entry: ReadingProgressEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FURQAN.")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(entry.streak)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer(minLength: 0)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(min(entry.completionPercentage / 100.0, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", entry.completionPercentage))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("\(entry.totalPages)/604")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 68, height: 68)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text("\(entry.todayPages) pages today")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: progress ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(min(entry.completionPercentage / 100.0, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(String(format: "%.1f%%", entry.completionPercentage))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("\(entry.totalPages)/604")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, height: 90)

            // Right: stats
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FURQAN.")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                statRow(icon: "book.fill", color: .green, value: "\(entry.todayPages)", label: "pages today")
                statRow(icon: "flame.fill", color: .orange, value: "\(entry.streak)", label: "day streak")
                statRow(icon: "checkmark.circle.fill", color: .blue, value: "\(entry.totalPages)", label: "pages read")
            }
        }
        .padding(16)
    }

    private func statRow(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 16)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Definition

struct ReadingProgressWidget: Widget {
    let kind: String = "ReadingProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProgressProvider()) { entry in
            if #available(iOS 17.0, *) {
                ReadingProgressWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ReadingProgressWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Reading Progress")
        .description("Track your Quran reading progress and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
