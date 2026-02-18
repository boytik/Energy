import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧠 BloomJournalMind — Days Tab ViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Drives the "Days" tab:
//   - Calendar month view with status dots
//   - Recent days list with overload info
//   - Copy day plan to today
//   - Delete old plans
//   - Weekly comfort/overload stats
//   - Navigate to day detail
//
// View file: BloomJournalGallery.swift

final class BloomJournalMind: ObservableObject {
    
    // ── Dependencies ──
    private let vault: VitalVault
    private var cancellables = Set<AnyCancellable>()
    
    // ── Calendar State ──
    @Published var displayedMonth: Date = Date()
    @Published var selectedDayKey: String?
    
    // ── Derived ──
    @Published var allDayPlans: [RhythmDayBlueprint] = []
    @Published var recentDays: [DayEntry] = []
    @Published var calendarDays: [CalendarDayItem] = []
    @Published var weeklyStats: WeeklyStats = .empty
    
    // ── UI ──
    @Published var showDayDetail = false
    @Published var selectedDayPlan: RhythmDayBlueprint?
    @Published var showDeleteConfirmation = false
    @Published var showHelpSheet = false
    @Published var dayKeyToDelete: String?
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Types
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    struct DayEntry: Identifiable {
        let id: String  // dayKey
        let date: Date
        let dayKey: String
        let rhythmTitle: String
        let rhythmIcon: String
        let spotCount: Int
        let totalPlannedMin: Int
        let budgetMin: Int
        let status: OverloadPulse
        let variantCount: Int
        let isToday: Bool
        
        var overloadDelta: Int {
            max(0, totalPlannedMin - budgetMin)
        }
        
        var dateFormatted: String {
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            f.locale = Locale(identifier: "en_US")
            return f.string(from: date)
        }
    }
    
    struct CalendarDayItem: Identifiable {
        let id: String
        let day: Int
        let dayKey: String
        let isCurrentMonth: Bool
        let isToday: Bool
        let status: OverloadPulse?   // nil = no plan
        let hasVariants: Bool
    }
    
    struct WeeklyStats {
        let totalDays: Int
        let comfortableDays: Int
        let tightDays: Int
        let overloadedDays: Int
        let avgPlannedMin: Int
        let totalSpots: Int
        
        static let empty = WeeklyStats(
            totalDays: 0, comfortableDays: 0, tightDays: 0,
            overloadedDays: 0, avgPlannedMin: 0, totalSpots: 0
        )
        
        var comfortRate: Double {
            guard totalDays > 0 else { return 0 }
            return Double(comfortableDays) / Double(totalDays)
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    init(vault: VitalVault = .shared) {
        self.vault = vault
        
        vault.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.refreshFromState(state)
            }
            .store(in: &cancellables)
        
        refreshFromState(vault.state)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Refresh
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func refreshFromState(_ state: VitalAppState) {
        let config = state.config
        allDayPlans = state.dayPlans.sorted { $0.localDayKey > $1.localDayKey }
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        
        // Build recent days list
        recentDays = allDayPlans.prefix(30).map { plan in
            let variant = plan.activeVariant
            let rhythm = variant?.rhythm ?? config.defaultRhythm
            let budget = config.budgetMinutes(for: rhythm)
            let planned = variant?.totalPlannedMin ?? 0
            let status = statusFor(planned: planned, budget: budget, config: config)
            
            return DayEntry(
                id: plan.localDayKey,
                date: plan.dateStart,
                dayKey: plan.localDayKey,
                rhythmTitle: rhythm.title,
                rhythmIcon: rhythm.icon,
                spotCount: variant?.spotCount ?? 0,
                totalPlannedMin: planned,
                budgetMin: budget,
                status: status,
                variantCount: plan.variants.count,
                isToday: plan.localDayKey == todayKey
            )
        }
        
        // Build calendar
        rebuildCalendar(state: state)
        
        // Weekly stats (last 7 days)
        computeWeeklyStats(state: state)
        
        // Keep selectedDayPlan in sync when viewing a day
        if let key = selectedDayKey {
            selectedDayPlan = allDayPlans.first { $0.localDayKey == key }
        }
    }
    
    private func statusFor(planned: Int, budget: Int, config: ZenConfigBlueprint) -> OverloadPulse {
        let delta = planned - budget
        if delta > config.overloadThresholdMin { return .overloaded }
        if delta > config.tightThresholdMin { return .tight }
        return .comfortable
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Calendar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func rebuildCalendar(state: VitalAppState) {
        let cal = Calendar.current
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        let config = state.config
        
        // Build lookup of dayKey → plan
        let planLookup = Dictionary(
            uniqueKeysWithValues: state.dayPlans.map { ($0.localDayKey, $0) }
        )
        
        // Get range of days in displayed month
        guard let monthRange = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else {
            calendarDays = []
            return
        }
        
        // Leading empty days (to align weekday)
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (firstWeekday - cal.firstWeekday + 7) % 7
        
        var items: [CalendarDayItem] = []
        
        // Leading placeholders
        for i in 0..<leadingEmpty {
            items.append(CalendarDayItem(
                id: "lead_\(i)",
                day: 0,
                dayKey: "",
                isCurrentMonth: false,
                isToday: false,
                status: nil,
                hasVariants: false
            ))
        }
        
        // Actual days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for day in monthRange {
            var comps = cal.dateComponents([.year, .month], from: displayedMonth)
            comps.day = day
            guard let date = cal.date(from: comps) else { continue }
            let key = formatter.string(from: date)
            
            let plan = planLookup[key]
            var status: OverloadPulse? = nil
            var hasVariants = false
            
            if let plan = plan, let variant = plan.activeVariant {
                let budget = config.budgetMinutes(for: variant.rhythm)
                status = statusFor(planned: variant.totalPlannedMin, budget: budget, config: config)
                hasVariants = plan.variants.count > 1
            }
            
            items.append(CalendarDayItem(
                id: key,
                day: day,
                dayKey: key,
                isCurrentMonth: true,
                isToday: key == todayKey,
                status: status,
                hasVariants: hasVariants
            ))
        }
        
        calendarDays = items
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Weekly Stats
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func computeWeeklyStats(state: VitalAppState) {
        let cal = Calendar.current
        let config = state.config
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) else {
            weeklyStats = .empty
            return
        }
        let weekAgoKey = RhythmDayBlueprint.dayKey(from: weekAgo)
        
        let recent = state.dayPlans.filter { $0.localDayKey >= weekAgoKey }
        
        var comfortable = 0, tight = 0, overloaded = 0
        var totalPlanned = 0, totalSpots = 0
        
        for plan in recent {
            guard let variant = plan.activeVariant else { continue }
            let budget = config.budgetMinutes(for: variant.rhythm)
            let planned = variant.totalPlannedMin
            let status = statusFor(planned: planned, budget: budget, config: config)
            
            switch status {
            case .comfortable: comfortable += 1
            case .tight:       tight += 1
            case .overloaded:  overloaded += 1
            }
            
            totalPlanned += planned
            totalSpots += variant.spotCount
        }
        
        let count = recent.count
        weeklyStats = WeeklyStats(
            totalDays: count,
            comfortableDays: comfortable,
            tightDays: tight,
            overloadedDays: overloaded,
            avgPlannedMin: count > 0 ? totalPlanned / count : 0,
            totalSpots: totalSpots
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = Date()
        }
        rebuildCalendar(state: vault.state)
    }
    
    func nextMonth() {
        let cal = Calendar.current
        if let next = cal.date(byAdding: .month, value: 1, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                displayedMonth = next
            }
            rebuildCalendar(state: vault.state)
        }
    }
    
