import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🌊 DriftGlowAtmosphere — Animated background
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// UIKit-based animated background wrapped for SwiftUI.
// Two layers:
//   1. Breathing gradient (slow color shift)
//   2. Floating particles (gentle upward drift)
//
// Respects UIAccessibility.isReduceMotionEnabled:
//   → static gradient, no particles.
//
// Usage:
//   ZStack {
//       DriftGlowAtmosphere(preset: .sunrise)
//       // ...your content
//   }

struct DriftGlowAtmosphere: UIViewRepresentable {
    
    let preset: AtmospherePreset
    
    func makeUIView(context: Context) -> DriftGlowUIView {
        let view = DriftGlowUIView(preset: preset)
        view.startAnimating()
        return view
    }
    
    func updateUIView(_ uiView: DriftGlowUIView, context: Context) {
        // Preset changes are rare; rebuild if needed
        if uiView.currentPreset != preset {
            uiView.applyPreset(preset)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🎨 Atmosphere Presets
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum AtmospherePreset: Equatable {
    case sunrise      // Tab 1 "Today" — warm yellow breathing
    case moonGarden   // Tab 2 "Days" — cool lavender drift
    case zenStone     // Tab 3 "Settings" — neutral grey calm
    case sparkField   // Tab 3 "Insights" — soft peach glow
    case auraGateway  // Splash / Onboarding — golden shimmer
    
    var primaryColors: [UIColor] {
        switch self {
        case .sunrise:
            return [
                UIColor(red: 0.961, green: 0.859, blue: 0.263, alpha: 1.0),  // glowZincSunrise
                UIColor(red: 0.973, green: 0.918, blue: 0.557, alpha: 1.0),  // glowSoftMorning
                UIColor(red: 0.980, green: 0.941, blue: 0.710, alpha: 1.0),  // glowWarmDawn
            ]
        case .moonGarden:
            return [
                UIColor(red: 0.910, green: 0.918, blue: 0.922, alpha: 1.0),  // driftFogVeil
                UIColor(red: 0.812, green: 0.796, blue: 0.878, alpha: 1.0),  // rhythmEveningDusk
                UIColor(red: 0.910, green: 0.918, blue: 0.922, alpha: 1.0),  // driftFogVeil
            ]
        case .zenStone:
            return [
                UIColor(red: 0.957, green: 0.961, blue: 0.965, alpha: 1.0),  // driftSnowField
                UIColor(red: 0.910, green: 0.918, blue: 0.922, alpha: 1.0),  // driftFogVeil
                UIColor(red: 0.957, green: 0.961, blue: 0.965, alpha: 1.0),  // driftSnowField
            ]
        case .sparkField:
            return [
                UIColor(red: 0.980, green: 0.941, blue: 0.710, alpha: 1.0),  // glowWarmDawn
                UIColor(red: 0.945, green: 0.835, blue: 0.725, alpha: 1.0),  // rhythmMorningPeach
                UIColor(red: 0.980, green: 0.941, blue: 0.710, alpha: 1.0),  // glowWarmDawn
            ]
        case .auraGateway:
            return [
                UIColor(red: 0.961, green: 0.859, blue: 0.263, alpha: 1.0),  // glowZincSunrise
                UIColor(red: 0.855, green: 0.729, blue: 0.235, alpha: 1.0),  // surgeXPGold
                UIColor(red: 0.973, green: 0.918, blue: 0.557, alpha: 1.0),  // glowSoftMorning
            ]
        }
    }
    
    var secondaryColors: [UIColor] {
        switch self {
        case .sunrise:
            return [
                UIColor(red: 0.980, green: 0.941, blue: 0.710, alpha: 1.0),
                UIColor(red: 0.961, green: 0.859, blue: 0.263, alpha: 1.0),
                UIColor(red: 0.973, green: 0.918, blue: 0.557, alpha: 1.0),
            ]
        case .moonGarden:
            return [
                UIColor(red: 0.812, green: 0.796, blue: 0.878, alpha: 1.0),
                UIColor(red: 0.957, green: 0.961, blue: 0.965, alpha: 1.0),
                UIColor(red: 0.812, green: 0.796, blue: 0.878, alpha: 1.0),
            ]
        case .zenStone:
            return [
                UIColor(red: 0.910, green: 0.918, blue: 0.922, alpha: 1.0),
                UIColor(red: 0.957, green: 0.961, blue: 0.965, alpha: 1.0),
                UIColor(red: 0.749, green: 0.761, blue: 0.765, alpha: 0.3),
            ]
        case .sparkField:
            return [
                UIColor(red: 0.945, green: 0.835, blue: 0.725, alpha: 1.0),
                UIColor(red: 0.980, green: 0.941, blue: 0.710, alpha: 1.0),
                UIColor(red: 0.945, green: 0.835, blue: 0.725, alpha: 1.0),
            ]
        case .auraGateway:
            return [
                UIColor(red: 0.973, green: 0.918, blue: 0.557, alpha: 1.0),
                UIColor(red: 0.961, green: 0.859, blue: 0.263, alpha: 1.0),
                UIColor(red: 0.855, green: 0.729, blue: 0.235, alpha: 1.0),
            ]
        }
    }
    
    var particleColor: UIColor {
        switch self {
        case .sunrise:     return UIColor.white.withAlphaComponent(0.25)
        case .moonGarden:  return UIColor(red: 0.533, green: 0.420, blue: 0.620, alpha: 0.15)
        case .zenStone:    return UIColor.black.withAlphaComponent(0.04)
        case .sparkField:  return UIColor.white.withAlphaComponent(0.3)
        case .auraGateway: return UIColor.white.withAlphaComponent(0.35)
        }
    }
    
    var breathDuration: CFTimeInterval {
        switch self {
        case .auraGateway: return 4.0
        default:           return 8.0
        }
    }
    
    var particleCount: Int {
        switch self {
        case .zenStone:    return 6
        case .auraGateway: return 15
        default:           return 10
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🖼 DriftGlowUIView — The UIKit implementation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class DriftGlowUIView: UIView {
    
    private(set) var currentPreset: AtmospherePreset
    
    // Layers
    private let gradientLayer = CAGradientLayer()
    private let particleContainer = UIView()
    private var particleLayers: [CAShapeLayer] = []
    private var displayLink: CADisplayLink?
    
    // State
    private var isAnimating = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled
    
    // ── Init ──
    
    init(preset: AtmospherePreset) {
        self.currentPreset = preset
        super.init(frame: .zero)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        self.currentPreset = .sunrise
        super.init(coder: coder)
        setupLayers()
    }
    
    // ── Setup ──
    
    private func setupLayers() {
        // Gradient
        gradientLayer.type = .axial
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.colors = currentPreset.primaryColors.map(\.cgColor)
        layer.insertSublayer(gradientLayer, at: 0)
        
        // Particle container
        particleContainer.isUserInteractionEnabled = false
        particleContainer.clipsToBounds = true
        addSubview(particleContainer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        particleContainer.frame = bounds
        
        // Recreate particles on layout change
        if isAnimating && !reduceMotion {
            rebuildParticles()
        }
    }
    
    // ── Public ──
    
    func applyPreset(_ preset: AtmospherePreset) {
        guard preset != currentPreset else { return }
        currentPreset = preset
        
        // Smooth color transition
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = preset.primaryColors.map(\.cgColor)
        animation.duration = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.colors = preset.primaryColors.map(\.cgColor)
        gradientLayer.add(animation, forKey: "presetTransition")
        
        if !reduceMotion {
            rebuildParticles()
        }
    }
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        if reduceMotion {
            // Static gradient only
            gradientLayer.colors = currentPreset.primaryColors.map(\.cgColor)
            return
        }
        
        startBreathingGradient()
        rebuildParticles()
    }
    
    func stopAnimating() {
        isAnimating = false
        gradientLayer.removeAllAnimations()
        clearParticles()
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Breathing Gradient
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func startBreathingGradient() {
        let colorAnim = CABasicAnimation(keyPath: "colors")
        colorAnim.fromValue = currentPreset.primaryColors.map(\.cgColor)
        colorAnim.toValue = currentPreset.secondaryColors.map(\.cgColor)
        colorAnim.duration = currentPreset.breathDuration
        colorAnim.autoreverses = true
        colorAnim.repeatCount = .infinity
        colorAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(colorAnim, forKey: "breathe")
        
        // Subtle diagonal drift
        let startAnim = CABasicAnimation(keyPath: "startPoint")
        startAnim.fromValue = CGPoint(x: 0, y: 0)
        startAnim.toValue = CGPoint(x: 0.15, y: 0.1)
        startAnim.duration = currentPreset.breathDuration * 1.3
        startAnim.autoreverses = true
        startAnim.repeatCount = .infinity
        startAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(startAnim, forKey: "startDrift")
        
        let endAnim = CABasicAnimation(keyPath: "endPoint")
        endAnim.fromValue = CGPoint(x: 1, y: 1)
        endAnim.toValue = CGPoint(x: 0.85, y: 0.9)
        endAnim.duration = currentPreset.breathDuration * 1.3
        endAnim.autoreverses = true
        endAnim.repeatCount = .infinity
        endAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(endAnim, forKey: "endDrift")
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Floating Particles
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func rebuildParticles() {
        clearParticles()
        
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let count = currentPreset.particleCount
        
        for i in 0..<count {
            let particle = createParticleLayer(index: i, total: count)
            particleContainer.layer.addSublayer(particle)
            particleLayers.append(particle)
            animateParticle(particle, index: i, total: count)
        }
    }
    
    private func clearParticles() {
        for p in particleLayers {
            p.removeAllAnimations()
            p.removeFromSuperlayer()
        }
        particleLayers.removeAll()
    }
    
    private func createParticleLayer(index: Int, total: Int) -> CAShapeLayer {
        let layer = CAShapeLayer()
        
        // Random size between 3-8 points
        let size = CGFloat.random(in: 3...8)
        let x = CGFloat.random(in: 0...bounds.width)
        let y = CGFloat.random(in: 0...bounds.height)
        
        let path = UIBezierPath(
            ovalIn: CGRect(x: 0, y: 0, width: size, height: size)
        )
        layer.path = path.cgPath
        layer.fillColor = currentPreset.particleColor.cgColor
        layer.position = CGPoint(x: x, y: y)
        layer.opacity = Float.random(in: 0.3...0.7)
        
        return layer
    }
    
    private func animateParticle(_ particle: CAShapeLayer, index: Int, total: Int) {
        let duration = CFTimeInterval.random(in: 12...25)
        let delay = CFTimeInterval(index) * 0.8
        
        // ── Vertical float (upward drift) ──
        let yTravel = CGFloat.random(in: 40...120)
        let posAnim = CABasicAnimation(keyPath: "position.y")
        posAnim.fromValue = particle.position.y
        posAnim.toValue = particle.position.y - yTravel
        posAnim.duration = duration
        posAnim.autoreverses = true
        posAnim.repeatCount = .infinity
        posAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        posAnim.beginTime = CACurrentMediaTime() + delay
        
        // ── Horizontal sway ──
        let xSway = CGFloat.random(in: 10...30)
        let xAnim = CABasicAnimation(keyPath: "position.x")
        xAnim.fromValue = particle.position.x
        xAnim.toValue = particle.position.x + (Bool.random() ? xSway : -xSway)
        xAnim.duration = duration * 0.7
        xAnim.autoreverses = true
        xAnim.repeatCount = .infinity
        xAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        xAnim.beginTime = CACurrentMediaTime() + delay
        
        // ── Pulse opacity ──
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = particle.opacity
        opacityAnim.toValue = max(0.1, particle.opacity - 0.3)
        opacityAnim.duration = duration * 0.5
        opacityAnim.autoreverses = true
        opacityAnim.repeatCount = .infinity
        opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        opacityAnim.beginTime = CACurrentMediaTime() + delay
        
        particle.add(posAnim, forKey: "floatY_\(index)")
        particle.add(xAnim, forKey: "swayX_\(index)")
        particle.add(opacityAnim, forKey: "pulse_\(index)")
    }
    
    // ── Cleanup ──
    
    deinit {
        stopAnimating()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🎁 SwiftUI Convenience Modifier
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    
    /// Apply animated background atmosphere behind content
    ///
    /// Usage:
    /// ```
    /// ScrollView { ... }
    ///     .vitalAtmosphere(.sunrise)
    /// ```
    func vitalAtmosphere(_ preset: AtmospherePreset) -> some View {
        self.background(
            DriftGlowAtmosphere(preset: preset)
                .ignoresSafeArea()
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ✨ Shimmer Effect Layer (for splash / level-up)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AuraShimmerOverlay: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = false
        container.backgroundColor = .clear
        
        guard !UIAccessibility.isReduceMotionEnabled else { return container }
        
        let shimmer = CAGradientLayer()
        shimmer.colors = [
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.15).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor,
        ]
        shimmer.locations = [0.0, 0.5, 1.0]
        shimmer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmer.frame = CGRect(x: -300, y: 0, width: 300, height: 2000)
        
        let anim = CABasicAnimation(keyPath: "position.x")
        anim.fromValue = -150
        anim.toValue = UIScreen.main.bounds.width + 150
        anim.duration = 3.0
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmer.add(anim, forKey: "shimmerSlide")
        
        container.layer.addSublayer(shimmer)
        container.layer.masksToBounds = true
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🫧 Pulsing Ring View (for splash logo)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AuraPulsingRing: View {
    
    let color: Color
    let lineWidth: CGFloat
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: lineWidth)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                guard !UIAccessibility.isReduceMotionEnabled else {
                    scale = 1.0
                    opacity = 0.3
                    return
                }
                withAnimation(
                    .easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.15
                    opacity = 0.15
                }
            }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🔵 Floating Orb (decorative element)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct DriftFloatingOrb: View {
    
    let size: CGFloat
    let color: Color
    let delay: Double
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var orbOpacity: Double = 0.5
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.3)
            .offset(x: offsetX, y: offsetY)
            .opacity(orbOpacity)
            .onAppear {
                guard !UIAccessibility.isReduceMotionEnabled else { return }
                withAnimation(
                    .easeInOut(duration: Double.random(in: 6...10))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    offsetY = CGFloat.random(in: -30...30)
                    offsetX = CGFloat.random(in: -15...15)
                    orbOpacity = Double.random(in: 0.2...0.5)
                }
            }
    }
}
