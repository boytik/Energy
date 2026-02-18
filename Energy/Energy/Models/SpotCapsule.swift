//
//  SpotCapsule.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📍 SpotCapsule — A single activity/place in a day plan
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SpotCapsule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var kind: SpotKind = .generic
    var zone: DayZone = .daytime
    var sortIndex: Int = 0
    
    var durationMin: Int = 30
    var travelBeforeMin: Int = 0
    var bufferAfterMin: Int = 0
    
    var effort: SpotEffort = .normal
    var note: String = ""
    var iconName: String?           // SF Symbol override
    var originTemplateId: UUID?     // which template it came from
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    /// Total load = duration + travel + buffer
    var computedLoadMin: Int {
        durationMin + travelBeforeMin + bufferAfterMin
    }
    
    /// The icon to display (custom or from SpotKind)
    var displayIcon: String {
        iconName ?? kind.icon
    }
}
