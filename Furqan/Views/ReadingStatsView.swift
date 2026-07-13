import SwiftUI

struct ReadingStatsView: View {
    @ObservedObject var statsManager: ReadingStatsManager
    @Environment(\.readingTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    private var palette: NativeGlassPalette { theme.nativeGlassPalette }

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
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Stat Card

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        NativeGlassSectionCard(cornerRadius: 24, tint: palette.sectionTint, elevated: true) {
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
        NativeGlassSectionCard(cornerRadius: 28, tint: palette.sectionTint, elevated: true) {
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

        return NativeGlassSectionCard(cornerRadius: 28, tint: palette.sectionTint, elevated: true) {
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
        return NativeGlassSectionCard(cornerRadius: 28, tint: palette.sectionTint, elevated: true) {
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
        NativeGlassSectionCard(cornerRadius: 28, tint: palette.sectionTint, elevated: true) {
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
        }
        .buttonStyle(NativeGlassRoundedButtonStyle(cornerRadius: 16, tint: nil, elevated: true))
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
        palette.sectionTint
    }

    private var strokeColor: Color {
        palette.stroke
    }
}

struct ReadingPlanView: View {
    @ObservedObject var planManager: ReadingPlanManager
    let initialStartPage: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme
    @State private var planKind: ReadingPlanKind = .khatm
    @State private var startPage: Int
    @State private var endPage = 604
    @State private var days = 30
    @State private var showResetConfirmation = false

    private var palette: NativeGlassPalette { theme.nativeGlassPalette }

    init(planManager: ReadingPlanManager, initialStartPage: Int) {
        self.planManager = planManager
        self.initialStartPage = initialStartPage
        _startPage = State(initialValue: min(max(initialStartPage, 1), 604))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if let plan = planManager.activePlan {
                        activePlanSection(plan)
                    } else {
                        createPlanSection
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
                .padding(.horizontal, 24)
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Reading Plan")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Reset Reading Plan?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    planManager.resetActivePlan()
                }
            } message: {
                Text("This removes the active plan and its progress.")
            }
        }
    }

    private func activePlanSection(_ plan: ReadingPlan) -> some View {
        VStack(spacing: 20) {
            NativeGlassSectionCard(cornerRadius: 30, tint: palette.sectionTint, elevated: true) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(plan.title, systemImage: plan.isComplete ? "checkmark.seal.fill" : "target")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)
                            Text("Pages \(plan.startPage)-\(plan.endPage)")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", plan.completionPercentage))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textColor)
                            .monospacedDigit()
                    }

                    ProgressView(value: plan.completionPercentage, total: 100)
                        .tint(.green)

                    HStack(spacing: 14) {
                        planMetric(value: "\(plan.completedCount)", label: "Completed")
                        planMetric(value: "\(plan.remainingPages)", label: "Remaining")
                        planMetric(value: "\(plan.dailyTargetPages())", label: "Today")
                    }
                }
                .padding(20)
            }

            NativeGlassSectionCard(cornerRadius: 26, tint: palette.sectionTint, elevated: true) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Daily Target", systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                    Text("Read \(plan.dailyTargetPages()) page\(plan.dailyTargetPages() == 1 ? "" : "s") per day to finish in \(plan.daysRemaining()) day\(plan.daysRemaining() == 1 ? "" : "s").")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset Plan", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(NativeGlassRoundedButtonStyle(cornerRadius: 16, tint: nil, elevated: true))
        }
    }

    private var createPlanSection: some View {
        NativeGlassSectionCard(cornerRadius: 30, tint: palette.sectionTint, elevated: true) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create a reading plan")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)
                    Text("Set a daily page goal and track progress privately on this device.")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Picker("Plan Type", selection: $planKind) {
                    Text("Full Mushaf").tag(ReadingPlanKind.khatm)
                    Text("Custom Range").tag(ReadingPlanKind.customRange)
                }
                .pickerStyle(.segmented)

                if planKind == .customRange {
                    Stepper("Start page \(startPage)", value: $startPage, in: 1...604)
                        .foregroundStyle(theme.textColor)
                    Stepper("End page \(endPage)", value: $endPage, in: 1...604)
                        .foregroundStyle(theme.textColor)
                }

                Stepper("Finish in \(days) days", value: $days, in: 1...365)
                    .foregroundStyle(theme.textColor)

                Button {
                    if planKind == .khatm {
                        planManager.createKhatmPlan(days: days)
                    } else {
                        planManager.createCustomPlan(startPage: startPage, endPage: endPage, days: days)
                    }
                } label: {
                    Label("Create Plan", systemImage: "target")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(NativeGlassRoundedButtonStyle(cornerRadius: 18, tint: .green.opacity(0.16), elevated: true))
            }
            .padding(20)
        }
    }

    private func planMetric(value: String, label: String) -> some View {
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
}

struct ReadingPlanPromptView: View {
    let onCreate: () -> Void
    let onDismiss: () -> Void
    @Environment(\.readingTheme) private var theme
    private var palette: NativeGlassPalette { theme.nativeGlassPalette }

    var body: some View {
        VStack(spacing: 18) {
            NativeGlassSectionCard(cornerRadius: 26, tint: palette.sectionTint, elevated: true) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.14))
                                .frame(width: 46, height: 46)
                            Image(systemName: "target")
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(.green)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Create a reading plan")
                                .font(.headline)
                                .foregroundStyle(theme.textColor)
                            Text("Set a daily page goal and track your progress privately on this device.")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 12) {
                        promptButton(
                            title: "Not Now",
                            systemImage: "xmark",
                            tint: nil,
                            action: onDismiss
                        )

                        promptButton(
                            title: "Create Plan",
                            systemImage: "target",
                            tint: .green.opacity(0.18),
                            action: onCreate
                        )
                    }
                }
                .padding(18)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.pageBackground.ignoresSafeArea())
        .preferredColorScheme(theme.colorScheme)
    }

    private func promptButton(
        title: String,
        systemImage: String,
        tint: Color?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(NativeGlassRoundedButtonStyle(cornerRadius: 16, tint: tint, elevated: true))
    }
}
