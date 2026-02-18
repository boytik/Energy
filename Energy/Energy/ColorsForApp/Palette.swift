import SwiftUI

// MARK: - 🎨 VitalPalette — All app colors with wellness-inspired names
// Based on RAL 1018 (Zinc Yellow), RAL 7042 (Traffic Grey A), RAL 9005 (Jet Black)

enum VitalPalette {
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Primary Background (RAL 1018 Zinc Yellow)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Main screen background — warm energetic yellow
    static let glowZincSunrise     = Color(red: 0.961, green: 0.859, blue: 0.263)
    
    /// Softer yellow for onboarding / splash backgrounds
    static let glowSoftMorning     = Color(red: 0.973, green: 0.918, blue: 0.557)
    
    /// Very subtle warm tint — for large empty areas
    static let glowWarmDawn        = Color(red: 0.980, green: 0.941, blue: 0.710)
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Surfaces & Cards (RAL 7042 Traffic Grey A)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Dark surface — section headers, overlays
    static let driftMistSurface    = Color(red: 0.588, green: 0.608, blue: 0.612)
    
    /// Medium card surface
    static let driftCloudLayer     = Color(red: 0.749, green: 0.761, blue: 0.765)
    
    /// Light card / sheet background (dark: darker grey)
    static let driftFogVeil        = Color(red: 0.22, green: 0.22, blue: 0.24)
    
    /// Near-white surface for elevated cards (dark: dark grey card)
    static let driftSnowField      = Color(red: 0.16, green: 0.16, blue: 0.18)
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Text & Buttons (dark theme)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Primary text, primary buttons
    static let zenJetStone         = Color(red: 0.96, green: 0.96, blue: 0.98)
    
    /// Secondary text, icons
    static let zenCharcoalDepth    = Color(red: 0.82, green: 0.82, blue: 0.84)
    
    /// Tertiary / placeholder text
    static let zenAshWhisper       = Color(red: 0.62, green: 0.62, blue: 0.64)
    
    /// Disabled text / subtle dividers
    static let zenSilentStone      = Color(red: 0.48, green: 0.48, blue: 0.50)
    
    
    /// Day is comfortable — muted sage green
    static let pulseComfortSage    = Color(red: 0.467, green: 0.608, blue: 0.494)
    
    /// Day is tight — muted amber
    static let pulseCautionAmber   = Color(red: 0.776, green: 0.639, blue: 0.306)
    
    /// Day is overloaded — muted rust
    static let pulseOverloadRust   = Color(red: 0.686, green: 0.357, blue: 0.310)
    
    /// XP bar fill, achievement shimmer
    static let surgeXPGold         = Color(red: 0.855, green: 0.729, blue: 0.235)
    
    /// Level-up accent (muted violet)
    static let bloomLevelViolet    = Color(red: 0.533, green: 0.420, blue: 0.620)
    
    /// Streak fire accent (muted orange)
    static let surgeStreakEmber    = Color(red: 0.804, green: 0.498, blue: 0.243)
    
    
    /// Morning zone tint — warm peach
    static let rhythmMorningPeach  = Color(red: 0.945, green: 0.835, blue: 0.725)
    
    /// Daytime zone tint — warm sand
    static let rhythmDaytimeSand   = Color(red: 0.933, green: 0.898, blue: 0.780)
    
    /// Evening zone tint — cool lavender
    static let rhythmEveningDusk   = Color(red: 0.812, green: 0.796, blue: 0.878)
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Pure white for overlays / modal sheets
    static let breathPureLight     = Color.white
    
    /// Card shadow color (dark: stronger shadow)
    static let driftShadowMist     = Color.black.opacity(0.35)
    
    /// Selected chip/button background (dark with golden tint)
    static let chipSelectedBg      = Color(red: 0.28, green: 0.24, blue: 0.10)
}

// MARK: - ⚡ EnergyRhythm — The three energy modes (Light / Normal / Intense)

