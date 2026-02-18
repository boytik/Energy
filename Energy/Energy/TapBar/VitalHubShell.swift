import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🏠 VitalHubShell — Main tab container
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 4 tabs:
//   Tab 1: "Today"    — PulseFlowTodayCanvas (energy day planner)
//   Tab 2: "Days"     — BloomJournalGallery (history / calendar)
//   Tab 3: "Insights" — VitalInsightsCanvas (stats + energy tips)
//   Tab 4: "Profile"  — ZenRootGarden (settings / stats / identity)

struct VitalHubShell: View {
    
    @EnvironmentObject var vault: VitalVault
    @State private var selectedTab: HubTab = .today
    @State private var showLevelUpBanner = false
    @State private var previousLevel: Int = 1
    
    var body: some View {
        ZStack(alignment: .top) {
            GoldBlackGradientBackground()
                .ignoresSafeArea()
            
            // ── Standard TabView with native tab bar ──
            TabView(selection: $selectedTab) {
                PulseFlowTodayCanvas()
                    .tag(HubTab.today)
                    .tabItem {
                        Label("Today", systemImage: "bolt.heart")
                    }
                
                BloomJournalGallery()
                    .tag(HubTab.days)
                    .tabItem {
                        Label("Days", systemImage: "calendar.circle")
                    }
                
                VitalInsightsCanvas()
                    .tag(HubTab.insights)
                    .tabItem {
                        Label("Insights", systemImage: "lightbulb.circle")
                    }
                
                ZenRootGarden()
                    .tag(HubTab.profile)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
            }
            .tabViewStyle(.automatic)
            
            // ── Level-up celebration banner ──
            if showLevelUpBanner {
                levelUpOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .onChange(of: vault.state.progress.totalXP) { newXP in
            checkLevelUp(newXP: newXP)
        }
        .onAppear {
            configureTabBarAppearance()
            previousLevel = vault.state.progress.currentLevel.level
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Level Up Overlay
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var levelUpOverlay: some View {
        VStack(spacing: 8) {
            let level = vault.state.progress.currentLevel
            
            HStack(spacing: 10) {
                Text(level.badge)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Level Up!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("You're now \(level.title)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showLevelUpBanner = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(VitalPalette.zenSilentStone)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(VitalPalette.driftFogVeil)
                    .shadow(color: VitalPalette.surgeXPGold.opacity(0.3), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(VitalPalette.surgeXPGold.opacity(0.4), lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showLevelUpBanner = false
                }
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Level Up Detection
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func checkLevelUp(newXP: Int) {
        let newLevel = VitalityLevel.levelFor(xp: newXP).level
        if newLevel > previousLevel {
            previousLevel = newLevel
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showLevelUpBanner = true
            }
            // Celebration haptic
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Tab Bar Appearance
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func configureTabBarAppearance() {
        let selectedColor = UIColor(red: 0.855, green: 0.729, blue: 0.235, alpha: 1.0) // surgeXPGold
        
        let appearance = UITabBarAppearance()
        if #available(iOS 26.0, *) {
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // dark surface
        }
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0)]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0)
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0)]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0)
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0)]
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = selectedColor
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📑 HubTab — Tab definitions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum HubTab: Int, CaseIterable, Identifiable {
    case today   = 0
    case days    = 1
    case insights = 2
    case profile = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .today:   return "Today"
        case .days:    return "Days"
        case .insights: return "Insights"
        case .profile: return "Profile"
        }
    }
    
    func icon(isSelected: Bool) -> String {
        switch self {
        case .today:   return isSelected ? "bolt.heart.fill"          : "bolt.heart"
        case .days:    return isSelected ? "calendar.circle.fill"     : "calendar.circle"
        case .insights: return isSelected ? "lightbulb.circle.fill"  : "lightbulb.circle"
        case .profile: return isSelected ? "person.crop.circle.fill"  : "person.crop.circle"
        }
    }
}

