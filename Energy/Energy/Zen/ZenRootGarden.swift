import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ⚙️ ZenRootGarden — Profile & Settings View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Features (5 key actions):
//   1. Avatar emoji picker + display name edit
//   2. XP/Level/Streak gamification display
//   3. Statistics overview (comfort rate, totals)
//   4. Config editor (rhythm, buffers, thresholds)
//   5. Export data / Share stats / Reset all
//
// ViewModel: ZenRootMind.swift

struct ZenRootGarden: View {
    
    @EnvironmentObject var vault: VitalVault
    @StateObject private var mind = ZenRootMind()
    @State private var isSpotTemplatesExpanded = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GoldBlackGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // ── Identity Card ──
                        identityCard
                            .padding(.horizontal, 20)
                        
                        // ── XP & Level ──
                        gamificationCard
                            .padding(.horizontal, 20)
                        
                        // ── Statistics ──
                        statsCard
                            .padding(.horizontal, 20)
                        
                        // ── Quick Add Spots (templates for Add Spot) ──
                        spotTemplatesCard
                            .padding(.horizontal, 20)
                        
                        // ── Settings ──
                        settingsCard
                            .padding(.horizontal, 20)
                        
                        // ── Data Management ──
                        dataCard
                            .padding(.horizontal, 20)
                        
