//
//  CoreInsightCapsule.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🔍 CoreInsightCapsule — Overload analysis result
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CoreInsightCapsule: Codable, Equatable {
    var variantId: UUID
    var computedAt: Date = Date()
    var status: OverloadPulse
    
    var overloadDeltaMin: Int          // planned - budget (positive = overloaded)
    var tightDeltaMin: Int             // how close to tight threshold
    
    var recommendedSpots: Int
    var actualSpots: Int
    
    var bufferTotalMin: Int
    var travelTotalMin: Int
    var durationTotalMin: Int
    
    var primaryOverZone: DayZone?      // zone with highest overload
    var overMorningDeltaMin: Int = 0
    var overDaytimeDeltaMin: Int = 0
    var overEveningDeltaMin: Int = 0
    
    var suggestions: [CoreFixWhisper] = []
}
