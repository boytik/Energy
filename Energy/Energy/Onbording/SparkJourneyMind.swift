import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧠 SparkJourneyMind — Onboarding ViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Manages a 4-step onboarding flow:
//   Step 0: Welcome — app overview with 3 key features
//   Step 1: Choose Tempo — select Light / Normal / Intense
//   Step 2: Pick Starters — select 3-5 template spots
//   Step 3: All Set — summary + create first day
//
// View file: SparkJourneyPortal.swift

final class SparkJourneyMind: ObservableObject {
    
    // ── Step Management ──
    @Published var currentStep: Int = 0
    @Published var direction: NavigationDirection = .forward
    
    let totalSteps = 4
    
    enum NavigationDirection {
        case forward, backward
    }
    
    // ── Step 1: Tempo Selection ──
    @Published var selectedRhythm: EnergyRhythm = .normal
    
    // ── Step 1: Buffer Config ──
    @Published var selectedBufferMin: Int = 10
    @Published var selectedTravelMin: Int = 0
    
    let bufferOptions = [0, 5, 10, 15]
    let travelOptions = [0, 10, 20]
    
    // ── Step 2: Starter Spots ──
    @Published var availableTemplates: [SparkTemplateSeed] = SparkTemplateSeed.starterPack
    @Published var selectedTemplateIds: Set<UUID> = []
    
    var selectedTemplates: [SparkTemplateSeed] {
        availableTemplates.filter { selectedTemplateIds.contains($0.id) }
    }
    
    var starterPickCount: Int { selectedTemplateIds.count }
    var canProceedFromStarters: Bool { starterPickCount >= 2 }
    
    // ── Computed ──
    
    var canGoNext: Bool {
        switch currentStep {
        case 0: return true                          // Welcome — always
        case 1: return true                          // Tempo — always (has default)
        case 2: return canProceedFromStarters         // Need 2+ spots
        case 3: return true                          // All Set — always
        default: return false
        }
    }
    
    var canGoBack: Bool { currentStep > 0 }
    
    var isLastStep: Bool { currentStep == totalSteps - 1 }
    
    var progressFraction: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var nextButtonTitle: String {
        switch currentStep {
        case 0: return "Let's Begin"
        case 1: return "Continue"
        case 2: return "Create My Day"
        case 3: return "Start Planning"
        default: return "Next"
        }
    }
    
    // ── Budget Preview (for step 1) ──
    
    var budgetPreviewMin: Int {
        selectedRhythm.defaultBudgetMinutes
    }
    
    var budgetPreviewHours: String {
        let h = budgetPreviewMin / 60
        let m = budgetPreviewMin % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
    
    var overheadExample: String {
        let spots = 3
        let overhead = (spots - 1) * selectedBufferMin
        return "\(spots) spots + \(selectedBufferMin) min buffer = +\(overhead) min overhead"
    }
    
    // ── Welcome Features (step 0) ──
    
    struct WelcomeFeature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }
    
    let welcomeFeatures: [WelcomeFeature] = [
        WelcomeFeature(
            icon: "bolt.heart.fill",
            title: "Plan by Energy",
            subtitle: "Distribute tasks across Morning, Daytime & Evening based on your energy, not the clock"
        ),
        WelcomeFeature(
            icon: "exclamationmark.triangle.fill",
            title: "Spot Overload Early",
            subtitle: "See when your day is too packed before it starts — and fix it in one tap"
        ),
        WelcomeFeature(
            icon: "trophy.fill",
            title: "Earn & Grow",
            subtitle: "Gain Vitality XP for smart planning, build streaks, and level up your wellness game"
        ),
    ]
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func goNext() {
        guard canGoNext, currentStep < totalSteps - 1 else { return }
        direction = .forward
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep += 1
        }
    }
    
    func goBack() {
        guard canGoBack else { return }
        direction = .backward
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep -= 1
        }
    }
    
    func selectRhythm(_ rhythm: EnergyRhythm) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedRhythm = rhythm
        }
    }
    
    func toggleTemplate(_ template: SparkTemplateSeed) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedTemplateIds.contains(template.id) {
                selectedTemplateIds.remove(template.id)
            } else {
                selectedTemplateIds.insert(template.id)
            }
        }
    }
    
    func isTemplateSelected(_ template: SparkTemplateSeed) -> Bool {
        selectedTemplateIds.contains(template.id)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Finish & Create First Day
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Apply all selections to vault and create the first day plan (single commit to avoid race with deferred state updates)
    func finishOnboarding(vault: VitalVault) {
        vault.applyOnboardingComplete(
            rhythm: selectedRhythm,
            bufferMin: selectedBufferMin,
            travelMin: selectedTravelMin,
            templates: selectedTemplates,
            zoneForIndex: { [weak self] index, total in self?.zoneForIndex(index, total: total) ?? .daytime }
        )
    }
    
    /// Distribute spots across zones based on position
    private func zoneForIndex(_ index: Int, total: Int) -> DayZone {
        guard total > 0 else { return .daytime }
        let third = max(1, total / 3)
        if index < third { return .morning }
        if index < third * 2 { return .daytime }
        return .evening
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Summary (Step 3)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    struct JourneySummary {
        let rhythmTitle: String
        let rhythmIcon: String
        let budgetText: String
        let spotCount: Int
        let spotNames: [String]
        let bufferMin: Int
    }
    
    var summary: JourneySummary {
        JourneySummary(
            rhythmTitle: selectedRhythm.title,
            rhythmIcon: selectedRhythm.icon,
            budgetText: budgetPreviewHours,
            spotCount: starterPickCount,
            spotNames: selectedTemplates.map(\.title),
            bufferMin: selectedBufferMin
        )
    }
}
