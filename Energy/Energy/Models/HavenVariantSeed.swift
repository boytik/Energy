//
//  HavenVariantSeed.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🌿 HavenVariantSeed — A variant of a day plan
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct HavenVariantSeed: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String = "Main"
    var rhythm: EnergyRhythm = .normal
    var isPrimary: Bool = true
    
    var spots: [SpotCapsule] = []
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // ── Computed Summary ──
    
    var totalPlannedMin: Int {
        spots.reduce(0) { $0 + $1.computedLoadMin }
    }
    
    var spotCount: Int { spots.count }
    
    func spotsIn(zone: DayZone) -> [SpotCapsule] {
        spots.filter { $0.zone == zone }
            .sorted { $0.sortIndex < $1.sortIndex }
    }
    
    func plannedMinIn(zone: DayZone) -> Int {
        spotsIn(zone: zone).reduce(0) { $0 + $1.computedLoadMin }
    }
    
    func spotCountIn(zone: DayZone) -> Int {
        spotsIn(zone: zone).count
    }
}
