//
//  BloomStatsCapsule.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📊 Aggregate Statistics Capsule
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BloomStatsCapsule {
    let totalDaysPlanned: Int
    let comfortableDays: Int
    let tightDays: Int
    let overloadedDays: Int
    let averageOverloadMin: Double
    let mostUsedSpotKind: SpotKind?
    let totalSpotsCreated: Int
    let favoriteZone: DayZone?
    
    var comfortRate: Double {
        guard totalDaysPlanned > 0 else { return 0 }
        return Double(comfortableDays) / Double(totalDaysPlanned)
    }
}
