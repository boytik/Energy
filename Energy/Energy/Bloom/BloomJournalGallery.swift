import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📅 BloomJournalGallery — Days Tab View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Features (4 key actions):
//   1. Calendar month grid with status dots per day
//   2. Weekly stats summary card (comfort rate, avg load)
//   3. Recent days list with status, spots, overload
//   4. Copy day to today / Delete day (swipe + context)
//
// ViewModel: BloomJournalMind.swift

struct BloomJournalGallery: View {
    
    @EnvironmentObject var vault: VitalVault
    @StateObject private var mind = BloomJournalMind()
    
    var body: some View {
        NavigationStack {
            ZStack {
                GoldBlackGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // ── Calendar ──
                        calendarCard
                            .padding(.horizontal, 20)
                        
                        // ── Weekly Stats ──
                        if mind.weeklyStats.totalDays > 0 {
                            weeklyStatsCard
                                .padding(.horizontal, 20)
                        }
                        
                        // ── Recent Days List ──
                        if mind.hasDayPlans {
                            recentDaysList
                        } else {
                            emptyState
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Days")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mind.showHelpSheet = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 18))
                            .foregroundColor(VitalPalette.zenAshWhisper)
                    }
                }
            }
            .sheet(isPresented: $mind.showDayDetail) {
                if let plan = mind.selectedDayPlan {
                    BloomDayDetailSheet(
                        dayPlan: plan,
                        todayPlan: mind.todayPlan,
                        config: vault.state.config,
                        pinnedTemplates: mind.pinnedTemplates,
                        onCopyToToday: { mind.copyDayToToday(plan.localDayKey) },
                        onSwitchVariant: { mind.switchVariant(plan.localDayKey, variantId: $0) },
                        onAddVariant: { mind.addVariantToDay(plan.localDayKey, title: $0) },
                        onAddFromTemplate: { mind.addSpotToDay(dayKey: plan.localDayKey, template: $0, zone: $1) },
                        onApplyTodayVariant: { mind.applyTodayVariantToDay(variantId: $0, toDayKey: plan.localDayKey) }
                    )
                    .presentationDetents([.large])
                }
            }
            .alert("Delete Day Plan?", isPresented: $mind.showDeleteConfirmation) {
                Button("Delete", role: .destructive) { mind.performDeleteDay() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove this day plan and all its variants.")
            }
            .sheet(isPresented: $mind.showHelpSheet) {
                DaysHelpSheet()
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Calendar Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var calendarCard: some View {
        VStack(spacing: 14) {
            // Month navigation
            HStack {
                Button(action: mind.previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(VitalPalette.zenJetStone)
                }
                
                Spacer()
                
                Text(mind.displayedMonthTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if !mind.isDisplayingCurrentMonth {
                        Button("Today") {
                            mind.goToToday()
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.surgeXPGold)
                    }
                    Button(action: mind.nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(VitalPalette.zenJetStone)
                    }
                }
            }
            
            // Weekday headers
            let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                        .frame(height: 20)
                }
            }
            
            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(mind.calendarDays) { item in
                    calendarDayCell(item)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func calendarDayCell(_ item: BloomJournalMind.CalendarDayItem) -> some View {
        Button {
            if item.isCurrentMonth {
                if item.status != nil {
                    mind.selectDay(item.dayKey)
                } else if !item.dayKey.isEmpty {
                    mind.createDayPlan(forDayKey: item.dayKey)
                }
            }
        } label: {
            VStack(spacing: 3) {
                if item.isCurrentMonth {
                    Text("\(item.day)")
                        .font(.system(size: 14, weight: item.isToday ? .bold : .regular, design: .rounded))
                        .foregroundColor(
                            item.isToday
                            ? VitalPalette.glowZincSunrise
                            : VitalPalette.zenJetStone
                        )
                    
                    // Status dot or add hint
                    if let status = item.status {
                        Circle()
                            .fill(status.statusColor)
                            .frame(width: 6, height: 6)
                    } else if !item.dayKey.isEmpty {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(VitalPalette.zenSilentStone)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                } else {
                    Text("")
                        .frame(height: 14)
                    Spacer().frame(height: 6)
                }
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                item.isToday
                                ? VitalPalette.chipSelectedBg
                                : Color.clear
                            )
                    )
        }
        .buttonStyle(.plain)
        .disabled(!item.isCurrentMonth || item.dayKey.isEmpty)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Weekly Stats Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var weeklyStatsCard: some View {
        let stats = mind.weeklyStats
        
        return VStack(spacing: 14) {
            HStack {
                Text("Last 7 Days")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                Spacer()
                Text("\(stats.totalDays) days planned")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            
            // Status breakdown
            HStack(spacing: 12) {
                statsPill(
                    icon: "checkmark.circle.fill",
                    color: VitalPalette.pulseComfortSage,
                    value: "\(stats.comfortableDays)",
                    label: "Comfortable"
                )
                statsPill(
                    icon: "exclamationmark.triangle.fill",
                    color: VitalPalette.pulseCautionAmber,
                    value: "\(stats.tightDays)",
                    label: "Tight"
                )
                statsPill(
                    icon: "xmark.octagon.fill",
                    color: VitalPalette.pulseOverloadRust,
                    value: "\(stats.overloadedDays)",
                    label: "Overloaded"
                )
            }
            
            // Comfort rate bar
            VStack(spacing: 6) {
                HStack {
                    Text("Comfort Rate")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                    Spacer()
                    Text("\(Int(stats.comfortRate * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.pulseComfortSage)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(VitalPalette.driftFogVeil)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(VitalPalette.pulseComfortSage)
                            .frame(width: geo.size.width * stats.comfortRate, height: 8)
                            .animation(.easeInOut(duration: 0.5), value: stats.comfortRate)
                    }
                }
                .frame(height: 8)
            }
            
            // Bottom row
            HStack {
                Label("Avg \(stats.avgPlannedMin) min/day", systemImage: "clock")
                Spacer()
                Label("\(stats.totalSpots) total spots", systemImage: "mappin.circle")
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(VitalPalette.zenAshWhisper)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func statsPill(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Recent Days List
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var recentDaysList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 10) {
                ForEach(mind.recentDays) { entry in
                    BloomDayRow(entry: entry)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            mind.selectDay(entry.dayKey)
                        }
                        .contextMenu {
                            let todayKey = RhythmDayBlueprint.dayKey(from: Date())
                            if !entry.isToday && entry.dayKey < todayKey && entry.spotCount > 0 {
                                Button {
                                    mind.copyDayToToday(entry.dayKey)
                                } label: {
                                    Label("Copy to Today", systemImage: "doc.on.doc")
                                }
                            }
                            
                            Button(role: .destructive) {
                                mind.confirmDeleteDay(entry.dayKey)
                            } label: {
                                Label("Delete Day", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Empty State
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(VitalPalette.zenSilentStone)
            
            Text("No Days Planned Yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
            
            Text("Switch to the Today tab to create your first Energy Route")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
                .multilineTextAlignment(.center)
            Text("Or tap an empty day in the calendar to add a plan")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(VitalPalette.zenSilentStone)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📋 BloomDayRow — Single day entry in list
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BloomDayRow: View {
    let entry: BloomJournalMind.DayEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(entry.status.statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: entry.status.icon)
                    .font(.system(size: 18))
                    .foregroundColor(entry.status.statusColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.dateFormatted)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    if entry.isToday {
                        Text("TODAY")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(VitalPalette.glowZincSunrise)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(VitalPalette.chipSelectedBg)
                            )
                    }
                }
                
                HStack(spacing: 8) {
                    Label(entry.rhythmTitle, systemImage: entry.rhythmIcon)
                    Text("•")
                    Text("\(entry.spotCount) spots")
                    Text("•")
                    Text("\(entry.totalPlannedMin) min")
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            }
            
            Spacer()
            
            // Overload delta or OK
            VStack(alignment: .trailing, spacing: 2) {
                if entry.overloadDelta > 0 {
                    Text("+\(entry.overloadDelta)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(entry.status.statusColor)
                    Text("min over")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(VitalPalette.pulseComfortSage)
                }
                
                if entry.variantCount > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 9))
                        Text("\(entry.variantCount)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(VitalPalette.zenSilentStone)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 4, x: 0, y: 2)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📄 BloomDayDetailSheet — Day detail view
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BloomDayDetailSheet: View {
    let dayPlan: RhythmDayBlueprint
    let todayPlan: RhythmDayBlueprint?
    let config: ZenConfigBlueprint
    let pinnedTemplates: [SparkTemplateSeed]
    let onCopyToToday: () -> Void
    let onSwitchVariant: (UUID) -> Void
    let onAddVariant: (String) -> Void
    let onAddFromTemplate: (SparkTemplateSeed, DayZone) -> Void
    let onApplyTodayVariant: (UUID) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var newVariantName = ""
    @State private var showAddVariantField = false
    @State private var selectedZoneForTemplate: DayZone = .daytime
    
    private var todayKey: String { RhythmDayBlueprint.dayKey(from: Date()) }
    private var isFutureOrToday: Bool { dayPlan.localDayKey >= todayKey }
    private var isPastDay: Bool { dayPlan.localDayKey < todayKey }
    private var hasContent: Bool {
        dayPlan.variants.contains { $0.spotCount > 0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Variant info
                    if let variant = dayPlan.activeVariant {
                        let summary = CoreOverloadEngine.daySummary(variant: variant, config: config)
                        
                        // Status header
                        VStack(spacing: 8) {
                            Image(systemName: summary.status.icon)
                                .font(.system(size: 32))
                                .foregroundColor(summary.status.statusColor)
                            
                            Text(summary.displayText)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(VitalPalette.zenJetStone)
                            
                            Text("\(variant.rhythm.title) mode • \(variant.spotCount) spots")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(VitalPalette.zenAshWhisper)
                        }
                        .padding(.top, 8)
                        
                        // Budget bar
                        VStack(spacing: 8) {
                            HStack {
                                Text("Planned")
                                Spacer()
                                Text("\(summary.plannedMin) / \(summary.budgetMin) min")
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(VitalPalette.driftFogVeil)
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(summary.status.statusColor)
                                        .frame(width: min(geo.size.width, geo.size.width * summary.usagePercent), height: 10)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding(.horizontal, 20)
                        
                        // Zone breakdown
                        ForEach(DayZone.allCases) { zone in
                            let zoneSpots = variant.spotsIn(zone: zone)
                            if !zoneSpots.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: zone.icon)
                                        Text(zone.title)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        Spacer()
                                        Text("\(variant.plannedMinIn(zone: zone)) min")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(VitalPalette.zenAshWhisper)
                                    }
                                    .foregroundColor(VitalPalette.zenJetStone)
                                    
                                    ForEach(zoneSpots) { spot in
                                        HStack(spacing: 10) {
                                            Image(systemName: spot.displayIcon)
                                                .font(.system(size: 13))
                                                .foregroundColor(VitalPalette.zenCharcoalDepth)
                                                .frame(width: 20)
                                            
                                            Text(spot.title)
                                                .font(.system(size: 14, design: .rounded))
                                                .foregroundColor(VitalPalette.zenJetStone)
                                            
                                            Spacer()
                                            
                                            Text("\(spot.computedLoadMin) min")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(VitalPalette.zenAshWhisper)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(zone.tintColor.opacity(0.15))
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Apply from Today (future days only)
                        if isFutureOrToday && dayPlan.localDayKey != todayKey,
                           let today = todayPlan, !today.variants.isEmpty,
                           today.variants.contains(where: { $0.spotCount > 0 }) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Apply from Today")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                                
                                ForEach(today.variants.filter { $0.spotCount > 0 }) { variant in
                                    Button {
                                        onApplyTodayVariant(variant.id)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.on.doc.fill")
                                                .font(.system(size: 14))
                                            Text(variant.title)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                            Spacer()
                                            Text("\(variant.spotCount) spots • \(variant.totalPlannedMin) min")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundColor(VitalPalette.zenAshWhisper)
                                        }
                                        .foregroundColor(VitalPalette.zenJetStone)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(VitalPalette.driftFogVeil)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Add from templates (future days or today)
                        if isFutureOrToday && !pinnedTemplates.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Add from templates")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                                
                                HStack(spacing: 8) {
                                    ForEach(DayZone.allCases) { zone in
                                        ChipButton(
                                            title: zone.title,
                                            isSelected: selectedZoneForTemplate == zone,
                                            action: { selectedZoneForTemplate = zone }
                                        )
                                    }
                                }
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(pinnedTemplates) { template in
                                        Button {
                                            onAddFromTemplate(template, selectedZoneForTemplate)
                                        } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: template.iconName ?? template.kind.icon)
                                                    .font(.system(size: 14))
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(template.title)
                                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                                        .lineLimit(1)
                                                    Text("\(template.defaultDurationMin) min")
                                                        .font(.system(size: 11, design: .rounded))
                                                        .foregroundColor(VitalPalette.zenAshWhisper)
                                                }
                                            }
                                            .foregroundColor(VitalPalette.zenJetStone)
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(VitalPalette.driftFogVeil)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Variants list
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Variants")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                                Spacer()
                                Button {
                                    showAddVariantField = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Add")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(VitalPalette.surgeXPGold)
                                }
                            }
                            
                            if showAddVariantField {
                                HStack(spacing: 8) {
                                    TextField("Variant name", text: $newVariantName)
                                        .font(.system(size: 14, design: .rounded))
                                        .padding(10)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(VitalPalette.driftFogVeil))
                                    Button {
                                        let name = newVariantName.isEmpty ? "Variant \(dayPlan.variants.count + 1)" : newVariantName
                                        onAddVariant(name)
                                        newVariantName = ""
                                        showAddVariantField = false
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(VitalPalette.zenJetStone)
                                    }
                                    Button {
                                        showAddVariantField = false
                                        newVariantName = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(VitalPalette.zenSilentStone)
                                    }
                                }
                            }
                            
                            if dayPlan.variants.count > 0 {
                                ForEach(dayPlan.variants) { v in
                                    Button {
                                        onSwitchVariant(v.id)
                                    } label: {
                                        HStack {
                                            Image(systemName: v.id == dayPlan.selectedVariantId
                                                  ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(v.id == dayPlan.selectedVariantId
                                                                 ? VitalPalette.zenJetStone
                                                                 : VitalPalette.zenSilentStone)
                                            
                                            Text(v.title)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                            
                                            Spacer()
                                            
                                            Text("\(v.spotCount) spots • \(v.totalPlannedMin) min")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundColor(VitalPalette.zenAshWhisper)
                                        }
                                        .foregroundColor(VitalPalette.zenJetStone)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(VitalPalette.driftFogVeil.opacity(0.5))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Copy to today button (past days with content only — avoid copying empty retroactive plans)
                    if isPastDay && hasContent {
                        Button {
                            onCopyToToday()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy to Today")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(VitalPalette.glowZincSunrise)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(VitalPalette.chipSelectedBg)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.vertical, 12)
            }
            .navigationTitle(dayPlanDateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
            }
        }
    }
    
    private var dayPlanDateTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: dayPlan.dateStart)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ❓ DaysHelpSheet — Tips for Days tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct DaysHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    private let tips: [(icon: String, title: String, body: String)] = [
        ("calendar.badge.plus", "Future days",
         "Tap a future day to open it. Apply one of today's variants, or add spots from pinned templates. Choose Morning, Daytime or Evening, then tap a template."),
        ("doc.on.doc", "Past days",
         "Tap a past day to view its plan. \"Copy to Today\" appears only when the day has spots — empty retroactive days cannot be copied to avoid confusion."),
        ("square.on.square", "Variants",
         "Create multiple variants per day (e.g. Plan A / Plan B) and switch between them. Each variant has its own spots."),
        ("chart.bar", "Weekly stats",
         "See how many days were comfortable, tight or overloaded in the last 7 days.")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: tip.icon)
                                .font(.system(size: 22))
                                .foregroundColor(VitalPalette.glowZincSunrise)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                                Text(tip.body)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(VitalPalette.zenAshWhisper)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(VitalPalette.driftFogVeil)
                        )
                    }
                }
                .padding(20)
            }
            .background(VitalPalette.driftSnowField)
            .navigationTitle("Days Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
            }
        }
    }
}
