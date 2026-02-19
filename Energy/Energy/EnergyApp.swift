import SwiftUI
import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🔒 Portrait Lock (first release)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private final class PortraitLockDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🚀 c10App — Main entry point
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Flow: Splash → Onboarding (first launch) → Main Tabs
// All state lives in VitalVault (singleton, JSON persistence).

@main
struct TempoMapEnergyRouteApp: App {
    
    @UIApplicationDelegateAdaptor(PortraitLockDelegate.self) private var portraitLock
    @StateObject private var vault = VitalVault.shared
    
    var body: some Scene {
        WindowGroup {
            VitalFlowRoot()
                .environmentObject(vault)
                .preferredColorScheme(.dark)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🌊 VitalFlowRoot — Splash → Onboarding → Tabs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct VitalFlowRoot: View {
    
    @EnvironmentObject var vault: VitalVault
    
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
                
                SparkJourneyPortal {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phase = .mainApp
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                
            case .mainApp:
                VitalHubShell()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
    }
}
