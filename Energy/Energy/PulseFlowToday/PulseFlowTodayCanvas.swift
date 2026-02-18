import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ⚡ PulseFlowTodayCanvas — Main "Today" Screen
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Features (7 key actions):
//   1. Mode switcher (Light / Normal / Intense)
//   2. Energy budget bar with live percentage
//   3. Three-zone timeline (Morning / Daytime / Evening)
//   4. Spot cards with swipe-to-delete & context menu
//   5. Overload banner with one-tap fix suggestions
//   6. Add spot FAB (from templates or custom)
//   7. Undo toast for reversible actions
//
// ViewModel: PulseFlowTodayMind.swift

struct PulseFlowTodayCanvas: View {
    
    @EnvironmentObject var vault: VitalVault
    @StateObject private var mind = PulseFlowTodayMind()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GoldBlackGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // ── Mode Switcher ──
                        rhythmSwitcher
                            .padding(.horizontal, 20)
                        
                        // ── Budget Summary Card ──
                        budgetCard
                            .padding(.horizontal, 20)
                        
                        // ── Overload Banner ──
                        if mind.overloadStatus != .comfortable {
                            overloadBanner
                                .padding(.horizontal, 20)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // ── Density Warning ──
                        if let warning = mind.densityWarning, warning.isExceeded {
                            densityLabel(warning)
                                .padding(.horizontal, 20)
                        }
                        
                        // ── Three-Zone Timeline ──
                        ForEach(DayZone.allCases) { zone in
                            zoneSection(zone)
                        }
                        
                        // ── Variant Switcher ──
                        if mind.variantCount > 1 {
                            variantBar
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 8)
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                
                // ── Undo Toast ──
                if mind.showUndoToast {
                    undoToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(mind.todayDateFormatted)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            mind.showAddSpotSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Spot")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(VitalPalette.zenJetStone)
                        }
                        Button {
                            mind.showVariantsSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.on.square")
                                if mind.variantCount > 1 {
                                    Text("\(mind.variantCount)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundColor(VitalPalette.zenJetStone)
                        }
                    }
                }
            }
            .sheet(isPresented: $mind.showAddSpotSheet) {
                SparkSpotCreatorSheet(mind: mind)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $mind.showOverloadSheet) {
                CoreOverloadInsightSheet(mind: mind)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $mind.selectedSpotForEdit) { spot in
                PulseSpotEditSheet(spot: spot, mind: mind)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $mind.showVariantsSheet) {
                HavenVariantSheet(mind: mind)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            DispatchQueue.main.async { mind.loadToday() }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Mode Switcher
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var rhythmSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(EnergyRhythm.allCases) { rhythm in
                Button {
                    mind.switchRhythm(rhythm)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: rhythm.icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(rhythm.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(
                        mind.currentRhythm == rhythm
                        ? VitalPalette.glowZincSunrise
                        : VitalPalette.zenCharcoalDepth
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            mind.currentRhythm == rhythm
                            ? VitalPalette.chipSelectedBg
                            : VitalPalette.driftSnowField.opacity(0.7)
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: mind.currentRhythm)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Budget Card
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var budgetCard: some View {
        VStack(spacing: 12) {
            // Title row
            HStack {
                Text("Energy Budget")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                Spacer()
                
                Text(mind.budgetDisplayText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(mind.overloadStatus.statusColor)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(VitalPalette.driftFogVeil)
                        .frame(height: 12)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(mind.overloadStatus.statusColor)
                        .frame(
                            width: min(geo.size.width, geo.size.width * mind.budgetUsagePercent),
                            height: 12
                        )
                        .animation(.easeInOut(duration: 0.4), value: mind.budgetUsagePercent)
                }
            }
            .frame(height: 12)
            
            // Zone mini-bars
            HStack(spacing: 8) {
                ForEach(DayZone.allCases) { zone in
                    zoneMiniBar(zone)
                }
            }
            
            // Numbers row
            if let summary = mind.daySummary {
                HStack {
                    Label("\(summary.plannedMin) min", systemImage: "clock")
                    Spacer()
                    Label("\(mind.totalSpotCount) spots", systemImage: "mappin.circle")
                    Spacer()
                    Label(mind.currentRhythm.title, systemImage: mind.currentRhythm.icon)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 8, x: 0, y: 4)
    }
    
    private func zoneMiniBar(_ zone: DayZone) -> some View {
        let summary = mind.zoneSummary(for: zone)
        let usage = summary?.usagePercent ?? 0
        let status = summary?.status ?? .comfortable
        
        return VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(zone.tintColor.opacity(0.3))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(status.statusColor)
                        .frame(width: min(geo.size.width, geo.size.width * usage), height: 6)
                        .animation(.easeInOut(duration: 0.4), value: usage)
                }
            }
            .frame(height: 6)
            
            Text(zone.title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Overload Banner
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var overloadBanner: some View {
        Button {
            mind.showOverloadSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: mind.overloadStatus.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(mind.overloadStatus.statusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mind.overloadStatus.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    if let delta = mind.daySummary?.deltaMin, delta > 0 {
                        Text("+\(delta) min over budget")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(VitalPalette.zenAshWhisper)
                    }
                }
                
                Spacer()
                
                Text("Fix")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.glowZincSunrise)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(VitalPalette.chipSelectedBg)
                    )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(VitalPalette.driftSnowField.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(mind.overloadStatus.statusColor.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Density Warning
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func densityLabel(_ warning: CoreOverloadEngine.DensityWarning) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(VitalPalette.pulseCautionAmber)
            Text(warning.displayText ?? "")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(VitalPalette.pulseCautionAmber.opacity(0.08))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Zone Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func zoneSection(_ zone: DayZone) -> some View {
        VStack(spacing: 8) {
            // Zone header
            zoneHeader(zone)
                .padding(.horizontal, 20)
            
            // Spot cards
            let zoneSpots = mind.spots(for: zone)
            
            if zoneSpots.isEmpty {
                emptyZonePlaceholder(zone)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(zoneSpots) { spot in
                        SpotCardView(
                            spot: spot,
                            onTap: { mind.selectedSpotForEdit = spot },
                            onDelete: { mind.deleteSpot(spot.id) },
                            onMoveToZone: { targetZone in
                                mind.moveSpotToZone(spot.id, zone: targetZone)
                            },
                            onCompress: { mind.compressSpot(spot.id) },
                            currentZone: zone
                        )
                        .padding(.horizontal, 20)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: zoneSpots.map(\.id))
            }
        }
    }
    
    private func zoneHeader(_ zone: DayZone) -> some View {
        let summary = mind.zoneSummary(for: zone)
        
        return HStack {
            HStack(spacing: 8) {
                Image(systemName: zone.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                
                Text(zone.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
            }
            
            Spacer()
            
            if let s = summary {
                HStack(spacing: 6) {
                    Text("\(s.plannedMin)/\(s.budgetMin) min")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(s.status.statusColor)
                    
                    Text("•")
                        .foregroundColor(VitalPalette.zenSilentStone)
                    
                    Text("\(mind.spots(for: zone).count) spots")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(zone.tintColor.opacity(0.25))
        )
    }
    
    private func emptyZonePlaceholder(_ zone: DayZone) -> some View {
        HStack {
            Image(systemName: "plus.circle.dashed")
                .foregroundColor(VitalPalette.zenSilentStone)
            Text("No spots in \(zone.title.lowercased()) yet")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(VitalPalette.zenSilentStone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(VitalPalette.zenSilentStone.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Variant Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var variantBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.on.square")
                .foregroundColor(VitalPalette.zenCharcoalDepth)
            
            Text(mind.activeVariantTitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            
            Spacer()
            
            Button {
                mind.showVariantsSheet = true
            } label: {
                Text("Switch")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(VitalPalette.driftFogVeil)
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VitalPalette.driftSnowField.opacity(0.7))
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Undo Toast
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var undoToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Text(mind.undoMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    mind.performUndo()
                } label: {
                    Text("Undo")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.glowZincSunrise)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(VitalPalette.chipSelectedBg)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 95)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🃏 SpotCardView — Single spot card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SpotCardView: View {
    let spot: SpotCapsule
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMoveToZone: (DayZone) -> Void
    let onCompress: () -> Void
    let currentZone: DayZone
    
    var body: some View {
        HStack(spacing: 0) {
            // Tappable card content
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentZone.tintColor.opacity(0.4))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: spot.displayIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(VitalPalette.zenJetStone)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(spot.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(spot.durationMin) min")
                            .foregroundColor(VitalPalette.zenCharcoalDepth)
                        
                        if spot.travelBeforeMin > 0 {
                            Text("🚶 \(spot.travelBeforeMin)")
                                .foregroundColor(VitalPalette.zenAshWhisper)
                        }
                        
                        if spot.bufferAfterMin > 0 {
                            Text("⏸ \(spot.bufferAfterMin)")
                                .foregroundColor(VitalPalette.zenAshWhisper)
                        }
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                
                Spacer()
                
                Text("\(spot.computedLoadMin)m")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(VitalPalette.driftFogVeil)
                    )
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            // Delete button — separate from card content so taps are not captured
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(VitalPalette.zenAshWhisper)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 4, x: 0, y: 2)
        .contextMenu {
            // Move to other zones
            ForEach(DayZone.allCases.filter { $0 != currentZone }) { zone in
                Button {
                    onMoveToZone(zone)
                } label: {
                    Label("Move to \(zone.title)", systemImage: zone.icon)
                }
            }
            
            Divider()
            
            // Compress
            if spot.durationMin > 15 {
                Button {
                    onCompress()
                } label: {
                    Label("Compress −10 min", systemImage: "arrow.down.right.and.arrow.up.left")
                }
            }
            
            Divider()
            
            // Delete
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🆕 SparkSpotCreatorSheet — Add new spot
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SparkSpotCreatorSheet: View {
    @ObservedObject var mind: PulseFlowTodayMind
    @Environment(\.dismiss) private var dismiss
    
    @State private var customTitle = ""
    @State private var customDuration = 30
    @State private var customKind: SpotKind = .generic
    @State private var selectedZone: DayZone = .daytime
    @State private var showCustomForm = false
    
    let durationChips = [15, 20, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ── Quick Add from Templates ──
                    VStack(alignment: .center, spacing: 12) {
                        Text("Quick Add")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(VitalPalette.zenJetStone)
                        
                        // Zone selector
                        HStack(spacing: 8) {
                            ForEach(DayZone.allCases) { zone in
                                ChipButton(
                                    title: zone.title,
                                    isSelected: selectedZone == zone,
                                    action: { selectedZone = zone }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 10
                        ) {
                            ForEach(mind.pinnedTemplates) { template in
                                Button {
                                    mind.addSpotFromTemplate(template, zone: selectedZone)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: template.iconName ?? template.kind.icon)
                                            .font(.system(size: 14))
                                        VStack(alignment: .center, spacing: 1) {
                                            Text(template.title)
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .lineLimit(1)
                                            Text("\(template.defaultDurationMin) min")
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundColor(VitalPalette.zenAshWhisper)
                                        }
                                    }
                                    .foregroundColor(VitalPalette.zenJetStone)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(VitalPalette.driftFogVeil)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().padding(.horizontal, 20)
                    
                    // ── Custom Spot Form ──
                    VStack(alignment: .center, spacing: 12) {
                        Button {
                            withAnimation { showCustomForm.toggle() }
                        } label: {
                            HStack {
                                Text("Create Custom Spot")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                                Spacer()
                                Image(systemName: showCustomForm ? "chevron.up" : "chevron.down")
                                    .foregroundColor(VitalPalette.zenAshWhisper)
                            }
                        }
                        
                        if showCustomForm {
                            VStack(spacing: 14) {
                                // Zone selector (Morning / Daytime / Evening)
                                VStack(alignment: .center, spacing: 8) {
                                    Text("Time of day")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                                    HStack(spacing: 8) {
                                        ForEach(DayZone.allCases) { zone in
                                            ChipButton(
                                                title: zone.title,
                                                isSelected: selectedZone == zone,
                                                action: { selectedZone = zone }
                                            )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Title field
                                TextField("Spot name", text: $customTitle)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(VitalPalette.driftFogVeil)
                                    )
                                
                                // Duration chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(durationChips, id: \.self) { min in
                                            ChipButton(
                                                title: "\(min)m",
                                                isSelected: customDuration == min,
                                                action: { customDuration = min }
                                            )
                                        }
                                    }
                                }
                                
                                // Kind picker
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(SpotKind.allCases) { kind in
                                            ChipButton(
                                                title: kind.title,
                                                isSelected: customKind == kind,
                                                action: { customKind = kind }
                                            )
                                        }
                                    }
                                }
                                
                                // Add button
                                Button {
                                    guard !customTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    mind.addCustomSpot(
                                        title: customTitle,
                                        durationMin: customDuration,
                                        kind: customKind,
                                        zone: selectedZone
                                    )
                                    dismiss()
                                } label: {
                                    Text("Add to \(selectedZone.title)")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(VitalPalette.glowZincSunrise)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(VitalPalette.chipSelectedBg)
                                        )
                                }
                                .disabled(customTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                                .opacity(customTitle.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🔍 CoreOverloadInsightSheet — Overload details + fixes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CoreOverloadInsightSheet: View {
    @ObservedObject var mind: PulseFlowTodayMind
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let insight = mind.insight {
                        // Status header
                        VStack(spacing: 8) {
                            Image(systemName: insight.status.icon)
                                .font(.system(size: 36))
                                .foregroundColor(insight.status.statusColor)
                            
                            Text("Overloaded by +\(max(0, insight.overloadDeltaMin)) min")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(VitalPalette.zenJetStone)
                        }
                        .padding(.top, 8)
                        
                        // Zone breakdown
                        VStack(spacing: 10) {
                            zoneRow("Morning", delta: insight.overMorningDeltaMin)
                            zoneRow("Daytime", delta: insight.overDaytimeDeltaMin)
                            zoneRow("Evening", delta: insight.overEveningDeltaMin)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(VitalPalette.driftFogVeil)
                        )
                        .padding(.horizontal, 20)
                        
                        // Overhead breakdown
                        HStack(spacing: 16) {
                            overheadItem("Activities", value: "\(insight.durationTotalMin)m", icon: "figure.walk")
                            overheadItem("Buffers", value: "\(insight.bufferTotalMin)m", icon: "pause.circle")
                            overheadItem("Travel", value: "\(insight.travelTotalMin)m", icon: "car")
                        }
                        .padding(.horizontal, 20)
                        
                        // Fix suggestions
                        if !insight.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quick Fixes")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                                
                                ForEach(insight.suggestions) { suggestion in
                                    Button {
                                        mind.applySuggestion(suggestion)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: iconForSuggestion(suggestion.kind))
                                                .foregroundColor(VitalPalette.zenCharcoalDepth)
                                                .frame(width: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                                    .foregroundColor(VitalPalette.zenJetStone)
                                                
                                                if suggestion.deltaMin > 0 {
                                                    Text("Saves ~\(suggestion.deltaMin) min")
                                                        .font(.system(size: 12, design: .rounded))
                                                        .foregroundColor(VitalPalette.pulseComfortSage)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(VitalPalette.zenSilentStone)
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(VitalPalette.driftSnowField)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Overload Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
            }
        }
    }
    
    private func zoneRow(_ name: String, delta: Int) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
            Spacer()
            Text(delta > 0 ? "+\(delta) min" : "OK")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(delta > 0 ? VitalPalette.pulseOverloadRust : VitalPalette.pulseComfortSage)
        }
    }
    
    private func overheadItem(_ label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(VitalPalette.driftFogVeil))
    }
    
    private func iconForSuggestion(_ kind: FixWhisperKind) -> String {
        switch kind {
        case .compress:      return "arrow.down.right.and.arrow.up.left"
        case .moveZone:      return "arrow.right.arrow.left"
        case .insertBreak:   return "cup.and.saucer"
        case .removeSpot:    return "minus.circle"
        case .createVariant: return "square.on.square"
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ✏️ PulseSpotEditSheet — Edit single spot
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct PulseSpotEditSheet: View {
    let spot: SpotCapsule
    @ObservedObject var mind: PulseFlowTodayMind
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var duration: Int
    @State private var travel: Int
    @State private var buffer: Int
    @State private var kind: SpotKind
    @State private var effort: SpotEffort
    @State private var note: String
    
    init(spot: SpotCapsule, mind: PulseFlowTodayMind) {
        self.spot = spot
        self.mind = mind
        _title = State(initialValue: spot.title)
        _duration = State(initialValue: spot.durationMin)
        _travel = State(initialValue: spot.travelBeforeMin)
        _buffer = State(initialValue: spot.bufferAfterMin)
        _kind = State(initialValue: spot.kind)
        _effort = State(initialValue: spot.effort)
        _note = State(initialValue: spot.note)
    }
    
    let durationChips = [15, 20, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    TextField("Spot name", text: $title)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(duration) min")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(durationChips, id: \.self) { min in
                                    ChipButton(title: "\(min)m", isSelected: duration == min) {
                                        duration = min
                                    }
                                }
                            }
                        }
                        
                        Stepper("Fine-tune: \(duration) min", value: $duration, in: 5...480, step: 5)
                            .font(.system(size: 14, design: .rounded))
                    }
                    
                    // Travel & Buffer
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Travel before")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            Stepper("\(travel) min", value: $travel, in: 0...60, step: 5)
                                .font(.system(size: 14, design: .rounded))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Buffer after")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            Stepper("\(buffer) min", value: $buffer, in: 0...30, step: 5)
                                .font(.system(size: 14, design: .rounded))
                        }
                    }
                    
                    // Kind
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SpotKind.allCases) { k in
                                    ChipButton(title: k.title, isSelected: kind == k) { kind = k }
                                }
                            }
                        }
                    }
                    
                    // Note
                    TextField("Note (optional)", text: $note)
                        .font(.system(size: 14, design: .rounded))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                    
                    // Total load preview
                    HStack {
                        Text("Total load:")
                        Spacer()
                        Text("\(duration + travel + buffer) min")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        mind.updateSpot(spot.id) { s in
                            s.title = title
                            s.durationMin = duration
                            s.travelBeforeMin = travel
                            s.bufferAfterMin = buffer
                            s.kind = kind
                            s.effort = effort
                            s.note = note
                        }
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(VitalPalette.zenJetStone)
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📋 HavenVariantSheet — Manage variants
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct HavenVariantSheet: View {
    @ObservedObject var mind: PulseFlowTodayMind
    @Environment(\.dismiss) private var dismiss
    @State private var newVariantName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let plan = mind.dayPlan {
                    ForEach(plan.variants) { variant in
                        Button {
                            mind.switchToVariant(variant.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: variant.id == plan.selectedVariantId
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundColor(variant.id == plan.selectedVariantId
                                                     ? VitalPalette.zenJetStone
                                                     : VitalPalette.zenSilentStone)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(variant.title)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(VitalPalette.zenJetStone)
                                    
                                    Text("\(variant.spotCount) spots • \(variant.totalPlannedMin) min")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(VitalPalette.zenAshWhisper)
                                }
                                
                                Spacer()
                                
                                if plan.variants.count > 1 && variant.id != plan.selectedVariantId {
                                    Button {
                                        mind.deleteVariant(variant.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundColor(VitalPalette.pulseOverloadRust)
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(VitalPalette.driftSnowField)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Create new
                HStack {
                    TextField("New variant name", text: $newVariantName)
                        .font(.system(size: 15, design: .rounded))
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(VitalPalette.driftFogVeil))
                    
                    Button {
                        let name = newVariantName.isEmpty ? "Variant \(mind.variantCount + 1)" : newVariantName
                        mind.createVariant(title: name)
                        newVariantName = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(VitalPalette.zenJetStone)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Variants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
            }
        }
    }
}
