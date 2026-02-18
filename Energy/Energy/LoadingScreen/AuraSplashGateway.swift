import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🌅 AuraSplashGateway — Animated loading screen
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Shows for ~2.5 seconds on cold launch.
// Features:
//   - Golden breathing background (auraGateway preset)
//   - Pulsing concentric rings
//   - App logo / emoji badge
//   - Rotating abstract loading phrases
//   - Animated progress dots
//   - Smooth fade-out transition
//
// After completion, calls `onFinished()` to hand off
// to onboarding or main tab shell.

struct AuraSplashGateway: View {
    
    let onFinished: () -> Void
    
    // ── Animation state ──
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var phraseIndex: Int = 0
    @State private var phraseOpacity: Double = 0
    @State private var dotsOpacity: Double = 0
    @State private var overallOpacity: Double = 1
    @State private var ring1Visible: Bool = false
    @State private var ring2Visible: Bool = false
    @State private var ring3Visible: Bool = false
    @State private var orbsVisible: Bool = false
    
    // ── Abstract loading phrases (no specifics) ──
    private let loadingPhrases = [
        "Gathering energy…",
        "Balancing the flow…",
        "Preparing your rhythm…",
        "Almost there…",
    ]
    
    // ── Timer for phrase rotation ──
    @State private var phraseTimer: Timer?
    
    var body: some View {
        ZStack {
            // ── Background from VitalFlowRoot (gold-black gradient) ──
            
            // ── Shimmer overlay ──
            AuraShimmerOverlay()
                .ignoresSafeArea()
                .opacity(0.5)
            
            // ── Floating orbs (decorative) ──
            if orbsVisible {
                floatingOrbsLayer
            }
            
            // ── Main content ──
            VStack(spacing: 0) {
                Spacer()
                
                // ── Pulsing rings + Logo ──
                ZStack {
                    if ring3Visible {
                        AuraPulsingRing(
                            color: VitalPalette.glowSoftMorning.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 200, height: 200)
                    }
                    
                    if ring2Visible {
                        AuraPulsingRing(
                            color: VitalPalette.surgeXPGold.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 150, height: 150)
                    }
                    
                    if ring1Visible {
                        AuraPulsingRing(
                            color: VitalPalette.glowZincSunrise.opacity(0.4),
                            lineWidth: 2.5
                        )
                        .frame(width: 100, height: 100)
                    }
                    
                    // ── App Logo ──
                    logoView
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                .frame(height: 220)
                
                Spacer()
                    .frame(height: 40)
                
                // ── App Title ──
                VStack(spacing: 8) {
                    Text("c10")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("Energy Route")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
                
                Spacer()
                    .frame(height: 60)
                
                // ── Loading phrase ──
                Text(loadingPhrases[phraseIndex])
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
                    .opacity(phraseOpacity)
                    .animation(.easeInOut(duration: 0.6), value: phraseIndex)
                    .id("phrase_\(phraseIndex)")
                
                Spacer()
                    .frame(height: 16)
                
                // ── Animated dots ──
                LoadingDotsView()
                    .opacity(dotsOpacity)
                
                Spacer()
                
                // ── Bottom tagline ──
                Text("Plan by energy, not by clock")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper.opacity(0.6))
                    .opacity(titleOpacity)
                    .padding(.bottom, 40)
            }
        }
        .opacity(overallOpacity)
        .onAppear(perform: startSequence)
        .onDisappear { phraseTimer?.invalidate() }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Logo
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var logoView: some View {
        ZStack {
            Circle()
                .fill(VitalPalette.chipSelectedBg)
                .frame(width: 72, height: 72)
            
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(VitalPalette.glowZincSunrise)
        }
        .shadow(color: VitalPalette.driftShadowMist, radius: 20, x: 0, y: 8)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Floating Orbs Layer
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var floatingOrbsLayer: some View {
        ZStack {
            DriftFloatingOrb(size: 60, color: VitalPalette.surgeXPGold.opacity(0.15), delay: 0)
                .position(x: 60, y: 200)
            
            DriftFloatingOrb(size: 40, color: VitalPalette.glowSoftMorning.opacity(0.2), delay: 1.5)
                .position(x: UIScreen.main.bounds.width - 80, y: 300)
            
            DriftFloatingOrb(size: 50, color: VitalPalette.bloomLevelViolet.opacity(0.1), delay: 0.8)
                .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height - 200)
            
            DriftFloatingOrb(size: 35, color: VitalPalette.glowZincSunrise.opacity(0.15), delay: 2.0)
                .position(x: 100, y: UIScreen.main.bounds.height - 300)
        }
        .allowsHitTesting(false)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Animation Sequence
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func startSequence() {
        let isReduceMotion = UIAccessibility.isReduceMotionEnabled
        
        if isReduceMotion {
            // Instant show, skip animations
            logoScale = 1.0
            logoOpacity = 1
            titleOpacity = 1
            titleOffset = 0
            phraseOpacity = 1
            dotsOpacity = 1
            ring1Visible = true
            ring2Visible = true
            ring3Visible = true
            orbsVisible = true
            
            // Still wait a moment then finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onFinished()
            }
            return
        }
        
        // ── Phase 1: Logo appears (0.0s) ──
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1
        }
        
        // ── Phase 2: Rings cascade in (0.3s) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                ring1Visible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                ring2Visible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.5)) {
                ring3Visible = true
            }
        }
        
