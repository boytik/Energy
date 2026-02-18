import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧠 PulseFlowTodayMind — Today Screen ViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Drives the main "Today" tab:
//   - Day plan with active variant
//   - Spots grouped by zone (Morning / Daytime / Evening)
//   - Real-time budget & overload tracking
//   - Add / edit / delete / move spots
//   - Mode switching (Light / Normal / Intense)
//   - Fix suggestions & variant creation
//   - Undo support
//   - XP rewards for actions
//
// View file: PulseFlowTodayCanvas.swift

final class PulseFlowTodayMind: ObservableObject {
    
    // ── Dependencies ──
    private let vault: VitalVault
    private var cancellables = Set<AnyCancellable>()
    
    // ── Published State ──
    @Published var dayPlan: RhythmDayBlueprint?
    @Published var activeVariant: HavenVariantSeed?
    @Published var config: ZenConfigBlueprint
    
    // Computed from active variant
    @Published var morningSpots: [SpotCapsule] = []
    @Published var daytimeSpots: [SpotCapsule] = []
    @Published var eveningSpots: [SpotCapsule] = []
    
    @Published var daySummary: CoreOverloadEngine.BudgetSummary?
    @Published var morningSummary: CoreOverloadEngine.BudgetSummary?
    @Published var daytimeSummary: CoreOverloadEngine.BudgetSummary?
    @Published var eveningSummary: CoreOverloadEngine.BudgetSummary?
    
    @Published var insight: CoreInsightCapsule?
    @Published var densityWarning: CoreOverloadEngine.DensityWarning?
    
    // UI state
    @Published var showAddSpotSheet = false
    @Published var showOverloadSheet = false
    @Published var showVariantsSheet = false
    @Published var selectedSpotForEdit: SpotCapsule?
    @Published var showUndoToast = false
    @Published var undoMessage = ""
    
    var dayKey: String {
        dayPlan?.localDayKey ?? RhythmDayBlueprint.dayKey(from: Date())
    }
    
    var currentRhythm: EnergyRhythm {
        activeVariant?.rhythm ?? config.defaultRhythm
    }
    
    var variantCount: Int {
        dayPlan?.variants.count ?? 0
    }
    
    var activeVariantTitle: String {
        activeVariant?.title ?? "Main"
    }
    
    var canUndo: Bool { vault.canUndo }
    
    var pinnedTemplates: [SparkTemplateSeed] {
        vault.state.templates.filter(\.isPinned)
    }
    
