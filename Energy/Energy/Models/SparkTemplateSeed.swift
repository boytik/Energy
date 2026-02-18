//
//  SparkTemplateSeed.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ⚡ SparkTemplateSeed — Reusable spot template
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SparkTemplateSeed: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var defaultDurationMin: Int
    var defaultTravelMin: Int?
    var defaultBufferMin: Int?
    var kind: SpotKind = .generic
    var iconName: String?
    var isPinned: Bool = false
    var usageCount: Int = 0
    var lastUsedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    /// Convert template into a live SpotCapsule
    func toSpot(zone: DayZone = .daytime, bufferDefault: Int = 10) -> SpotCapsule {
        SpotCapsule(
            title: title,
            kind: kind,
            zone: zone,
            durationMin: defaultDurationMin,
            travelBeforeMin: defaultTravelMin ?? 0,
            bufferAfterMin: defaultBufferMin ?? bufferDefault,
            iconName: iconName,
            originTemplateId: id
        )
    }
    
    /// Built-in starter templates
    static let starterPack: [SparkTemplateSeed] = [
        SparkTemplateSeed(title: "Coffee Break",   defaultDurationMin: 20,  kind: .rest,    iconName: "cup.and.saucer.fill", isPinned: true),
        SparkTemplateSeed(title: "Workout",         defaultDurationMin: 60,  kind: .sport,   iconName: "figure.run",          isPinned: true),
        SparkTemplateSeed(title: "Meeting",          defaultDurationMin: 90,  kind: .meeting, iconName: "person.2.fill",       isPinned: true),
        SparkTemplateSeed(title: "Grocery Run",      defaultDurationMin: 25,  kind: .errand,  iconName: "cart.fill",           isPinned: true),
        SparkTemplateSeed(title: "Walk",             defaultDurationMin: 40,  kind: .sport,   iconName: "figure.walk",         isPinned: true),
        SparkTemplateSeed(title: "Deep Work Block",  defaultDurationMin: 120, kind: .work,    iconName: "laptopcomputer",      isPinned: true),
        SparkTemplateSeed(title: "Rest & Recharge",  defaultDurationMin: 15,  kind: .rest,    iconName: "bed.double.fill",     isPinned: true),
        SparkTemplateSeed(title: "Commute",          defaultDurationMin: 30,  kind: .travel,  iconName: "car.fill"),
        SparkTemplateSeed(title: "Quick Call",        defaultDurationMin: 15,  kind: .meeting, iconName: "phone.fill"),
        SparkTemplateSeed(title: "Cooking",           defaultDurationMin: 45,  kind: .errand,  iconName: "frying.pan.fill"),
        SparkTemplateSeed(title: "Reading",           defaultDurationMin: 30,  kind: .rest,    iconName: "book.fill"),
        SparkTemplateSeed(title: "Yoga / Stretch",    defaultDurationMin: 25,  kind: .sport,   iconName: "figure.yoga"),
    ]
}
