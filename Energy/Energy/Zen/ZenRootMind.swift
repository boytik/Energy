import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧠 ZenRootMind — Profile & Settings ViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Drives the "Profile" tab:
//   - Identity: avatar emoji picker, display name
//   - Gamification: XP, level, streak, milestones
//   - Statistics: BloomStatsCapsule display
//   - Config: default rhythm, buffer, travel, thresholds
//   - Data management: export JSON, reset all data
//   - Share: activity sheet for stats summary
//
// View file: ZenRootGarden.swift

final class ZenRootMind: ObservableObject {
    
    // ── Dependencies ──
    private let vault: VitalVault
    private var cancellables = Set<AnyCancellable>()
    
    // ── Published State ──
    @Published var identity: GlowIdentityCard
    @Published var progress: SurgeProgressCapsule
    @Published var config: ZenConfigBlueprint
    @Published var stats: BloomStatsCapsule
    
    // UI state
    @Published var showAvatarPicker = false
    @Published var showConfigEditor = false
    @Published var showTemplateEditor = false
    @Published var templateToEdit: SparkTemplateSeed?
    @Published var showResetConfirmation = false
    @Published var showExportShare = false
    @Published var showStatsShare = false
    @Published var exportData: Data?
    @Published var editingName = false
    @Published var nameField = ""
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    init(vault: VitalVault = .shared) {
        self.vault = vault
        self.identity = vault.state.identity
        self.progress = vault.state.progress
        self.config = vault.state.config
        self.stats = vault.computeStats()
        
        vault.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.identity = state.identity
                self?.progress = state.progress
                self?.config = state.config
                self?.stats = vault.computeStats()
            }
            .store(in: &cancellables)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Gamification Display
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    var currentLevel: VitalityLevel { progress.currentLevel }
    var xpToNext: Int { progress.xpToNext ?? 0 }
    var progressToNext: Double { progress.progressToNext }
    
    var levelTitle: String {
        "\(currentLevel.badge) \(currentLevel.title)"
    }
    
    var xpDisplayText: String {
        "\(progress.totalXP) XP"
    }
    
    var streakText: String? {
        guard progress.currentStreak > 0 else { return nil }
        return "🔥 \(progress.currentStreak) day streak"
    }
    
    var longestStreakText: String {
        "\(progress.longestStreak) days"
    }
    
    var milestoneCount: Int {
        progress.achievedMilestones.count
    }
    
    // Next level info
    var nextLevelInfo: String {
        let next = currentLevel.level + 1
        if next > 10 { return "Max level reached!" }
        let nextLevel = VitalityLevel.levelFor(xp: currentLevel.xpThreshold + xpToNext + 1)
        return "\(xpToNext) XP to \(nextLevel.badge) \(nextLevel.title)"
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Stats Display
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    var comfortRatePercent: Int {
        Int(stats.comfortRate * 100)
    }
    
    var statsRows: [StatRow] {
        var rows: [StatRow] = [
            StatRow(icon: "calendar", label: "Days Planned", value: "\(stats.totalDaysPlanned)"),
            StatRow(icon: "checkmark.circle", label: "Comfortable", value: "\(stats.comfortableDays)", color: VitalPalette.pulseComfortSage),
            StatRow(icon: "exclamationmark.triangle", label: "Tight", value: "\(stats.tightDays)", color: VitalPalette.pulseCautionAmber),
            StatRow(icon: "xmark.octagon", label: "Overloaded", value: "\(stats.overloadedDays)", color: VitalPalette.pulseOverloadRust),
            StatRow(icon: "mappin.circle", label: "Total Spots", value: "\(stats.totalSpotsCreated)"),
        ]
        
        if let kind = stats.mostUsedSpotKind {
            rows.append(StatRow(icon: kind.icon, label: "Most Used Type", value: kind.title))
        }
        if let zone = stats.favoriteZone {
            rows.append(StatRow(icon: zone.icon, label: "Favorite Zone", value: zone.title))
        }
        if stats.averageOverloadMin > 0 {
            rows.append(StatRow(
                icon: "clock.badge.exclamationmark",
                label: "Avg Overload",
                value: "\(Int(stats.averageOverloadMin)) min",
                color: VitalPalette.pulseOverloadRust
            ))
        }
        
        return rows
    }
    
    struct StatRow: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let value: String
        var color: Color = VitalPalette.zenCharcoalDepth
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Identity Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func selectAvatar(_ emoji: String) {
        vault.updateAvatar(emoji)
        showAvatarPicker = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func startEditingName() {
        nameField = identity.displayName
        editingName = true
    }
    
    func saveName() {
        let trimmed = nameField.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            vault.updateDisplayName(trimmed)
        }
        editingName = false
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Config Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func updateDefaultRhythm(_ rhythm: EnergyRhythm) {
        vault.updateConfig { $0.defaultRhythm = rhythm }
    }
    
    func updateDefaultBuffer(_ minutes: Int) {
        vault.updateConfig { $0.defaultBufferBetweenMin = minutes }
    }
    
    func updateDefaultTravel(_ minutes: Int) {
        vault.updateConfig { $0.defaultTravelMin = minutes }
    }
    
    func updateTightThreshold(_ minutes: Int) {
        vault.updateConfig { $0.tightThresholdMin = minutes }
    }
    
    func updateOverloadThreshold(_ minutes: Int) {
        vault.updateConfig { $0.overloadThresholdMin = minutes }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Export & Reset
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func exportJSON() {
        exportData = vault.exportJSON()
        if exportData != nil {
            showExportShare = true
        }
    }
    
    var fileSizeText: String {
        vault.fileSizeFormatted
    }
    
    func resetAllData() {
        vault.resetAllData()
        showResetConfirmation = false
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Share Stats
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Spot Templates (Quick Add)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    var templates: [SparkTemplateSeed] {
        vault.state.templates
    }
    
    var pinnedTemplates: [SparkTemplateSeed] {
        vault.state.templates.filter(\.isPinned)
    }
    
    func addTemplate(_ template: SparkTemplateSeed) {
        vault.addTemplate(template)
    }
    
    func updateTemplate(id: UUID, mutation: (inout SparkTemplateSeed) -> Void) {
        vault.updateTemplate(id: id, mutation: mutation)
    }
    
    func deleteTemplate(id: UUID) {
        vault.deleteTemplate(id: id)
    }
    
    func toggleTemplatePin(_ template: SparkTemplateSeed) {
        vault.updateTemplate(id: template.id) { $0.isPinned.toggle() }
    }
    
    func startAddTemplate() {
        templateToEdit = nil
        showTemplateEditor = true
    }
    
    func startEditTemplate(_ template: SparkTemplateSeed) {
        templateToEdit = template
        showTemplateEditor = true
    }
    
    var shareStatsText: String {
        """
        ⚡ My c10 Energy Route Stats
        
        \(levelTitle) • \(xpDisplayText)
        \(streakText ?? "No active streak")
        
        📊 \(stats.totalDaysPlanned) days planned
        ✅ \(comfortRatePercent)% comfort rate
        📍 \(stats.totalSpotsCreated) total spots
        
        Plan by energy, not by clock 💛
        """
    }
    
}