enum EnergyRhythm: Int, Codable, CaseIterable, Identifiable {
    case light   = 0
    case normal  = 1
    case intense = 2
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .light:   return "Light"
        case .normal:  return "Normal"
        case .intense: return "Intense"
        }
    }
    
    var icon: String {
        switch self {
        case .light:   return "leaf.fill"
        case .normal:  return "flame.fill"
        case .intense: return "bolt.fill"
        }
    }
    
    /// Default daily budget in minutes
    var defaultBudgetMinutes: Int {
        switch self {
        case .light:   return 300   // 5 hours
        case .normal:  return 420   // 7 hours
        case .intense: return 540   // 9 hours
        }
    }
    
    /// Recommended maximum spot count
    var recommendedSpotCount: Int {
        switch self {
        case .light:   return 4
        case .normal:  return 6
        case .intense: return 8
        }
    }
    
    /// Tint color for mode badge
    var tintColor: Color {
        switch self {
        case .light:   return VitalPalette.pulseComfortSage
        case .normal:  return VitalPalette.pulseCautionAmber
        case .intense: return VitalPalette.pulseOverloadRust
        }
    }
}

// MARK: - 🌅 DayZone — Morning / Daytime / Evening

enum DayZone: Int, Codable, CaseIterable, Identifiable {
    case morning = 0
    case daytime = 1
    case evening = 2
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .morning: return "Morning"
        case .daytime: return "Daytime"
        case .evening: return "Evening"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .daytime: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }
    
    /// Default percentage of daily budget allocated to this zone
    var defaultBudgetShare: Double {
        switch self {
        case .morning: return 0.30  // 30%
        case .daytime: return 0.45  // 45%
        case .evening: return 0.25  // 25%
        }
    }
    
    /// Zone header tint color
    var tintColor: Color {
        switch self {
        case .morning: return VitalPalette.rhythmMorningPeach
        case .daytime: return VitalPalette.rhythmDaytimeSand
        case .evening: return VitalPalette.rhythmEveningDusk
        }
    }
}

// MARK: - 📌 SpotKind — Type of activity

enum SpotKind: Int, Codable, CaseIterable, Identifiable {
    case generic  = 0
    case work     = 1
    case meeting  = 2
    case sport    = 3
    case errand   = 4
    case rest     = 5
    case travel   = 6
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .generic: return "General"
        case .work:    return "Work"
        case .meeting: return "Meeting"
        case .sport:   return "Sport"
        case .errand:  return "Errand"
        case .rest:    return "Rest"
        case .travel:  return "Travel"
        }
    }
    
    var icon: String {
        switch self {
        case .generic: return "circle.fill"
        case .work:    return "laptopcomputer"
        case .meeting: return "person.2.fill"
        case .sport:   return "figure.run"
        case .errand:  return "cart.fill"
        case .rest:    return "cup.and.saucer.fill"
        case .travel:  return "car.fill"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .generic: return VitalPalette.zenAshWhisper
        case .work:    return VitalPalette.pulseCautionAmber
        case .meeting: return VitalPalette.bloomLevelViolet
        case .sport:   return VitalPalette.pulseComfortSage
        case .errand:  return VitalPalette.rhythmDaytimeSand
        case .rest:    return VitalPalette.rhythmEveningDusk
        case .travel:  return VitalPalette.surgeXPGold
        }
    }
}

// MARK: - 🚦 OverloadPulse — Status of overload

enum OverloadPulse: Int, Codable {
    case comfortable = 0
    case tight       = 1
    case overloaded  = 2
    
    var title: String {
        switch self {
        case .comfortable: return "Comfortable"
        case .tight:       return "Getting Tight"
        case .overloaded:  return "Overloaded"
        }
    }
    