    var totalSpotCount: Int {
        activeVariant?.spotCount ?? 0
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    init(vault: VitalVault = .shared) {
        self.vault = vault
        self.config = vault.state.config
        
        // Observe vault changes
        vault.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.refreshFromState(state)
            }
            .store(in: &cancellables)
        
        // Initial load
        loadToday()
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Load & Refresh
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func loadToday() {
        _ = vault.ensureTodayPlan()
        refreshFromState(vault.state)
        
        // Record active day for streak
        vault.recordActiveDay()
    }
    
    private func refreshFromState(_ state: VitalAppState) {
        config = state.config
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        dayPlan = state.dayPlans.first { $0.localDayKey == todayKey }
        activeVariant = dayPlan?.activeVariant
        
        guard let variant = activeVariant else {
            clearDerived()
            return
        }
        
        // Update zone spots
        morningSpots = variant.spotsIn(zone: .morning)
        daytimeSpots = variant.spotsIn(zone: .daytime)
        eveningSpots = variant.spotsIn(zone: .evening)
        
        // Compute summaries
        daySummary = CoreOverloadEngine.daySummary(variant: variant, config: config)
        morningSummary = CoreOverloadEngine.zoneSummary(variant: variant, zone: .morning, config: config)
        daytimeSummary = CoreOverloadEngine.zoneSummary(variant: variant, zone: .daytime, config: config)
        eveningSummary = CoreOverloadEngine.zoneSummary(variant: variant, zone: .evening, config: config)
        
        // Full insight with suggestions
        insight = CoreOverloadEngine.analyze(variant: variant, config: config)
        densityWarning = CoreOverloadEngine.densityCheck(variant: variant, config: config)
    }
    
    private func clearDerived() {
        morningSpots = []
        daytimeSpots = []
        eveningSpots = []
        daySummary = nil
        morningSummary = nil
        daytimeSummary = nil
        eveningSummary = nil
        insight = nil
        densityWarning = nil
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Spots for Zone (helper)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func spots(for zone: DayZone) -> [SpotCapsule] {
        switch zone {
        case .morning: return morningSpots
        case .daytime: return daytimeSpots
        case .evening: return eveningSpots
        }
    }
    
    func zoneSummary(for zone: DayZone) -> CoreOverloadEngine.BudgetSummary? {
        switch zone {
        case .morning: return morningSummary
        case .daytime: return daytimeSummary
        case .evening: return eveningSummary
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Add Spot
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Add spot from template
    func addSpotFromTemplate(_ template: SparkTemplateSeed, zone: DayZone = .daytime) {
        var spot = template.toSpot(zone: zone, bufferDefault: config.defaultBufferBetweenMin)
        spot.travelBeforeMin = config.defaultTravelMin
        
        vault.addSpot(dayKey: dayKey, spot: spot)
        vault.incrementTemplateUsage(id: template.id)
        vault.earnXP(SurgeXPReward.addSpot)
        
        triggerHaptic(.light)
    }
    
    /// Add spot manually
    func addCustomSpot(title: String, durationMin: Int, kind: SpotKind, zone: DayZone) {
        let spot = SpotCapsule(
            title: title,
            kind: kind,
            zone: zone,
            durationMin: durationMin,
            travelBeforeMin: config.defaultTravelMin,
            bufferAfterMin: config.defaultBufferBetweenMin,
            effort: .normal
        )
        vault.addSpot(dayKey: dayKey, spot: spot)
        vault.earnXP(SurgeXPReward.addSpot)
        
        triggerHaptic(.light)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Edit Spot
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func updateSpot(_ spotId: UUID, mutation: (inout SpotCapsule) -> Void) {
        vault.updateSpot(dayKey: dayKey, spotId: spotId, mutation: mutation)
    }
    
    func updateSpotDuration(_ spotId: UUID, newDuration: Int) {
        updateSpot(spotId) { $0.durationMin = max(5, newDuration) }
    }
    
    func compressSpot(_ spotId: UUID, byMinutes: Int = 10) {
        updateSpot(spotId) { spot in
            spot.durationMin = max(5, spot.durationMin - byMinutes)
        }
        triggerHaptic(.medium)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Delete Spot
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func deleteSpot(_ spotId: UUID) {
        let spotName = activeVariant?.spots.first { $0.id == spotId }?.title ?? "Spot"
        vault.deleteSpot(dayKey: dayKey, spotId: spotId)
        
        undoMessage = "\"\(spotName)\" removed"
        withAnimation(.easeInOut(duration: 0.3)) {
            showUndoToast = true
        }
        autoDismissUndo()
        triggerHaptic(.medium)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Move Spot (Drag & Drop)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func moveSpot(_ spotId: UUID, toZone: DayZone, toIndex: Int) {
        vault.moveSpot(dayKey: dayKey, spotId: spotId, toZone: toZone, toIndex: toIndex)
        
        // First drag XP milestone
        if !vault.state.progress.achievedMilestones.contains("first_drag") {
            vault.recordMilestone("first_drag")
            vault.earnXP(SurgeXPReward.firstDragDrop)
        }
        
        triggerHaptic(.light)
    }
    
    /// Reorder within a zone after drag
    func reorderInZone(_ zone: DayZone, spotIds: [UUID]) {
        vault.reorderSpots(dayKey: dayKey, zone: zone, orderedIds: spotIds)
    }
    
    /// Move a spot to another zone (one-tap from context menu)
    func moveSpotToZone(_ spotId: UUID, zone: DayZone) {
        let targetIndex = spots(for: zone).count
        moveSpot(spotId, toZone: zone, toIndex: targetIndex)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Mode / Rhythm Switching
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func switchRhythm(_ rhythm: EnergyRhythm) {
        vault.updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
            plan.variants[vIdx].rhythm = rhythm
        }
        triggerHaptic(.light)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Variants
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func createVariant(title: String, copyFromCurrent: Bool = true) {
        let sourceId = copyFromCurrent ? activeVariant?.id : nil
        vault.addVariant(dayKey: dayKey, title: title, copyFromVariantId: sourceId)
        vault.earnXP(SurgeXPReward.createVariant)
        
        if !vault.state.progress.achievedMilestones.contains("first_variant") {
            vault.recordMilestone("first_variant")
        }
        
        triggerHaptic(.medium)
    }
    
    func switchToVariant(_ variantId: UUID) {
        vault.updateDayPlan(dayKey: dayKey) { plan in
            plan.selectedVariantId = variantId
        }
    }
    
    func deleteVariant(_ variantId: UUID) {
        vault.deleteVariant(dayKey: dayKey, variantId: variantId)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Apply Fix Suggestion
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func applySuggestion(_ suggestion: CoreFixWhisper) {
        guard let variant = activeVariant else { return }
        
        if suggestion.kind == .createVariant {
            createVariant(title: "Lighter Variant", copyFromCurrent: true)
            return
        }
        
        let modified = CoreOverloadEngine.applySuggestion(suggestion, to: variant, config: config)
        
        // Replace variant spots in vault
        vault.updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == variant.id }) else { return }
            plan.variants[vIdx].spots = modified.spots
            plan.variants[vIdx].updatedAt = Date()
        }
        
        vault.earnXP(SurgeXPReward.fixOverload)
        triggerHaptic(.success)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Undo
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func performUndo() {
        let success = vault.undoLastAction(dayKey: dayKey)
        if success {
            withAnimation(.easeInOut(duration: 0.3)) {
                showUndoToast = false
            }
            triggerHaptic(.light)
        }
    }
    
    private func autoDismissUndo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showUndoToast = false
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Formatted Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    var todayDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    var budgetDisplayText: String {
        daySummary?.displayText ?? "No plan"
    }
    
    var budgetUsagePercent: Double {
        daySummary?.usagePercent ?? 0
    }
    
    var overloadStatus: OverloadPulse {
        daySummary?.status ?? .comfortable
    }
    
    var hasSuggestions: Bool {
        !(insight?.suggestions.isEmpty ?? true)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Haptics
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    enum HapticStyle {
        case light, medium, success
    }
    
    private func triggerHaptic(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
