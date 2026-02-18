//
//  SparkPetProfileCapsule.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🐾 SparkPetReactionSeed — Pet hygiene reaction log
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SparkPetProfileCapsule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var species: String           // "Dog", "Cat", "Rabbit", etc.
    var emoji: String = "🐾"
    var createdAt: Date = Date()
}

struct SparkCareProductCapsule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String              // "Shampoo X", "Flea drops Y"
    var category: String = ""     // "Shampoo", "Spray", "Drops", "Cream"
    var brand: String = ""
    var createdAt: Date = Date()
}

enum PetReactionRating: Int, Codable, CaseIterable {
    case terrible  = 1
    case bad       = 2
    case neutral   = 3
    case good      = 4
    case excellent = 5
    
    var emoji: String {
        switch self {
        case .terrible:  return "😫"
        case .bad:       return "😟"
        case .neutral:   return "😐"
        case .good:      return "😊"
        case .excellent: return "🤩"
        }
    }
    
    var title: String {
        switch self {
        case .terrible:  return "Terrible"
        case .bad:       return "Bad"
        case .neutral:   return "Neutral"
        case .good:      return "Good"
        case .excellent: return "Excellent"
        }
    }
}

struct SparkPetReactionSeed: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var petId: UUID
    var productId: UUID
    var rating: PetReactionRating
    var notes: String = ""
    var dateRecorded: Date = Date()
}

