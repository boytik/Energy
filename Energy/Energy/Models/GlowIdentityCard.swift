//
//  GlowIdentityCard.swift
//  Energy
//
//  Created by Евгений on 18.02.2026.
//

import Foundation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 😊 GlowIdentityCard — User profile
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct GlowIdentityCard: Codable, Equatable {
    var avatarEmoji: String = "😊"
    var displayName: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    /// All available emoji avatars grouped by category
    static let avatarOptions: [String: [String]] = [
        "Faces":   ["😊", "😎", "🤓", "🧘", "💪", "🌟", "🦊", "🐱"],
        "Nature":  ["🌻", "🌿", "🍀", "🌸", "🌊", "⛰️", "🌅", "🔥"],
        "Symbols": ["⚡", "💎", "🎯", "🏆", "✨", "🦋", "🕊️", "🎭"],
    ]
    
    /// Avatar categories for picker UI (name + emojis)
    struct AvatarCategory: Identifiable {
        let id = UUID()
        let name: String
        let emojis: [String]
    }
    
    static var avatarCategories: [AvatarCategory] {
        avatarOptions.map { AvatarCategory(name: $0.key, emojis: $0.value) }
    }
}