                        // App info
                        appInfoFooter
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $mind.showAvatarPicker) {
                ZenAvatarPickerSheet(mind: mind)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $mind.showConfigEditor) {
                ZenConfigEditorSheet(mind: mind)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $mind.showTemplateEditor) {
                TemplateEditorSheet(mind: mind, template: mind.templateToEdit)
                    .presentationDetents([.medium, .large])
                    .onDisappear { mind.templateToEdit = nil }
            }
            .sheet(isPresented: $mind.showExportShare) {
                if let data = mind.exportData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(isPresented: $mind.showStatsShare) {
                ShareSheet(items: [mind.shareStatsText])
            }
            .alert("Reset All Data?", isPresented: $mind.showResetConfirmation) {
                Button("Reset Everything", role: .destructive) { mind.resetAllData() }
                Button("Cancel", role: .cancel) { }
            }             message: {
                Text("This will permanently delete all your day plans and progress. This cannot be undone.")
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Identity Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var identityCard: some View {
        VStack(spacing: 16) {
            // Avatar
            Button { mind.showAvatarPicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    Text(mind.identity.avatarEmoji)
                        .font(.system(size: 64))
                        .frame(width: 90, height: 90)
                        .background(
                            Circle().fill(VitalPalette.driftFogVeil)
                        )
                    
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(VitalPalette.zenJetStone)
                        .background(Circle().fill(VitalPalette.driftSnowField).padding(-2))
                }
            }
            
            // Name
            if mind.editingName {
                HStack(spacing: 10) {
                    TextField("Your name", text: $mind.nameField)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(VitalPalette.driftFogVeil)
                        )
                        .frame(maxWidth: 200)
                    
                    Button { mind.saveName() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(VitalPalette.zenJetStone)
                    }
                }
            } else {
                Button { mind.startEditingName() } label: {
                    HStack(spacing: 6) {
                        Text(mind.identity.displayName.isEmpty ? "Tap to set name" : mind.identity.displayName)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                mind.identity.displayName.isEmpty
                                ? VitalPalette.zenSilentStone
                                : VitalPalette.zenJetStone
                            )
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(VitalPalette.zenSilentStone)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Gamification Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var gamificationCard: some View {
        VStack(spacing: 16) {
            // Level badge
            HStack(spacing: 14) {
                Text(mind.currentLevel.badge)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mind.currentLevel.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    Text("Level \(mind.currentLevel.level)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(mind.xpDisplayText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.surgeXPGold)
                    
                    if let streak = mind.streakText {
                        Text(streak)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(VitalPalette.surgeStreakEmber)
                    }
                }
            }
            
            // XP progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(VitalPalette.driftFogVeil)
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [VitalPalette.surgeXPGold, VitalPalette.bloomLevelViolet],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * mind.progressToNext, height: 10)
                            .animation(.easeInOut(duration: 0.5), value: mind.progressToNext)
                    }
                }
                .frame(height: 10)
                
                Text(mind.nextLevelInfo)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            
            // Quick stats row
            HStack(spacing: 0) {
                miniStat(label: "Streak", value: "\(mind.progress.currentStreak)", icon: "flame.fill", color: VitalPalette.surgeStreakEmber)
                
                Divider().frame(height: 30)
                
                miniStat(label: "Longest", value: mind.longestStreakText, icon: "trophy.fill", color: VitalPalette.surgeXPGold)
                
                Divider().frame(height: 30)
                
                miniStat(label: "Milestones", value: "\(mind.milestoneCount)", icon: "star.fill", color: VitalPalette.bloomLevelViolet)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func miniStat(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
        }
        .frame(maxWidth: .infinity)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Statistics Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var statsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                Spacer()
                
                // Share button
                Button { mind.showStatsShare = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(VitalPalette.driftFogVeil))
                }
            }
            
            // Comfort rate highlight
            if mind.stats.totalDaysPlanned > 0 {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(VitalPalette.driftFogVeil, lineWidth: 6)
                            .frame(width: 56, height: 56)
                        
                        Circle()
                            .trim(from: 0, to: mind.stats.comfortRate)
                            .stroke(VitalPalette.pulseComfortSage, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.6), value: mind.stats.comfortRate)
                        
                        Text("\(mind.comfortRatePercent)%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(VitalPalette.zenJetStone)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comfort Rate")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(VitalPalette.zenJetStone)
                        Text("Days within energy budget")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(VitalPalette.zenAshWhisper)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(VitalPalette.pulseComfortSage.opacity(0.08))
                )
            }
            
            // Stat rows
            ForEach(mind.statsRows) { row in
                HStack(spacing: 10) {
                    Image(systemName: row.icon)
                        .font(.system(size: 14))
                        .foregroundColor(row.color)
                        .frame(width: 22)
                    
                    Text(row.label)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                    
                    Spacer()
                    
                    Text(row.value)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Spot Templates Card (Quick Add)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var spotTemplatesCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Quick Add Spots")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                Spacer()
                Button {
                    mind.startAddTemplate()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.surgeXPGold)
                }
            }
            
            Text("Templates shown in Add Spot sheet")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            
            if mind.templates.isEmpty {
                Text("No templates yet. Tap Add to create one.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(VitalPalette.zenSilentStone)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(mind.templates.prefix(isSpotTemplatesExpanded ? mind.templates.count : 4))) { template in
                        templateRow(template)
                    }
                    if mind.templates.count > 4 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSpotTemplatesExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSpotTemplatesExpanded ? "Show less" : "Show more (\(mind.templates.count - 4))")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                Image(systemName: isSpotTemplatesExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(VitalPalette.surgeXPGold)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func templateRow(_ template: SparkTemplateSeed) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(template.kind.tintColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                Image(systemName: template.iconName ?? template.kind.icon)
                    .font(.system(size: 18))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(template.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                Text("\(template.defaultDurationMin) min • \(template.kind.title)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            
            Spacer()
            
            Button {
                mind.toggleTemplatePin(template)
            } label: {
                Image(systemName: template.isPinned ? "pin.fill" : "pin.slash")
                    .font(.system(size: 16))
                    .foregroundColor(template.isPinned ? VitalPalette.surgeXPGold : VitalPalette.zenSilentStone)
            }
            
            Button {
                mind.startEditTemplate(template)
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 20))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
            }
            
            Button {
                mind.deleteTemplate(id: template.id)
            } label: {
                Image(systemName: "trash.circle")
                    .font(.system(size: 20))
                    .foregroundColor(VitalPalette.pulseOverloadRust)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VitalPalette.driftFogVeil.opacity(0.8))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Settings Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var settingsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Settings")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                Spacer()
            }
            
            // Current defaults
            settingsRow(icon: "bolt.heart", label: "Default Tempo", value: mind.config.defaultRhythm.title)
            settingsRow(icon: "timer", label: "Default Buffer", value: "\(mind.config.defaultBufferBetweenMin) min")
            settingsRow(icon: "car", label: "Default Travel", value: "\(mind.config.defaultTravelMin) min")
            settingsRow(icon: "exclamationmark.triangle", label: "Tight Threshold", value: "+\(mind.config.tightThresholdMin) min")
            settingsRow(icon: "xmark.octagon", label: "Overload Threshold", value: "+\(mind.config.overloadThresholdMin) min")
            
            // Edit button
            Button { mind.showConfigEditor = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Edit Settings")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(VitalPalette.driftFogVeil)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    private func settingsRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
                .frame(width: 22)
            
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
        }
        .padding(.vertical, 2)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Data Management Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var dataCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Data")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                Spacer()
                
                Text(mind.fileSizeText)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            
            // Export
            Button { mind.exportJSON() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export All Data (JSON)")
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(VitalPalette.driftFogVeil)
                )
            }
            
            // Reset
            Button { mind.showResetConfirmation = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Reset All Data")
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.pulseOverloadRust)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(VitalPalette.pulseOverloadRust.opacity(0.08))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 6, x: 0, y: 3)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – App Info Footer
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var appInfoFooter: some View {
        VStack(spacing: 6) {
            Text("c10 — Energy Route")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            
            Text("Plan by energy, not by clock")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(VitalPalette.zenSilentStone)
            
            Text("v1.0")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(VitalPalette.zenSilentStone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🎭 ZenAvatarPickerSheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ZenAvatarPickerSheet: View {
    @ObservedObject var mind: ZenRootMind
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current avatar
                Text(mind.identity.avatarEmoji)
                    .font(.system(size: 72))
                
                // Categories
                ForEach(GlowIdentityCard.avatarCategories) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(category.emojis, id: \.self) { emoji in
                                Button {
                                    mind.selectAvatar(emoji)
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .padding(4)
                                        .background(
                                            Circle().fill(
                                                mind.identity.avatarEmoji == emoji
                                                ? VitalPalette.driftFogVeil
                                                : Color.clear
                                            )
                                        )
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🎛 ZenConfigEditorSheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ZenConfigEditorSheet: View {
    @ObservedObject var mind: ZenRootMind
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Default Rhythm
                    configSection(icon: "bolt.heart.fill", title: "Default Tempo") {
                        ForEach(EnergyRhythm.allCases) { rhythm in
                            Button {
                                mind.updateDefaultRhythm(rhythm)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: rhythm.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(VitalPalette.surgeXPGold)
                                        .frame(width: 28, alignment: .center)
                                    Text(rhythm.title)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(VitalPalette.zenJetStone)
                                    Spacer()
                                    Text("\(rhythm.defaultBudgetMinutes / 60)h")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(VitalPalette.zenAshWhisper)
                                    Image(systemName: mind.config.defaultRhythm == rhythm
                                          ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(mind.config.defaultRhythm == rhythm
                                            ? VitalPalette.zenJetStone : VitalPalette.zenSilentStone)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(mind.config.defaultRhythm == rhythm
                                              ? VitalPalette.driftFogVeil : VitalPalette.driftSnowField.opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // Buffer
                    configStepperSection(
                        icon: "timer",
                        title: "Default Buffer",
                        value: mind.config.defaultBufferBetweenMin,
                        unit: "min",
                        subtitle: "Time gap between consecutive spots",
                        range: 0...30,
                        step: 5
                    ) { mind.updateDefaultBuffer($0) }
                    
                    // Travel
                    configStepperSection(
                        icon: "car.fill",
                        title: "Default Travel",
                        value: mind.config.defaultTravelMin,
                        unit: "min",
                        subtitle: "Travel time before each spot",
                        range: 0...60,
                        step: 5
                    ) { mind.updateDefaultTravel($0) }
                    
                    Divider()
                    
                    // Tight Threshold
                    configStepperSection(
                        icon: "exclamationmark.triangle.fill",
                        title: "Tight Threshold",
                        value: mind.config.tightThresholdMin,
                        unit: "min",
                        prefix: "+",
                        subtitle: "Over budget before yellow warning",
                        range: 0...30,
                        step: 5
                    ) { mind.updateTightThreshold($0) }
                    
                    // Overload Threshold
                    configStepperSection(
                        icon: "xmark.octagon.fill",
                        title: "Overload Threshold",
                        value: mind.config.overloadThresholdMin,
                        unit: "min",
                        prefix: "+",
                        subtitle: "Over budget before red alert",
                        range: 5...60,
                        step: 5
                    ) { mind.updateOverloadThreshold($0) }
                }
                .padding(20)
            }
            .navigationTitle("Edit Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
    
    private func configSection<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(VitalPalette.surgeXPGold)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func configStepperSection(
        icon: String,
        title: String,
        value: Int,
        unit: String,
        prefix: String = "",
        subtitle: String,
        range: ClosedRange<Int>,
        step: Int,
        onUpdate: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(VitalPalette.surgeXPGold)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            Text(subtitle)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            
            HStack(spacing: 16) {
                Button {
                    let new = max(range.lowerBound, value - step)
                    onUpdate(new)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                .opacity(value <= range.lowerBound ? 0.4 : 1)
                
                Text("\(prefix)\(value) \(unit)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                    .frame(minWidth: 80)
                
                Button {
                    let new = min(range.upperBound, value + step)
                    onUpdate(new)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
                .opacity(value >= range.upperBound ? 0.4 : 1)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VitalPalette.driftFogVeil)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ✏️ TemplateEditorSheet — Add/Edit spot template
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TemplateEditorSheet: View {
    @ObservedObject var mind: ZenRootMind
    let template: SparkTemplateSeed?
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var durationMin: Int = 30
    @State private var kind: SpotKind = .generic
    @State private var iconName: String?
    @State private var isPinned: Bool = true
    
    private let durationChips = [15, 20, 30, 45, 60, 90, 120]
    private let commonIcons = ["figure.walk", "figure.run", "cup.and.saucer.fill", "laptopcomputer", "person.2.fill", "cart.fill", "car.fill", "book.fill", "phone.fill", "bed.double.fill", "figure.yoga", "circle.fill"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .center, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                        TextField("Spot name", text: $title)
                            .font(.system(size: 16, design: .rounded))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Duration
                    VStack(alignment: .center, spacing: 8) {
                        Text("Default duration")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(durationChips, id: \.self) { min in
                                    ChipButton(title: "\(min)m", isSelected: durationMin == min) {
                                        durationMin = min
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Kind
                    VStack(alignment: .center, spacing: 8) {
                        Text("Type")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SpotKind.allCases) { k in
                                    ChipButton(title: k.title, isSelected: kind == k) {
                                        kind = k
                                        if iconName == nil { iconName = k.icon }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Icon (optional)
                    VStack(alignment: .center, spacing: 8) {
                        Text("Icon (optional)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(commonIcons, id: \.self) { icon in
                                Button {
                                    iconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(iconName == icon ? Color(red: 0.08, green: 0.06, blue: 0.04) : VitalPalette.zenCharcoalDepth)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(iconName == icon ? VitalPalette.surgeXPGold : VitalPalette.driftFogVeil)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Show in Add Spot
                    Toggle(isOn: $isPinned) {
                        Text("Show in Add Spot")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(VitalPalette.zenJetStone)
                    }
                    .tint(VitalPalette.surgeXPGold)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(VitalPalette.surgeXPGold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let t = template {
                    title = t.title
                    durationMin = t.defaultDurationMin
                    kind = t.kind
                    iconName = t.iconName
                    isPinned = t.isPinned
                }
            }
        }
    }
    
    private func saveTemplate() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        if let t = template {
            mind.updateTemplate(id: t.id) { template in
                template.title = trimmed
                template.defaultDurationMin = durationMin
                template.kind = kind
                template.iconName = iconName
                template.isPinned = isPinned
            }
        } else {
            let new = SparkTemplateSeed(
                title: trimmed,
                defaultDurationMin: durationMin,
                kind: kind,
                iconName: iconName,
                isPinned: isPinned
            )
            mind.addTemplate(new)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📤 ShareSheet — UIActivityViewController wrapper
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
