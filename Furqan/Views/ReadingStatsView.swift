import SwiftUI

struct ReadingStatsView: View {
    @ObservedObject var statsManager: ReadingStatsManager
    @Environment(\.readingTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top row: streak + best streak
                    HStack(spacing: 14) {
                        statCard(
                            icon: "flame.fill",
                            iconColor: .orange,
                            value: "\(statsManager.currentStreak)",
                            label: "Current Streak"
                        )

                        statCard(
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            value: "\(statsManager.bestStreak)",
                            label: "Best Streak"
                        )
                    }

                    // Second row: time today
                    HStack(spacing: 14) {
                        statCard(
                            icon: "clock.fill",
                            iconColor: .blue,
                            value: statsManager.todayReadingTimeFormatted,
                            label: "Today"
                        )

                        statCard(
                            icon: "book.fill",
                            iconColor: .green,
                            value: "\(statsManager.todayPages.count)",
                            label: "Pages Today"
                        )
                    }

                    // Third row: lifetime days + khatm
                    HStack(spacing: 14) {
                        statCard(
                            icon: "calendar",
                            iconColor: .purple,
                            value: "\(statsManager.lifetimeDaysRead)",
                            label: "Days Read"
                        )
                        statCard(
                            icon: "checkmark.seal.fill",
                            iconColor: .teal,
                            value: "\(statsManager.khatmCount)",
                            label: "Khatms"
                        )
                    }

                    // Fourth row: most active day
                    HStack(spacing: 14) {
                        statCard(
                            icon: "star.fill",
                            iconColor: .pink,
                            value: statsManager.mostActiveWeekday ?? "—",
                            label: "Most Active Day"
                        )
                    }

                    // Progress ring
                    progressSection

                    // 90-day heatmap
                    heatmapSection

                    // Weekly chart
                    weeklyChartSection

                    // Pages today detail
                    todayDetailSection

                    // Reset button
                    resetButton
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
                .padding(.horizontal, 24)
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Reading Stats")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Stat Card

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 24,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textColor)
                        .monospacedDigit()
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 28,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mushaf Progress")
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text("\(statsManager.totalPagesRead) of 604 pages")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    Spacer()
                    Text(String(format: "%.1f%%", statsManager.completionPercentage))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textColor)
                        .monospacedDigit()
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.textColor.opacity(0.08))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0, geo.size.width * CGFloat(statsManager.completionPercentage / 100.0)),
                                height: 12
                            )
                    }
                }
                .frame(height: 12)

                // Juz markers
                HStack {
                    Text("Juz 1")
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryTextColor)
                    Spacer()
                    Text("Juz 15")
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryTextColor)
                    Spacer()
                    Text("Juz 30")
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryTextColor)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        let data = statsManager.weeklyData()
        let maxPages = max(data.map(\.pages).max() ?? 1, 1)

        return AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 28,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Label("This Week", systemImage: "calendar")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, entry in
                        VStack(spacing: 6) {
                            Text("\(entry.pages)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.secondaryTextColor)
                                .monospacedDigit()

                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    index == data.count - 1
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [.green, .green.opacity(0.6)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                          ))
                                        : AnyShapeStyle(theme.textColor.opacity(0.12))
                                )
                                .frame(
                                    height: max(4, CGFloat(entry.pages) / CGFloat(maxPages) * 80)
                                )

                            Text(entry.day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(
                                    index == data.count - 1
                                        ? theme.textColor
                                        : theme.tertiaryTextColor
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
            .padding(20)
        }
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        let data = statsManager.heatmapData()
        // Group into 13 columns of 7 days (oldest → newest)
        let columns = stride(from: 0, to: data.count, by: 7).map {
            Array(data[$0..<min($0 + 7, data.count)])
        }
        return AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 28,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Last 90 Days", systemImage: "square.grid.3x3.fill")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                HStack(alignment: .top, spacing: 4) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                        VStack(spacing: 4) {
                            ForEach(Array(col.enumerated()), id: \.offset) { _, entry in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(heatColor(for: entry.count))
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }

                HStack(spacing: 6) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryTextColor)
                    ForEach([0, 1, 3, 6, 10], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heatColor(for: level))
                            .frame(width: 10, height: 10)
                    }
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryTextColor)
                }
            }
            .padding(20)
        }
    }

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0:     return theme.textColor.opacity(0.08)
        case 1...2: return .green.opacity(0.3)
        case 3...5: return .green.opacity(0.55)
        case 6...9: return .green.opacity(0.78)
        default:    return .green
        }
    }

    // MARK: - Today Detail

    private var todayDetailSection: some View {
        AdaptiveGlassCard(
            tint: sectionTint,
            cornerRadius: 28,
            fallbackFill: AnyShapeStyle(.thinMaterial),
            fallbackStroke: strokeColor
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Today's Reading", systemImage: "book.fill")
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                HStack(spacing: 20) {
                    detailItem(
                        value: "\(statsManager.todayPages.count)",
                        label: "Pages"
                    )
                    detailItem(
                        value: statsManager.todayReadingTimeFormatted,
                        label: "Time"
                    )
                    detailItem(
                        value: "\(statsManager.currentStreak)",
                        label: "Streak"
                    )
                }
            }
            .padding(20)
        }
    }

    private func detailItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textColor)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        Button {
            showResetConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                Text("Reset All Stats")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                tint: nil,
                fallbackFill: AnyShapeStyle(theme.pageBackground.opacity(0.88)),
                fallbackStroke: strokeColor
            )
        }
        .buttonStyle(.plain)
        .alert("Reset Reading Stats?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                statsManager.resetAll()
            }
        } message: {
            Text("This will erase all your reading progress, streaks, and session data. This cannot be undone.")
        }
    }

    // MARK: - Helpers

    private var sectionTint: Color? {
        switch theme {
        case .sepia: return Color.brown.opacity(0.18)
        default: return nil
        }
    }

    private var strokeColor: Color {
        switch theme {
        case .light:  return .black.opacity(0.06)
        case .dark:   return .white.opacity(0.06)
        case .sepia:  return Color(red: 0.55, green: 0.46, blue: 0.35).opacity(0.18)
        case .amoled: return .white.opacity(0.04)
        }
    }
}
