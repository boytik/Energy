import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧬 ZenConfigBlueprint — App-wide settings
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ZenConfigBlueprint: Codable, Equatable {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Energy mode defaults
    var defaultRhythm: EnergyRhythm = .normal
    
    // Buffers
    var defaultBufferBetweenMin: Int = 10      // 0 / 5 / 10 / 15
    var defaultTravelMin: Int = 0              // 0 / 10 / 20
    
    // Overload thresholds
    var overloadThresholdMin: Int = 15         // "overloaded" if exceeds budget by this
    var tightThresholdMin: Int = 5             // "tight" if within this range
    
    // Recommended spot counts per mode
    var recommendedSpotsLight: Int = 4
    var recommendedSpotsNormal: Int = 6
    var recommendedSpotsIntense: Int = 8
    
    // Zone budget distribution (must sum to 100)
    var zoneShareMorningPercent: Int = 30
    var zoneShareDaytimePercent: Int = 45
    var zoneShareEveningPercent: Int = 25
    
    // UX toggles
    var showOverloadBanner: Bool = true
    var enableUndoToasts: Bool = true
    
    // Budgets per mode (minutes)
    var budgetLightMin: Int = 300
    var budgetNormalMin: Int = 420
    var budgetIntenseMin: Int = 540
    
    /// Returns budget for a given rhythm
    func budgetMinutes(for rhythm: EnergyRhythm) -> Int {
        switch rhythm {
        case .light:   return budgetLightMin
        case .normal:  return budgetNormalMin
        case .intense: return budgetIntenseMin
        }
    }
    
    /// Returns recommended spots for a given rhythm
    func recommendedSpots(for rhythm: EnergyRhythm) -> Int {
        switch rhythm {
        case .light:   return recommendedSpotsLight
        case .normal:  return recommendedSpotsNormal
        case .intense: return recommendedSpotsIntense
        }
    }
    
    /// Returns zone budget in minutes for a given rhythm and zone
    func zoneBudget(rhythm: EnergyRhythm, zone: DayZone) -> Int {
        let total = budgetMinutes(for: rhythm)
        let share: Int
        switch zone {
        case .morning: share = zoneShareMorningPercent
        case .daytime: share = zoneShareDaytimePercent
        case .evening: share = zoneShareEveningPercent
        }
        return (total * share) / 100
    }
}











// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 💡 CoreFixWhisper — A suggestion to fix overload
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CoreFixWhisper: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: FixWhisperKind
    var title: String                // "Compress 'Meeting' by 10 min"
    var deltaMin: Int                // expected overload reduction
    var targetSpotId: UUID?          // which spot to affect
    var targetZone: DayZone?         // where to move
    var priority: Int = 50           // 0..100
    var createdAt: Date = Date()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🔙 CoreLastAction — For single-step Undo
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CoreActionKind: Int, Codable {
    case addSpot    = 0
    case moveSpot   = 1
    case editSpot   = 2
    case deleteSpot = 3
    case applyFix   = 4
}

struct CoreLastAction: Codable {
    var id: UUID = UUID()
    var actionKind: CoreActionKind
    var variantId: UUID?
    var spotId: UUID?
    var previousSpotSnapshot: SpotCapsule?    // for restore
    var previousZone: DayZone?                // for move undo
    var previousSortIndex: Int?               // for move undo
    var createdAt: Date = Date()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🏆 SurgeProgressCapsule — XP, Level & Streak
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SurgeProgressCapsule: Codable, Equatable {
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDayKey: String?     // tracks streak continuity
    var achievedMilestones: [String] = []  // e.g. "first_drag", "first_variant"
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var currentLevel: VitalityLevel {
        VitalityLevel.levelFor(xp: totalXP)
    }
    
    var progressToNext: Double {
        VitalityLevel.progressFraction(currentXP: totalXP)
    }
    
    var xpToNext: Int? {
        VitalityLevel.xpToNextLevel(currentXP: totalXP)
    }
    
    /// Add XP and update timestamp
    mutating func earnXP(_ amount: Int) {
        totalXP += amount
        updatedAt = Date()
    }
    
    /// Update streak based on today's dayKey
    mutating func recordActiveDay(dayKey: String) {
        guard dayKey != lastActiveDayKey else { return }
        
        if let lastKey = lastActiveDayKey, isConsecutive(lastKey, dayKey) {
            currentStreak += 1
        } else if lastActiveDayKey == nil {
            currentStreak = 1
        } else {
            currentStreak = 1 // streak broken
        }
        
        longestStreak = max(longestStreak, currentStreak)
        lastActiveDayKey = dayKey
        updatedAt = Date()
    }
    
    private func isConsecutive(_ key1: String, _ key2: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let d1 = formatter.date(from: key1),
              let d2 = formatter.date(from: key2) else { return false }
        let diff = Calendar.current.dateComponents([.day], from: d1, to: d2).day ?? 0
        return diff == 1
    }
}


