import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🏆 GoldBlackGradientBackground — App-wide gradient
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Gold-to-black gradient used across all screens via ZStack.
// Diagonal gradient: top-leading (gold) → bottom-trailing (black).

struct GoldBlackGradientBackground: View {
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.28, blue: 0.10),   // gold accent (top)
                Color(red: 0.18, green: 0.14, blue: 0.06),  // warm dark gold
                Color(red: 0.08, green: 0.06, blue: 0.04),  // deep black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View extension for convenience

extension View {
    func goldBlackBackground() -> some View {
        self.background(
            GoldBlackGradientBackground()
                .ignoresSafeArea()
        )
    }
}