    var icon: String {
        switch self {
        case .comfortable: return "checkmark.circle.fill"
        case .tight:       return "exclamationmark.triangle.fill"
        case .overloaded:  return "xmark.octagon.fill"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .comfortable: return VitalPalette.pulseComfortSage
        case .tight:       return VitalPalette.pulseCautionAmber
        case .overloaded:  return VitalPalette.pulseOverloadRust
        }
    }
}

// MARK: - 🔧 FixWhisperKind — Types of overload fix suggestions

enum FixWhisperKind: Int, Codable {
    case compress       = 0
    case moveZone       = 1
    case insertBreak    = 2
    case removeSpot     = 3
    case createVariant  = 4
}

// MARK: - 💪 SpotEffort — User-labeled energy cost (does NOT affect time overload)

enum SpotEffort: Int, Codable, CaseIterable {
    case light  = 0
    case normal = 1
    case heavy  = 2
    
    var title: String {
        switch self {
        case .light:  return "Light"
        case .normal: return "Normal"
        case .heavy:  return "Heavy"
        }
    }
    
    var icon: String {
        switch self {
        case .light:  return "hare.fill"
        case .normal: return "figure.walk"
        case .heavy:  return "figure.highintensity.intervaltraining"
        }
    }
}

// MARK: - 🏆 VitalityLevel — Gamification levels

struct VitalityLevel {
    let level: Int
    let title: String
    let badge: String
    let xpThreshold: Int
    
    static let allLevels: [VitalityLevel] = [
        VitalityLevel(level: 1,  title: "Beginner Breather", badge: "🌱", xpThreshold: 0),
        VitalityLevel(level: 2,  title: "Morning Walker", badge: "🌿", xpThreshold: 50),
        VitalityLevel(level: 3,  title: "Flow Finder", badge: "🌊", xpThreshold: 150),
        VitalityLevel(level: 4,  title: "Rhythm Keeper", badge: "🎵", xpThreshold: 350),
        VitalityLevel(level: 5,  title: "Balance Master", badge: "⚖️", xpThreshold: 600),
        VitalityLevel(level: 6,  title: "Energy Sage", badge: "🧘", xpThreshold: 1000),
        VitalityLevel(level: 7,  title: "Vitality Champion", badge: "🏆", xpThreshold: 1500),
        VitalityLevel(level: 8,  title: "Zen Architect", badge: "🏛️", xpThreshold: 2500),
        VitalityLevel(level: 9,  title: "Flow Legend", badge: "✨", xpThreshold: 4000),
        VitalityLevel(level: 10, title: "Day Alchemist", badge: "🔮", xpThreshold: 6000),
    ]
    
    /// Returns the level for a given XP total
    static func levelFor(xp: Int) -> VitalityLevel {
        var result = allLevels[0]
        for lvl in allLevels {
            if xp >= lvl.xpThreshold {
                result = lvl
            } else {
                break
            }
        }
        return result
    }
    
    /// XP needed to reach next level (nil if max)
    static func xpToNextLevel(currentXP: Int) -> Int? {
        guard let next = allLevels.first(where: { $0.xpThreshold > currentXP }) else {
            return nil
        }
        return next.xpThreshold - currentXP
    }
    
    /// Progress fraction (0...1) within current level
    static func progressFraction(currentXP: Int) -> Double {
        let current = levelFor(xp: currentXP)
        guard let next = allLevels.first(where: { $0.xpThreshold > currentXP }) else {
            return 1.0
        }
        let range = next.xpThreshold - current.xpThreshold
        guard range > 0 else { return 1.0 }
        let progress = currentXP - current.xpThreshold
        return Double(progress) / Double(range)
    }
}

// MARK: - 🎯 XP Reward Table

enum SurgeXPReward {
    static let createDayPlan        = 10
    static let addSpot              = 3
    static let stayWithinBudget     = 25
    static let fixOverload          = 8
    static let createVariant        = 5
    static let dailyStreakBonus     = 15
    static let firstDragDrop        = 5
    static let completeOnboarding   = 20
    static let addPetReaction       = 4
}