        // ── Phase 3: Title slides up (0.6s) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.7)) {
                titleOpacity = 1
                titleOffset = 0
            }
        }
        
        // ── Phase 4: Orbs fade in (0.8s) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 1.0)) {
                orbsVisible = true
            }
        }
        
        // ── Phase 5: Loading phrase + dots (1.0s) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                phraseOpacity = 1
                dotsOpacity = 1
            }
            startPhraseRotation()
        }
        
        // ── Phase 6: Fade out and finish (2.8s) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                overallOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            onFinished()
        }
    }
    
    private func startPhraseRotation() {
        phraseTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            let nextIndex = (phraseIndex + 1) % loadingPhrases.count
            withAnimation(.easeInOut(duration: 0.3)) {
                phraseOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                phraseIndex = nextIndex
                withAnimation(.easeInOut(duration: 0.3)) {
                    phraseOpacity = 1
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ⏳ LoadingDotsView — Animated dot indicator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct LoadingDotsView: View {
    
    @State private var activeDot: Int = 0
    @State private var timer: Timer?
    
    private let dotCount = 3
    private let dotSize: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(VitalPalette.zenJetStone)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(activeDot == index ? 1.4 : 0.8)
                    .opacity(activeDot == index ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.35),
                        value: activeDot
                    )
            }
        }
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else {
                activeDot = 1
                return
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                activeDot = (activeDot + 1) % dotCount
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🎬 Splash Wrapper (manages splash → app transition)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Drop this into your @main App as the root view.
// It handles: splash → onboarding (if first launch) → main tabs.

struct AuraFlowGateway: View {
    
    @StateObject private var vault = VitalVault.shared
    
    enum FlowPhase {
        case splash
        case onboarding
        case mainApp
    }
    
    @State private var phase: FlowPhase = .splash
    
    var body: some View {
        ZStack {
            GoldBlackGradientBackground()
                .ignoresSafeArea()
            
            switch phase {
            case .splash:
                AuraSplashGateway {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        if vault.state.hasCompletedOnboarding {
                            phase = .mainApp
                        } else {
                            phase = .onboarding
                        }
                    }
                }
                .transition(.opacity)
                
            case .onboarding:
                // Placeholder — will be replaced by SparkJourneyPortal
                SparkJourneyPlaceholder {
                    vault.completeOnboarding()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phase = .mainApp
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                
            case .mainApp:
                // Placeholder — will be replaced by VitalHubShell
                VitalHubPlaceholder()
                    .transition(.opacity)
            }
        }
        .environmentObject(vault)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📦 Temporary Placeholders (replaced by real screens later)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Placeholder for onboarding — replaced by SparkJourneyPortal
struct SparkJourneyPlaceholder: View {
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            GoldBlackGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("✨ Onboarding")
                    .font(.largeTitle.bold())
                
                Text("(Will be replaced by SparkJourneyPortal)")
                    .foregroundColor(VitalPalette.zenAshWhisper)
                
                Button(action: onComplete) {
                    Text("Complete Setup")
                        .font(.headline)
                        .foregroundColor(VitalPalette.glowZincSunrise)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(VitalPalette.chipSelectedBg)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

/// Placeholder for main app — replaced by VitalHubShell
struct VitalHubPlaceholder: View {
    @EnvironmentObject var vault: VitalVault
    
    var body: some View {
        ZStack {
            GoldBlackGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("🏠 Main App")
                    .font(.largeTitle.bold())
                
                Text("(Will be replaced by VitalHubShell)")
                    .foregroundColor(VitalPalette.zenAshWhisper)
                
                Text("XP: \(vault.state.progress.totalXP)")
                    .font(.title2)
                
                Text("Level: \(vault.state.progress.currentLevel.badge) \(vault.state.progress.currentLevel.title)")
                    .font(.headline)
            }
        }
    }
}
