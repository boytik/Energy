import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ✨ SparkJourneyPortal — Onboarding View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 4-step animated onboarding:
//   Step 0: Welcome — 3 feature cards with staggered entrance
//   Step 1: Choose Tempo — segmented picker + budget preview
//   Step 2: Pick Starters — template grid with selection
//   Step 3: All Set — summary + create day button
//
// ViewModel: SparkJourneyMind.swift

struct SparkJourneyPortal: View {
    
    @StateObject private var mind = SparkJourneyMind()
    @EnvironmentObject var vault: VitalVault
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // ── Animated Background ──
            DriftGlowAtmosphere(preset: .auraGateway)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ── Progress Bar ──
                journeyProgressBar
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                
                // ── Step Content ──
                TabView(selection: $mind.currentStep) {
                    stepWelcome.tag(0)
                    stepChooseTempo.tag(1)
                    stepPickStarters.tag(2)
                    stepAllSet.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: mind.currentStep)
                
                // ── Bottom Navigation ──
                bottomNavigation
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Progress Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var journeyProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(VitalPalette.zenJetStone.opacity(0.1))
                    .frame(height: 4)
                
                // Fill
                Capsule()
                    .fill(VitalPalette.zenJetStone)
                    .frame(
                        width: geo.size.width * mind.progressFraction,
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.4), value: mind.currentStep)
            }
        }
        .frame(height: 4)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Step 0: Welcome
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var stepWelcome: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer().frame(height: 30)
                
                // Logo
                ZStack {
                    AuraPulsingRing(
                        color: VitalPalette.surgeXPGold.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                    
                    ZStack {
                        Circle()
                            .fill(VitalPalette.zenJetStone)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 28))
                            .foregroundColor(VitalPalette.glowZincSunrise)
                    }
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("Welcome to c10")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("Your Energy Route planner")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                
                // Feature cards
                VStack(spacing: 16) {
                    ForEach(Array(mind.welcomeFeatures.enumerated()), id: \.element.id) { index, feature in
                        WelcomeFeatureCard(
                            feature: feature,
                            delay: Double(index) * 0.15
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Step 1: Choose Tempo
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var stepChooseTempo: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer().frame(height: 30)
                
                // Header
                VStack(spacing: 8) {
                    Text("Choose Your Tempo")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("How packed should your day feel?")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
                
                // Rhythm selector cards
                VStack(spacing: 12) {
                    ForEach(EnergyRhythm.allCases) { rhythm in
                        RhythmOptionCard(
                            rhythm: rhythm,
                            isSelected: mind.selectedRhythm == rhythm,
                            onTap: { mind.selectRhythm(rhythm) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Buffer config
                VStack(spacing: 16) {
                    Text("Buffer Between Spots")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                    
                    // Buffer picker
                    HStack(spacing: 10) {
                        ForEach(mind.bufferOptions, id: \.self) { mins in
                            ChipButton(
                                title: "\(mins) min",
                                isSelected: mind.selectedBufferMin == mins,
                                action: { mind.selectedBufferMin = mins }
                            )
                        }
                    }
                    
                    // Overhead example
                    Text(mind.overheadExample)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: mind.selectedBufferMin)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(VitalPalette.driftSnowField.opacity(0.7))
                )
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Step 2: Pick Starter Spots
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var stepPickStarters: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 30)
                
                // Header
                VStack(spacing: 8) {
                    Text("Pick Your Starters")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("Choose 2 or more to build your first day")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
                
                // Counter
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(
                            mind.canProceedFromStarters
                            ? VitalPalette.pulseComfortSage
                            : VitalPalette.zenSilentStone
                        )
                    Text("\(mind.starterPickCount) selected")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                .animation(.easeInOut(duration: 0.2), value: mind.starterPickCount)
                
                // Template grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    ForEach(mind.availableTemplates) { template in
                        TemplatePickCard(
                            template: template,
                            isSelected: mind.isTemplateSelected(template),
                            onTap: { mind.toggleTemplate(template) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Step 3: All Set
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var stepAllSet: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer().frame(height: 40)
                
                // Celebration
                ZStack {
                    AuraPulsingRing(
                        color: VitalPalette.surgeXPGold.opacity(0.3),
                        lineWidth: 2.5
                    )
                    .frame(width: 140, height: 140)
                    
                    Text("🎉")
                        .font(.system(size: 56))
                }
                
                VStack(spacing: 8) {
                    Text("You're All Set!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("Here's your first Energy Route")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
                
                // Summary card
                VStack(spacing: 16) {
                    SummaryRow(
                        icon: mind.summary.rhythmIcon,
                        label: "Tempo",
                        value: mind.summary.rhythmTitle
                    )
                    
                    Divider().opacity(0.3)
                    
                    SummaryRow(
                        icon: "clock.fill",
                        label: "Energy Budget",
                        value: mind.summary.budgetText
                    )
                    
                    Divider().opacity(0.3)
                    
                    SummaryRow(
                        icon: "mappin.circle.fill",
                        label: "Starter Spots",
                        value: "\(mind.summary.spotCount)"
                    )
                    
                    Divider().opacity(0.3)
                    
                    SummaryRow(
                        icon: "timer",
                        label: "Buffer",
                        value: "\(mind.summary.bufferMin) min"
                    )
                    
                    // Spot names
                    if !mind.summary.spotNames.isEmpty {
                        Divider().opacity(0.3)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(mind.summary.spotNames, id: \.self) { name in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(VitalPalette.zenJetStone)
                                        .frame(width: 6, height: 6)
                                    Text(name)
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(VitalPalette.driftSnowField.opacity(0.8))
                )
                .padding(.horizontal, 24)
                
                // XP Preview
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(VitalPalette.surgeXPGold)
                    Text("+\(SurgeXPReward.completeOnboarding + SurgeXPReward.createDayPlan) XP for completing setup!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(VitalPalette.driftSnowField.opacity(0.9))
                )
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Bottom Navigation
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var bottomNavigation: some View {
        HStack {
            // Back button
            if mind.canGoBack {
                Button(action: mind.goBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                .transition(.opacity)
            }
            
            Spacer()
            
            // Step indicator dots
            HStack(spacing: 6) {
                ForEach(0..<mind.totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step == mind.currentStep
                              ? VitalPalette.zenJetStone
                              : VitalPalette.zenJetStone.opacity(0.2))
                        .frame(width: step == mind.currentStep ? 8 : 6,
                               height: step == mind.currentStep ? 8 : 6)
                        .animation(.easeInOut(duration: 0.25), value: mind.currentStep)
                }
            }
            
            Spacer()
            
            // Next / Finish button
            Button(action: handleNext) {
                Text(mind.nextButtonTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(
                        mind.canGoNext
                        ? VitalPalette.glowZincSunrise
                        : VitalPalette.zenSilentStone
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(
                            mind.canGoNext
                            ? VitalPalette.zenJetStone
                            : VitalPalette.zenJetStone.opacity(0.3)
                        )
                    )
            }
            .disabled(!mind.canGoNext)
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.25), value: mind.currentStep)
    }
    
    private func handleNext() {
        if mind.isLastStep {
            mind.finishOnboarding(vault: vault)
            // Defer transition until commit's async state update has run (same run loop)
            DispatchQueue.main.async {
                onComplete()
            }
        } else {
            mind.goNext()
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🃏 WelcomeFeatureCard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct WelcomeFeatureCard: View {
    let feature: SparkJourneyMind.WelcomeFeature
    let delay: Double
    
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(VitalPalette.zenJetStone)
                    .frame(width: 44, height: 44)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(VitalPalette.glowZincSunrise)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                Text(feature.subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(VitalPalette.driftSnowField.opacity(0.75))
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                appeared = true
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🎛 RhythmOptionCard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct RhythmOptionCard: View {
    let rhythm: EnergyRhythm
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? VitalPalette.zenJetStone : VitalPalette.driftCloudLayer)
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: rhythm.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? VitalPalette.glowZincSunrise : VitalPalette.zenCharcoalDepth)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(rhythm.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("\(rhythm.defaultBudgetMinutes / 60)h budget • up to \(rhythm.recommendedSpotCount) spots")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
                
                Spacer()
                
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? VitalPalette.zenJetStone : VitalPalette.driftCloudLayer)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(VitalPalette.driftSnowField.opacity(isSelected ? 0.9 : 0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? VitalPalette.zenJetStone : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🏷 TemplatePickCard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct TemplatePickCard: View {
    let template: SparkTemplateSeed
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? VitalPalette.zenJetStone : VitalPalette.driftFogVeil)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: template.iconName ?? template.kind.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(
                            isSelected ? VitalPalette.glowZincSunrise : VitalPalette.zenCharcoalDepth
                        )
                }
                
                Text(template.title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(template.defaultDurationMin) min")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(VitalPalette.driftSnowField.opacity(isSelected ? 0.95 : 0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? VitalPalette.zenJetStone : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 💊 ChipButton (reusable)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? VitalPalette.glowZincSunrise : VitalPalette.zenCharcoalDepth)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? VitalPalette.zenJetStone : VitalPalette.driftFogVeil)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📊 SummaryRow (reusable)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
        }
    }
}
