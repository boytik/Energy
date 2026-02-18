//
//  VitalAppState.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🗂 AppState — Wrapper for all persisted data
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct VitalAppState: Codable {
    var config: ZenConfigBlueprint = ZenConfigBlueprint()
    var dayPlans: [RhythmDayBlueprint] = []
    var templates: [SparkTemplateSeed] = SparkTemplateSeed.starterPack
    var progress: SurgeProgressCapsule = SurgeProgressCapsule()
    var identity: GlowIdentityCard = GlowIdentityCard()
    var lastAction: CoreLastAction?
    
    // Tab 4: Pet care data
    var petProfiles: [SparkPetProfileCapsule] = []
    var careProducts: [SparkCareProductCapsule] = []
    var petReactions: [SparkPetReactionSeed] = []
    
    var hasCompletedOnboarding: Bool = false
    
    /// Find or create today's day plan
    mutating func findOrCreateToday(rhythm: EnergyRhythm? = nil) -> RhythmDayBlueprint {
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        if let idx = dayPlans.firstIndex(where: { $0.localDayKey == todayKey }) {
            return dayPlans[idx]
        }
        let r = rhythm ?? config.defaultRhythm
        let plan = RhythmDayBlueprint.blank(for: Date(), rhythm: r)
        dayPlans.append(plan)
        return plan
    }
    
    /// Find a day plan by key
    func dayPlan(for dayKey: String) -> RhythmDayBlueprint? {
        dayPlans.first { $0.localDayKey == dayKey }
    }
}
