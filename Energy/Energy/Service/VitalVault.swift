import Foundation
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🏦 VitalVault — JSON-based local persistence
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Replaces Core Data. Stores entire app state as a single
// Codable JSON file. Thread-safe via a serial queue.
// Auto-saves on every mutation through the `commit()` pattern.

final class VitalVault: ObservableObject {
    
    // ── Published state (drives all UI) ──
    @Published private(set) var state: VitalAppState
    
    // ── Private ──
    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "com.c10.vitalvault.save", qos: .utility)
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    // ── Singleton ──
    static let shared = VitalVault()
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    init(fileName: String = "vital_vault.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent(fileName)
        self.state = VitalAppState()
        self.state = loadFromDisk()
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Core Read/Write
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Mutate state and auto-save. ALL writes go through here.
    /// Usage: vault.commit { $0.config.defaultRhythm = .light }
    /// State update is synchronous on main to avoid race when ensureTodayPlan + addSpot run back-to-back.
    func commit(_ mutation: (inout VitalAppState) -> Void) {
        var copy = state
        mutation(&copy)
        persistToDisk(copy)
        if Thread.isMainThread {
            state = copy
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.state = copy
            }
        }
    }
    
    /// Read-only access (safe to call from any thread)
    var current: VitalAppState { state }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Disk Operations
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func loadFromDisk() -> VitalAppState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let fresh = VitalAppState()
            persistToDisk(fresh)
            return fresh
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let loaded = try decoder.decode(VitalAppState.self, from: data)
            return loaded
        } catch {
            print("⚠️ VitalVault: Failed to load — \(error.localizedDescription). Starting fresh.")
            let fresh = VitalAppState()
            persistToDisk(fresh)
            return fresh
        }
    }
    
    private func persistToDisk(_ appState: VitalAppState) {
        let data: Data
        do {
            data = try encoder.encode(appState)
        } catch {
            print("⚠️ VitalVault: Failed to encode — \(error.localizedDescription)")
            return
        }
        saveQueue.async { [weak self] in
            guard let self else { return }
            do {
                try data.write(to: self.fileURL, options: [.atomic, .completeFileProtection])
            } catch {
                print("⚠️ VitalVault: Failed to save — \(error.localizedDescription)")
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Day Plans
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Get or create today's plan
    func ensureTodayPlan() -> RhythmDayBlueprint {
        ensureDayPlan(for: Date())
    }
    
    /// Get or create a day plan for a date
    func ensureDayPlan(for date: Date) -> RhythmDayBlueprint {
        let key = RhythmDayBlueprint.dayKey(from: date)
        if let existing = state.dayPlans.first(where: { $0.localDayKey == key }) {
            return existing
        }
        let plan = RhythmDayBlueprint.blank(for: date, rhythm: state.config.defaultRhythm)
        commit { $0.dayPlans.append(plan) }
        return plan
    }
    
    /// Update a specific day plan by its dayKey
    func updateDayPlan(dayKey: String, mutation: (inout RhythmDayBlueprint) -> Void) {
        commit { appState in
            guard let idx = appState.dayPlans.firstIndex(where: { $0.localDayKey == dayKey }) else { return }
            mutation(&appState.dayPlans[idx])
            appState.dayPlans[idx].updatedAt = Date()
        }
    }
    
    /// Delete a day plan
    func deleteDayPlan(dayKey: String) {
        commit { $0.dayPlans.removeAll { $0.localDayKey == dayKey } }
    }
    
    /// Copy a day plan to a new date
    func copyDayPlan(fromKey: String, toDate: Date) {
        guard let source = state.dayPlans.first(where: { $0.localDayKey == fromKey }) else { return }
        let newKey = RhythmDayBlueprint.dayKey(from: toDate)
        
        commit { appState in
            // Remove existing plan for target date if any
            appState.dayPlans.removeAll { $0.localDayKey == newKey }
            
            var copy = source
            copy.id = UUID()
            copy.dateStart = toDate
            copy.localDayKey = newKey
            copy.createdAt = Date()
            copy.updatedAt = Date()
            
            // Deep-copy variants with new IDs
            copy.variants = source.variants.map { variant in
                var v = variant
                v.id = UUID()
                v.createdAt = Date()
                v.spots = variant.spots.map { spot in
                    var s = spot
                    s.id = UUID()
                    s.createdAt = Date()
                    return s
                }
                return v
            }
            copy.selectedVariantId = copy.variants.first?.id
            
            appState.dayPlans.append(copy)
        }
    }
    
    /// Copy a single variant from one day to a target date (replaces target day's plan)
    func copyVariantToDay(fromDayKey: String, variantId: UUID, toDate: Date) {
        guard let sourcePlan = state.dayPlans.first(where: { $0.localDayKey == fromDayKey }),
              let sourceVariant = sourcePlan.variants.first(where: { $0.id == variantId }) else { return }
        let newKey = RhythmDayBlueprint.dayKey(from: toDate)
        
        var newVariant = sourceVariant
        newVariant.id = UUID()
        newVariant.createdAt = Date()
        newVariant.updatedAt = Date()
        newVariant.spots = sourceVariant.spots.map { spot in
            var s = spot
            s.id = UUID()
            s.createdAt = Date()
            return s
        }
        
        var newPlan = RhythmDayBlueprint.blank(for: toDate, rhythm: sourceVariant.rhythm)
        newPlan.variants = [newVariant]
        newPlan.selectedVariantId = newVariant.id
        
        commit { appState in
            appState.dayPlans.removeAll { $0.localDayKey == newKey }
            appState.dayPlans.append(newPlan)
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Variants
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Add a new variant to a day (optionally copying from existing)
    func addVariant(dayKey: String, title: String, copyFromVariantId: UUID? = nil) {
        // Ensure plan exists (e.g. for today)
        if state.dayPlans.first(where: { $0.localDayKey == dayKey }) == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dayKey) {
                let plan = RhythmDayBlueprint.blank(for: date, rhythm: state.config.defaultRhythm)
                commit { $0.dayPlans.append(plan) }
            }
        }
        updateDayPlan(dayKey: dayKey) { plan in
            var newVariant: HavenVariantSeed
            
            if let sourceId = copyFromVariantId,
               let source = plan.variants.first(where: { $0.id == sourceId }) {
                newVariant = source
                newVariant.id = UUID()
                newVariant.title = title
                newVariant.isPrimary = false
                newVariant.createdAt = Date()
                // Deep-copy spots
                newVariant.spots = source.spots.map { spot in
                    var s = spot
                    s.id = UUID()
                    return s
                }
            } else {
                newVariant = HavenVariantSeed(
                    title: title,
                    rhythm: plan.activeVariant?.rhythm ?? .normal,
                    isPrimary: false
                )
            }
            
            plan.variants.append(newVariant)
            plan.selectedVariantId = newVariant.id
        }
    }
    
    /// Delete a variant (cannot delete if it's the only one)
    func deleteVariant(dayKey: String, variantId: UUID) {
        updateDayPlan(dayKey: dayKey) { plan in
            guard plan.variants.count > 1 else { return }
            plan.variants.removeAll { $0.id == variantId }
            if plan.selectedVariantId == variantId {
                plan.selectedVariantId = plan.variants.first?.id
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Spots
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Add a spot to the active variant of a day
    func addSpot(dayKey: String, spot: SpotCapsule) {
        updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
            var newSpot = spot
            let spotsInZone = plan.variants[vIdx].spotsIn(zone: spot.zone)
            newSpot.sortIndex = (spotsInZone.map(\.sortIndex).max() ?? -1) + 1
            plan.variants[vIdx].spots.append(newSpot)
            plan.variants[vIdx].updatedAt = Date()
        }
        
        // Record undo
        commit { appState in
            appState.lastAction = CoreLastAction(
                actionKind: .addSpot,
                spotId: spot.id
            )
        }
    }
    
    /// Update a spot within the active variant
    func updateSpot(dayKey: String, spotId: UUID, mutation: (inout SpotCapsule) -> Void) {
        updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
            guard let sIdx = plan.variants[vIdx].spots.firstIndex(where: { $0.id == spotId }) else { return }
            mutation(&plan.variants[vIdx].spots[sIdx])
            plan.variants[vIdx].spots[sIdx].updatedAt = Date()
        }
    }
    
    /// Delete a spot
    func deleteSpot(dayKey: String, spotId: UUID) {
        // Save snapshot for undo
        let snapshot = state.dayPlans
            .first { $0.localDayKey == dayKey }?
            .activeVariant?.spots
            .first { $0.id == spotId }
        
        updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
            plan.variants[vIdx].spots.removeAll { $0.id == spotId }
        }
        
        if let snap = snapshot {
            commit { $0.lastAction = CoreLastAction(
                actionKind: .deleteSpot,
                spotId: spotId,
                previousSpotSnapshot: snap
            )}
        }
    }
    
    /// Move a spot to a different zone and/or index
    func moveSpot(dayKey: String, spotId: UUID, toZone: DayZone, toIndex: Int) {
        // Save for undo
        let snapshot = state.dayPlans
            .first { $0.localDayKey == dayKey }?
            .activeVariant?.spots
            .first { $0.id == spotId }
        
        updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
            guard let sIdx = plan.variants[vIdx].spots.firstIndex(where: { $0.id == spotId }) else { return }
            
            let oldZone = plan.variants[vIdx].spots[sIdx].zone
            plan.variants[vIdx].spots[sIdx].zone = toZone
            plan.variants[vIdx].spots[sIdx].sortIndex = toIndex
            plan.variants[vIdx].spots[sIdx].updatedAt = Date()
            
            // Normalize sort indices in both zones
            normalizeSortIndices(in: &plan.variants[vIdx], zone: oldZone)
            if oldZone != toZone {
                normalizeSortIndices(in: &plan.variants[vIdx], zone: toZone)
            }
        }
        
        if let snap = snapshot {
            commit { $0.lastAction = CoreLastAction(
                actionKind: .moveSpot,
                spotId: spotId,
                previousSpotSnapshot: snap,
                previousZone: snap.zone,
                previousSortIndex: snap.sortIndex
            )}
        }
    }
    
    /// Reorder spots within a zone (after drag-and-drop)
    func reorderSpots(dayKey: String, zone: DayZone, orderedIds: [UUID]) {
        updateDayPlan(dayKey: dayKey) { plan in
            guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
            for (newIndex, spotId) in orderedIds.enumerated() {
                if let sIdx = plan.variants[vIdx].spots.firstIndex(where: { $0.id == spotId }) {
                    plan.variants[vIdx].spots[sIdx].sortIndex = newIndex
                }
            }
        }
    }
    
    private func normalizeSortIndices(in variant: inout HavenVariantSeed, zone: DayZone) {
        let sorted = variant.spots
            .filter { $0.zone == zone }
            .sorted { $0.sortIndex < $1.sortIndex }
        for (newIdx, spot) in sorted.enumerated() {
            if let i = variant.spots.firstIndex(where: { $0.id == spot.id }) {
                variant.spots[i].sortIndex = newIdx
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Undo
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Perform undo of last action (single-step)
    func undoLastAction(dayKey: String) -> Bool {
        guard let action = state.lastAction else { return false }
        
        switch action.actionKind {
        case .deleteSpot:
            if let snapshot = action.previousSpotSnapshot {
                updateDayPlan(dayKey: dayKey) { plan in
                    guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
                    plan.variants[vIdx].spots.append(snapshot)
                }
                commit { $0.lastAction = nil }
                return true
            }
            
        case .moveSpot:
            if let spotId = action.spotId,
               let prevZone = action.previousZone,
               let prevIndex = action.previousSortIndex {
                updateDayPlan(dayKey: dayKey) { plan in
                    guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
                    guard let sIdx = plan.variants[vIdx].spots.firstIndex(where: { $0.id == spotId }) else { return }
                    plan.variants[vIdx].spots[sIdx].zone = prevZone
                    plan.variants[vIdx].spots[sIdx].sortIndex = prevIndex
                }
                commit { $0.lastAction = nil }
                return true
            }
            
        case .addSpot:
            if let spotId = action.spotId {
                updateDayPlan(dayKey: dayKey) { plan in
                    guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
                    plan.variants[vIdx].spots.removeAll { $0.id == spotId }
                }
                commit { $0.lastAction = nil }
                return true
            }
            
        case .editSpot:
            if let snapshot = action.previousSpotSnapshot {
                updateDayPlan(dayKey: dayKey) { plan in
                    guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
                    if let sIdx = plan.variants[vIdx].spots.firstIndex(where: { $0.id == snapshot.id }) {
                        plan.variants[vIdx].spots[sIdx] = snapshot
                    }
                }
                commit { $0.lastAction = nil }
                return true
            }
            
        case .applyFix:
            // For applied fix, we restore the full spot snapshot
            if let snapshot = action.previousSpotSnapshot {
                updateDayPlan(dayKey: dayKey) { plan in
                    guard let vIdx = plan.variants.firstIndex(where: { $0.id == plan.selectedVariantId }) else { return }
                    if let sIdx = plan.variants[vIdx].spots.firstIndex(where: { $0.id == snapshot.id }) {
                        plan.variants[vIdx].spots[sIdx] = snapshot
                    }
                }
                commit { $0.lastAction = nil }
                return true
            }
        }
        
        return false
    }
    
    var canUndo: Bool { state.lastAction != nil }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Templates
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func addTemplate(_ template: SparkTemplateSeed) {
        commit { $0.templates.append(template) }
    }
    
    func updateTemplate(id: UUID, mutation: (inout SparkTemplateSeed) -> Void) {
        commit { appState in
            guard let idx = appState.templates.firstIndex(where: { $0.id == id }) else { return }
            mutation(&appState.templates[idx])
            appState.templates[idx].updatedAt = Date()
        }
    }
    
    func deleteTemplate(id: UUID) {
        commit { $0.templates.removeAll { $0.id == id } }
    }
    
    func incrementTemplateUsage(id: UUID) {
        updateTemplate(id: id) { t in
            t.usageCount += 1
            t.lastUsedAt = Date()
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – XP & Progress
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func earnXP(_ amount: Int) {
        commit { $0.progress.earnXP(amount) }
    }
    
    func recordActiveDay() {
        let todayKey = RhythmDayBlueprint.dayKey(from: Date())
        commit { $0.progress.recordActiveDay(dayKey: todayKey) }
    }
    
    func recordMilestone(_ key: String) {
        commit { appState in
            if !appState.progress.achievedMilestones.contains(key) {
                appState.progress.achievedMilestones.append(key)
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Identity / Profile
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func updateAvatar(_ emoji: String) {
        commit { $0.identity.avatarEmoji = emoji; $0.identity.updatedAt = Date() }
    }
    
    func updateDisplayName(_ name: String) {
        commit { $0.identity.displayName = name; $0.identity.updatedAt = Date() }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Pet Care (Tab 4)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func addPetProfile(_ pet: SparkPetProfileCapsule) {
        commit { $0.petProfiles.append(pet) }
    }
    
    func deletePetProfile(id: UUID) {
        commit { appState in
            appState.petProfiles.removeAll { $0.id == id }
            appState.petReactions.removeAll { $0.petId == id }
        }
    }
    
    func addCareProduct(_ product: SparkCareProductCapsule) {
        commit { $0.careProducts.append(product) }
    }
    
    func deleteCareProduct(id: UUID) {
        commit { appState in
            appState.careProducts.removeAll { $0.id == id }
            appState.petReactions.removeAll { $0.productId == id }
        }
    }
    
    func addPetReaction(_ reaction: SparkPetReactionSeed) {
        commit { $0.petReactions.append(reaction) }
        earnXP(SurgeXPReward.addPetReaction)
    }
    
    func deletePetReaction(id: UUID) {
        commit { $0.petReactions.removeAll { $0.id == id } }
    }
    
    /// Get all reactions for a specific pet
    func reactions(forPetId petId: UUID) -> [SparkPetReactionSeed] {
        state.petReactions.filter { $0.petId == petId }
    }
    
    /// Get all reactions for a specific product
    func reactions(forProductId productId: UUID) -> [SparkPetReactionSeed] {
        state.petReactions.filter { $0.productId == productId }
    }
    
    /// Average rating for a product across all pets
    func averageRating(forProductId productId: UUID) -> Double? {
        let relevant = reactions(forProductId: productId)
        guard !relevant.isEmpty else { return nil }
        let sum = relevant.reduce(0) { $0 + $1.rating.rawValue }
        return Double(sum) / Double(relevant.count)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Config
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func updateConfig(_ mutation: (inout ZenConfigBlueprint) -> Void) {
        commit { appState in
            mutation(&appState.config)
            appState.config.updatedAt = Date()
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Onboarding
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Apply all onboarding changes in a single commit (avoids race with deferred state updates)
    func applyOnboardingComplete(
        rhythm: EnergyRhythm,
        bufferMin: Int,
        travelMin: Int,
        templates: [SparkTemplateSeed],
        zoneForIndex: (Int, Int) -> DayZone
    ) {
        commit { appState in
            appState.config.defaultRhythm = rhythm
            appState.config.defaultBufferBetweenMin = bufferMin
            appState.config.defaultTravelMin = travelMin
            appState.hasCompletedOnboarding = true
            
            let todayKey = RhythmDayBlueprint.dayKey(from: Date())
            
            // Ensure today plan exists
            if appState.dayPlans.first(where: { $0.localDayKey == todayKey }) == nil {
                let plan = RhythmDayBlueprint.blank(for: Date(), rhythm: rhythm)
                appState.dayPlans.append(plan)
            }
            
            guard let planIdx = appState.dayPlans.firstIndex(where: { $0.localDayKey == todayKey }),
                  let vIdx = appState.dayPlans[planIdx].variants.firstIndex(where: { $0.id == appState.dayPlans[planIdx].selectedVariantId }) else { return }
            
            appState.dayPlans[planIdx].variants[vIdx].rhythm = rhythm
            
            for (index, template) in templates.enumerated() {
                var spot = template.toSpot(zone: zoneForIndex(index, templates.count), bufferDefault: bufferMin)
                spot.travelBeforeMin = travelMin
                spot.id = UUID()
                spot.createdAt = Date()
                let zoneSpots = appState.dayPlans[planIdx].variants[vIdx].spots.filter { $0.zone == spot.zone }
                spot.sortIndex = (zoneSpots.map(\.sortIndex).max() ?? -1) + 1
                appState.dayPlans[planIdx].variants[vIdx].spots.append(spot)
                appState.dayPlans[planIdx].variants[vIdx].updatedAt = Date()
                appState.dayPlans[planIdx].updatedAt = Date()
                
                if let tIdx = appState.templates.firstIndex(where: { $0.id == template.id }) {
                    appState.templates[tIdx].usageCount += 1
                    appState.templates[tIdx].lastUsedAt = Date()
                }
            }
            
            appState.progress.earnXP(SurgeXPReward.completeOnboarding + SurgeXPReward.createDayPlan)
            appState.progress.recordActiveDay(dayKey: todayKey)
        }
    }
    
    func completeOnboarding() {
        commit { $0.hasCompletedOnboarding = true }
        earnXP(SurgeXPReward.completeOnboarding)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Statistics
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func computeStats() -> BloomStatsCapsule {
        let plans = state.dayPlans
        let config = state.config
        
        var comfortable = 0
        var tight = 0
        var overloaded = 0
        var totalOverload = 0
        var kindCounts: [SpotKind: Int] = [:]
        var zoneCounts: [DayZone: Int] = [:]
        var totalSpots = 0
        
        for plan in plans {
            guard let variant = plan.activeVariant else { continue }
            let budget = config.budgetMinutes(for: variant.rhythm)
            let planned = variant.totalPlannedMin
            let delta = planned - budget
            
            if delta > config.overloadThresholdMin {
                overloaded += 1
                totalOverload += delta
            } else if delta > config.tightThresholdMin {
                tight += 1
            } else {
                comfortable += 1
            }
            
            for spot in variant.spots {
                kindCounts[spot.kind, default: 0] += 1
                zoneCounts[spot.zone, default: 0] += 1
                totalSpots += 1
            }
        }
        
        let avgOverload = overloaded > 0 ? Double(totalOverload) / Double(overloaded) : 0
        let topKind = kindCounts.max(by: { $0.value < $1.value })?.key
        let topZone = zoneCounts.max(by: { $0.value < $1.value })?.key
        
        return BloomStatsCapsule(
            totalDaysPlanned: plans.count,
            comfortableDays: comfortable,
            tightDays: tight,
            overloadedDays: overloaded,
            averageOverloadMin: avgOverload,
            mostUsedSpotKind: topKind,
            totalSpotsCreated: totalSpots,
            favoriteZone: topZone
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Export / Reset
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Export state as JSON Data (for sharing)
    func exportJSON() -> Data? {
        try? encoder.encode(state)
    }
    
    /// Full reset — deletes everything and starts fresh
    func resetAllData() {
        let fresh = VitalAppState()
        commit { $0 = fresh }
    }
    
    /// File size in bytes (for debug/settings)
    var fileSizeBytes: Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return (attrs?[.size] as? Int64) ?? 0
    }
    
    /// Human-readable file size
    var fileSizeFormatted: String {
        let bytes = fileSizeBytes
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
