//
//  RhythmDayBlueprint.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📅 RhythmDayBlueprint — A single day's plan container
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct RhythmDayBlueprint: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var dateStart: Date
    var localDayKey: String            // "YYYY-MM-DD" — unique per day
    var selectedVariantId: UUID?
    
    var variants: [HavenVariantSeed] = []
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    /// The currently active variant
    var activeVariant: HavenVariantSeed? {
        if let selectedId = selectedVariantId {
            return variants.first { $0.id == selectedId }
        }
        return variants.first { $0.isPrimary } ?? variants.first
    }
    
    /// Generate a day key from a Date
    static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    /// Create a blank day plan for a date
    static func blank(for date: Date, rhythm: EnergyRhythm = .normal) -> RhythmDayBlueprint {
        let key = dayKey(from: date)
        let mainVariant = HavenVariantSeed(
            title: "Main",
            rhythm: rhythm,
            isPrimary: true
        )
        let plan = RhythmDayBlueprint(
            dateStart: date,
            localDayKey: key,
            selectedVariantId: mainVariant.id,
            variants: [mainVariant]
        )
        return plan
    }
}
