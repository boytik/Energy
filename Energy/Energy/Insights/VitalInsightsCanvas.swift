import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 💡 VitalInsightsCanvas — Insights Tab View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Level progress, day health breakdown, patterns, recent days, tips.

struct VitalInsightsCanvas: View {
    
    @EnvironmentObject var vault: VitalVault
    
    private var stats: BloomStatsCapsule { vault.computeStats() }
    private var progress: SurgeProgressCapsule { vault.state.progress }
    private var config: ZenConfigBlueprint { vault.state.config }
    private var recentDayEntries: [InsightDayEntry] { computeRecentDays() }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DriftGlowAtmosphere(preset: .sparkField)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        levelProgressCard
                            .padding(.horizontal, 20)
                        
                        dayHealthCard
                            .padding(.horizontal, 20)
                        
                        if stats.totalSpotsCreated > 0 {
                            patternsCard
                                .padding(.horizontal, 20)
                        }
                        
                        if !recentDayEntries.isEmpty {
                            recentDaysCard
                                .padding(.horizontal, 20)
                        }
                        
                        contextualInsightCard
                            .padding(.horizontal, 20)
                        
                        tipsSection
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Level Progress
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var levelProgressCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(progress.currentLevel.badge)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.currentLevel.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    Text("\(progress.totalXP) XP total")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
                Spacer()
                if progress.currentLevel.level < 10, let toNext = progress.xpToNext {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(toNext) XP")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(VitalPalette.surgeXPGold)
                        Text("to next")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(VitalPalette.zenAshWhisper)
                    }
                }
            }
            
            if progress.currentLevel.level < 10 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(VitalPalette.driftFogVeil)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(VitalPalette.surgeXPGold)
                            .frame(width: geo.size.width * progress.progressToNext, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.9))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Day Health Breakdown
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var dayHealthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(VitalPalette.surgeXPGold)
                Text("Day Health")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            
            Text("How your planned days turned out")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            
            if stats.totalDaysPlanned == 0 {
                Text("No days planned yet — start with Today!")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    healthRow(
                        icon: "checkmark.circle.fill",
                        label: "Comfortable",
                        count: stats.comfortableDays,
                        total: stats.totalDaysPlanned,
                        color: VitalPalette.pulseComfortSage,
                        subtitle: "Within budget"
                    )
                    healthRow(
                        icon: "exclamationmark.triangle.fill",
                        label: "Tight",
                        count: stats.tightDays,
                        total: stats.totalDaysPlanned,
                        color: VitalPalette.pulseCautionAmber,
                        subtitle: "Slightly over"
                    )
                    healthRow(
                        icon: "xmark.octagon.fill",
                        label: "Overloaded",
                        count: stats.overloadedDays,
                        total: stats.totalDaysPlanned,
                        color: VitalPalette.pulseOverloadRust,
                        subtitle: "Way over budget"
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.9))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func healthRow(icon: String, label: String, count: Int, total: Int, color: Color, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                Text(subtitle)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            Spacer()
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            if total > 0 {
                Text("(\(Int(Double(count) / Double(total) * 100))%)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.12))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Your Patterns
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var patternsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(VitalPalette.surgeXPGold)
                Text("Your Patterns")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            
            HStack(spacing: 12) {
                if let kind = stats.mostUsedSpotKind {
                    patternPill(icon: kind.icon, label: "Most used", value: kind.title)
                }
                if let zone = stats.favoriteZone {
                    patternPill(icon: zone.icon, label: "Favorite zone", value: zone.title)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.9))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func patternPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(VitalPalette.surgeXPGold)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VitalPalette.driftFogVeil.opacity(0.8))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Recent Days
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var recentDaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(VitalPalette.surgeXPGold)
                Text("Recent Days")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            
            VStack(spacing: 8) {
                ForEach(recentDayEntries) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.status.icon)
                            .font(.system(size: 18))
                            .foregroundColor(entry.status.statusColor)
                            .frame(width: 24, alignment: .center)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.dateFormatted)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(VitalPalette.zenJetStone)
                            Text("\(entry.spotCount) spots • \(entry.totalPlannedMin) min")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(VitalPalette.zenAshWhisper)
                        }
                        Spacer()
                        Text(entry.status.title)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(entry.status.statusColor)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(entry.status.statusColor.opacity(0.1))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.9))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Contextual Insight
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var contextualInsightCard: some View {
        contextualInsightView(message: contextualInsightMessage, icon: contextualInsightIcon)
    }
    
    private var contextualInsightMessage: String {
        let rate = stats.comfortRate
        if stats.totalDaysPlanned == 0 {
            return "Plan your first day in the Today tab to start tracking!"
        } else if rate >= 0.8 {
            return "Great balance! \(Int(rate * 100))% of your days are comfortable."
        } else if rate >= 0.6 {
            return "\(Int(rate * 100))% comfort rate. Try Light mode on busy days."
        } else if stats.overloadedDays > stats.comfortableDays {
            return "Many overloaded days. Consider fewer spots or Light tempo."
        } else {
            return "Mix of comfortable and tight days. Buffer time helps!"
        }
    }
    
    private var contextualInsightIcon: String {
        let rate = stats.comfortRate
        if stats.totalDaysPlanned == 0 { return "bolt.heart.fill" }
        if rate >= 0.8 { return "star.fill" }
        if rate >= 0.6 { return "leaf.fill" }
        if stats.overloadedDays > stats.comfortableDays { return "exclamationmark.triangle.fill" }
        return "clock.badge.checkmark"
    }
    
    private func contextualInsightView(message: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(VitalPalette.surgeXPGold)
            Text(message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.9))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Tips
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(VitalPalette.surgeXPGold)
                Text("Energy Tips")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            
            VStack(spacing: 10) {
                tipRow(icon: "bolt.heart.fill", title: "Plan by energy", text: "Schedule demanding spots when you're most alert.")
                tipRow(icon: "leaf.fill", title: "Light mode", text: "Use on low-energy days — fewer spots, shorter durations.")
                tipRow(icon: "clock.badge.checkmark", title: "Buffer time", text: "Don't skip travel and transitions between spots.")
                tipRow(icon: "chart.line.uptrend.xyaxis", title: "Comfort rate", text: "Aim for 70%+ comfortable days. Adjust tempo if needed.")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.9))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func tipRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(VitalPalette.surgeXPGold)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VitalPalette.driftFogVeil.opacity(0.8))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private struct InsightDayEntry: Identifiable {
        let id: String
        let date: Date
        let dayKey: String
        let spotCount: Int
        let totalPlannedMin: Int
        let status: OverloadPulse
        
        var dateFormatted: String {
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            f.locale = Locale(identifier: "en_US")
            return f.string(from: date)
        }
    }
    
    private func computeRecentDays() -> [InsightDayEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return vault.state.dayPlans
            .sorted { $0.localDayKey > $1.localDayKey }
            .prefix(5)
            .compactMap { plan -> InsightDayEntry? in
                guard let variant = plan.activeVariant else { return nil }
                let budget = config.budgetMinutes(for: variant.rhythm)
                let planned = variant.totalPlannedMin
                let delta = planned - budget
                let status: OverloadPulse = delta > config.overloadThresholdMin ? .overloaded
                    : delta > config.tightThresholdMin ? .tight : .comfortable
                guard let date = formatter.date(from: plan.localDayKey) else { return nil }
                return InsightDayEntry(
                    id: plan.localDayKey,
                    date: date,
                    dayKey: plan.localDayKey,
                    spotCount: variant.spotCount,
                    totalPlannedMin: planned,
                    status: status
                )
            }
    }
}