    func previousMonth() {
        let cal = Calendar.current
        if let prev = cal.date(byAdding: .month, value: -1, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                displayedMonth = prev
            }
            rebuildCalendar(state: vault.state)
        }
    }
    
    var displayedMonthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: displayedMonth)
    }
    
    var isDisplayingCurrentMonth: Bool {
        Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }
    
    func selectDay(_ dayKey: String) {
        selectedDayKey = dayKey
        selectedDayPlan = allDayPlans.first { $0.localDayKey == dayKey }
        if selectedDayPlan != nil {
            showDayDetail = true
        }
    }
    
    func switchVariant(_ dayKey: String, variantId: UUID) {
        vault.updateDayPlan(dayKey: dayKey) { plan in
            plan.selectedVariantId = variantId
        }
    }
    
    func createDayPlan(for date: Date) {
        _ = vault.ensureDayPlan(for: date)
    }
    
    func createDayPlan(forDayKey dayKey: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: dayKey) else { return }
        _ = vault.ensureDayPlan(for: date)
        selectDay(dayKey)
    }
    
    func addVariantToDay(_ dayKey: String, title: String, copyFromCurrent: Bool = true) {
        let sourceId = copyFromCurrent
            ? allDayPlans.first { $0.localDayKey == dayKey }?.selectedVariantId
            : nil
        vault.addVariant(dayKey: dayKey, title: title, copyFromVariantId: sourceId)
    }
    
    func copyDayToToday(_ dayKey: String) {
        vault.copyDayPlan(fromKey: dayKey, toDate: Date())
        vault.earnXP(SurgeXPReward.createDayPlan)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Add spot from template to a specific day (for future days in Days tab)
    func addSpotToDay(dayKey: String, template: SparkTemplateSeed, zone: DayZone = .daytime) {
        let config = vault.state.config
        var spot = template.toSpot(zone: zone, bufferDefault: config.defaultBufferBetweenMin)
        spot.travelBeforeMin = config.defaultTravelMin
        vault.addSpot(dayKey: dayKey, spot: spot)
        vault.incrementTemplateUsage(id: template.id)
        vault.earnXP(SurgeXPReward.addSpot)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    var pinnedTemplates: [SparkTemplateSeed] {
        vault.state.templates.filter(\.isPinned)
    }
    
    var todayPlan: RhythmDayBlueprint? {
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        return allDayPlans.first { $0.localDayKey == todayKey }
    }
    
    /// Apply today's variant to a future day
    func applyTodayVariantToDay(variantId: UUID, toDayKey: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let toDate = formatter.date(from: toDayKey) else { return }
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        vault.copyVariantToDay(fromDayKey: todayKey, variantId: variantId, toDate: toDate)
        vault.earnXP(SurgeXPReward.createDayPlan)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func confirmDeleteDay(_ dayKey: String) {
        dayKeyToDelete = dayKey
        showDeleteConfirmation = true
    }
    
    func performDeleteDay() {
        guard let key = dayKeyToDelete else { return }
        vault.deleteDayPlan(dayKey: key)
        dayKeyToDelete = nil
        showDeleteConfirmation = false
    }
    
    var hasDayPlans: Bool { !allDayPlans.isEmpty }
}
