import Foundation


enum CoreOverloadEngine {
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Main Analysis
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Compute full overload insight for a variant
    static func analyze(
        variant: HavenVariantSeed,
        config: ZenConfigBlueprint
    ) -> CoreInsightCapsule {
        
        let rhythm = variant.rhythm
        let totalBudget = config.budgetMinutes(for: rhythm)
        let totalPlanned = variant.totalPlannedMin
        let totalDelta = totalPlanned - totalBudget
        
        // Per-zone analysis
        let morningPlanned = variant.plannedMinIn(zone: .morning)
        let daytimePlanned = variant.plannedMinIn(zone: .daytime)
        let eveningPlanned = variant.plannedMinIn(zone: .evening)
        
        let morningBudget = config.zoneBudget(rhythm: rhythm, zone: .morning)
        let daytimeBudget = config.zoneBudget(rhythm: rhythm, zone: .daytime)
        let eveningBudget = config.zoneBudget(rhythm: rhythm, zone: .evening)
        
        let morningDelta = morningPlanned - morningBudget
        let daytimeDelta = daytimePlanned - daytimeBudget
        let eveningDelta = eveningPlanned - eveningBudget
        
        // Determine status
        let status = computeStatus(
            delta: totalDelta,
            tightThreshold: config.tightThresholdMin,
            overloadThreshold: config.overloadThresholdMin
        )
        
        // Find worst zone
        let zoneDeltas: [(DayZone, Int)] = [
            (.morning, morningDelta),
            (.daytime, daytimeDelta),
            (.evening, eveningDelta)
        ]
        let primaryOverZone = zoneDeltas
            .filter { $0.1 > 0 }
            .max(by: { $0.1 < $1.1 })?
            .0
        
        // Aggregate buffer/travel/duration totals
        let allSpots = variant.spots
        let bufferTotal = allSpots.reduce(0) { $0 + $1.bufferAfterMin }
        let travelTotal = allSpots.reduce(0) { $0 + $1.travelBeforeMin }
        let durationTotal = allSpots.reduce(0) { $0 + $1.durationMin }
        
        // Recommended spots for this mode
        let recommendedSpots = config.recommendedSpots(for: rhythm)
        
        // Build suggestions if overloaded or tight
        var suggestions: [CoreFixWhisper] = []
        if status != .comfortable {
            suggestions = buildSuggestions(
                variant: variant,
                config: config,
                totalDelta: totalDelta,
                zoneDeltas: Dictionary(uniqueKeysWithValues: zoneDeltas),
                recommendedSpots: recommendedSpots
            )
        }
        
        return CoreInsightCapsule(
            variantId: variant.id,
            status: status,
            overloadDeltaMin: totalDelta,
            tightDeltaMin: max(0, totalDelta - config.tightThresholdMin),
            recommendedSpots: recommendedSpots,
            actualSpots: variant.spotCount,
            bufferTotalMin: bufferTotal,
            travelTotalMin: travelTotal,
            durationTotalMin: durationTotal,
            primaryOverZone: primaryOverZone,
            overMorningDeltaMin: morningDelta,
            overDaytimeDeltaMin: daytimeDelta,
            overEveningDeltaMin: eveningDelta,
            suggestions: suggestions
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Quick Status Check (lightweight)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Fast status check without full suggestion generation
    static func quickStatus(
        variant: HavenVariantSeed,
        config: ZenConfigBlueprint
    ) -> OverloadPulse {
        let budget = config.budgetMinutes(for: variant.rhythm)
        let planned = variant.totalPlannedMin
        let delta = planned - budget
        return computeStatus(
            delta: delta,
            tightThreshold: config.tightThresholdMin,
            overloadThreshold: config.overloadThresholdMin
        )
    }
    
    /// Quick zone-level status
    static func zoneStatus(
        variant: HavenVariantSeed,
        zone: DayZone,
        config: ZenConfigBlueprint
    ) -> OverloadPulse {
        let zoneBudget = config.zoneBudget(rhythm: variant.rhythm, zone: zone)
        let zonePlanned = variant.plannedMinIn(zone: zone)
        let delta = zonePlanned - zoneBudget
        return computeStatus(
            delta: delta,
            tightThreshold: config.tightThresholdMin / 2,  // stricter per-zone
            overloadThreshold: config.overloadThresholdMin / 2
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Budget Summary (for UI display)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    struct BudgetSummary {
        let plannedMin: Int
        let budgetMin: Int
        let deltaMin: Int           // positive = over budget
        let remainingMin: Int       // positive = room left
        let status: OverloadPulse
        let usagePercent: Double    // 0...1+
        
        var isOverBudget: Bool { deltaMin > 0 }
        
        /// Human-readable summary
        var displayText: String {
            if deltaMin > 0 {
                return "Overloaded by +\(deltaMin) min"
            } else if remainingMin > 0 {
                return "\(remainingMin) min remaining"
            } else {
                return "Right at the limit"
            }
        }
    }
    
    /// Compute budget summary for the whole day
    static func daySummary(
        variant: HavenVariantSeed,
        config: ZenConfigBlueprint
    ) -> BudgetSummary {
        let budget = config.budgetMinutes(for: variant.rhythm)
        let planned = variant.totalPlannedMin
        let delta = planned - budget
        let remaining = max(0, budget - planned)
        let status = quickStatus(variant: variant, config: config)
        let usage = budget > 0 ? Double(planned) / Double(budget) : 0
        
        return BudgetSummary(
            plannedMin: planned,
            budgetMin: budget,
            deltaMin: max(0, delta),
            remainingMin: remaining,
            status: status,
            usagePercent: usage
        )
    }
    
    /// Compute budget summary for a single zone
    static func zoneSummary(
        variant: HavenVariantSeed,
        zone: DayZone,
        config: ZenConfigBlueprint
    ) -> BudgetSummary {
        let budget = config.zoneBudget(rhythm: variant.rhythm, zone: zone)
        let planned = variant.plannedMinIn(zone: zone)
        let delta = planned - budget
        let remaining = max(0, budget - planned)
        let status = zoneStatus(variant: variant, zone: zone, config: config)
        let usage = budget > 0 ? Double(planned) / Double(budget) : 0
        
        return BudgetSummary(
            plannedMin: planned,
            budgetMin: budget,
            deltaMin: max(0, delta),
            remainingMin: remaining,
            status: status,
            usagePercent: usage
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Spot Density Warning
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    struct DensityWarning {
        let actual: Int
        let recommended: Int
        let isExceeded: Bool
        
        var displayText: String? {
            guard isExceeded else { return nil }
            return "\(actual) spots — \(recommended) recommended for this mode"
        }
    }
    
    /// Check spot count against recommended for the mode
    static func densityCheck(
        variant: HavenVariantSeed,
        config: ZenConfigBlueprint
    ) -> DensityWarning {
        let recommended = config.recommendedSpots(for: variant.rhythm)
        let actual = variant.spotCount
        return DensityWarning(
            actual: actual,
            recommended: recommended,
            isExceeded: actual > recommended
        )
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Apply Suggestion
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// Apply a fix suggestion to a variant, returns the modified variant
    static func applySuggestion(
        _ suggestion: CoreFixWhisper,
        to variant: HavenVariantSeed,
        config: ZenConfigBlueprint
    ) -> HavenVariantSeed {
        var result = variant
        
        switch suggestion.kind {
        case .compress:
            if let spotId = suggestion.targetSpotId,
               let idx = result.spots.firstIndex(where: { $0.id == spotId }) {
                let reduction = min(suggestion.deltaMin, result.spots[idx].durationMin - 5)
                result.spots[idx].durationMin -= max(0, reduction)
                result.spots[idx].updatedAt = Date()
            }
            
        case .moveZone:
            if let spotId = suggestion.targetSpotId,
               let targetZone = suggestion.targetZone,
               let idx = result.spots.firstIndex(where: { $0.id == spotId }) {
                result.spots[idx].zone = targetZone
                let maxIdx = result.spots
                    .filter { $0.zone == targetZone && $0.id != spotId }
                    .map(\.sortIndex).max() ?? -1
                result.spots[idx].sortIndex = maxIdx + 1
                result.spots[idx].updatedAt = Date()
            }
            
        case .insertBreak:
            let targetZone = suggestion.targetZone ?? .daytime
            let maxIdx = result.spots
                .filter { $0.zone == targetZone }
                .map(\.sortIndex).max() ?? -1
            let breakSpot = SpotCapsule(
                title: "Rest & Recharge",
                kind: .rest,
                zone: targetZone,
                sortIndex: maxIdx + 1,
                durationMin: 15,
                travelBeforeMin: 0,
                bufferAfterMin: 0,
                effort: .light,
                iconName: "bed.double.fill"
            )
            result.spots.append(breakSpot)
            
        case .removeSpot:
            if let spotId = suggestion.targetSpotId {
                result.spots.removeAll { $0.id == spotId }
            }
            
        case .createVariant:
            // This is handled at the vault level, not here
            break
        }
        
        result.updatedAt = Date()
        return result
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Private Helpers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private static func computeStatus(
        delta: Int,
        tightThreshold: Int,
        overloadThreshold: Int
    ) -> OverloadPulse {
        if delta > overloadThreshold {
            return .overloaded
        } else if delta > tightThreshold {
            return .tight
        } else {
            return .comfortable
        }
    }
    
    /// Build 3-6 suggestions based on local heuristics only
    private static func buildSuggestions(
        variant: HavenVariantSeed,
        config: ZenConfigBlueprint,
        totalDelta: Int,
        zoneDeltas: [DayZone: Int],
        recommendedSpots: Int
    ) -> [CoreFixWhisper] {
        
        var suggestions: [CoreFixWhisper] = []
        let allSpots = variant.spots.sorted { $0.computedLoadMin > $1.computedLoadMin }
        
        // ── 1. COMPRESS: shrink longest non-rest spots ──
        let compressCandidates = allSpots
            .filter { $0.kind != .rest && $0.durationMin > 20 }
            .prefix(2)
        
        for spot in compressCandidates {
            let reduction = min(15, spot.durationMin - 10)
            guard reduction > 0 else { continue }
            suggestions.append(CoreFixWhisper(
                kind: .compress,
                title: "Compress \"\(spot.title)\" by \(reduction) min",
                deltaMin: reduction,
                targetSpotId: spot.id,
                priority: 80
            ))
        }
        
        // ── 2. MOVE ZONE: if one zone is overloaded, move a light spot elsewhere ──
        if let worstZone = zoneDeltas.max(by: { $0.value < $1.value }),
           worstZone.value > 0 {
            
            let targetZone = leastLoadedZone(excluding: worstZone.key, zoneDeltas: zoneDeltas)
            
            // Pick a short/light spot from the overloaded zone
            let moveCandidates = variant.spotsIn(zone: worstZone.key)
                .filter { $0.kind != .rest }
                .sorted { $0.computedLoadMin < $1.computedLoadMin }
            
            if let candidate = moveCandidates.first {
                suggestions.append(CoreFixWhisper(
                    kind: .moveZone,
                    title: "Move \"\(candidate.title)\" to \(targetZone.title)",
                    deltaMin: candidate.computedLoadMin,
                    targetSpotId: candidate.id,
                    targetZone: targetZone,
                    priority: 70
                ))
            }
        }
        
        // ── 3. INSERT BREAK: if no rest exists in overloaded zone ──
        for (zone, delta) in zoneDeltas where delta > 0 {
            let hasRest = variant.spotsIn(zone: zone).contains { $0.kind == .rest }
            if !hasRest {
                suggestions.append(CoreFixWhisper(
                    kind: .insertBreak,
                    title: "Add 15 min break in \(zone.title)",
                    deltaMin: 0,   // breaks don't reduce overload, they make plan realistic
                    targetZone: zone,
                    priority: 50
                ))
                break  // only suggest one break
            }
        }
        
        // ── 4. REMOVE SPOT: if way over recommended count ──
        if variant.spotCount > recommendedSpots + 2 {
            // Suggest removing the shortest non-rest spot
            let removeCandidates = allSpots
                .filter { $0.kind != .rest }
                .suffix(1)  // shortest
            
            if let candidate = removeCandidates.first {
                suggestions.append(CoreFixWhisper(
                    kind: .removeSpot,
                    title: "Remove \"\(candidate.title)\" (\(candidate.computedLoadMin) min)",
                    deltaMin: candidate.computedLoadMin,
                    targetSpotId: candidate.id,
                    priority: 40
                ))
            }
        }
        
        // ── 5. CREATE VARIANT: always offer if overloaded ──
        if totalDelta > config.overloadThresholdMin {
            suggestions.append(CoreFixWhisper(
                kind: .createVariant,
                title: "Create a lighter variant",
                deltaMin: 0,
                priority: 30
            ))
        }
        
        // Sort by priority descending
        return suggestions.sorted { $0.priority > $1.priority }
    }
    
    /// Find the zone with the least overload (or most room)
    private static func leastLoadedZone(
        excluding: DayZone,
        zoneDeltas: [DayZone: Int]
    ) -> DayZone {
        DayZone.allCases
            .filter { $0 != excluding }
            .min(by: { (zoneDeltas[$0] ?? 0) < (zoneDeltas[$1] ?? 0) })
            ?? .evening
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 📊 Overhead Breakdown (for charts & detail sheet)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension CoreOverloadEngine {
    
    struct OverheadBreakdown {
        let durationMin: Int
        let bufferMin: Int
        let travelMin: Int
        let totalMin: Int
        
        var durationPercent: Double {
            guard totalMin > 0 else { return 0 }
            return Double(durationMin) / Double(totalMin)
        }
        var bufferPercent: Double {
            guard totalMin > 0 else { return 0 }
            return Double(bufferMin) / Double(totalMin)
        }
        var travelPercent: Double {
            guard totalMin > 0 else { return 0 }
            return Double(travelMin) / Double(totalMin)
        }
    }
    
    /// Break down where minutes go: activities vs buffers vs travel
    static func overheadBreakdown(variant: HavenVariantSeed) -> OverheadBreakdown {
        let spots = variant.spots
        let dur = spots.reduce(0) { $0 + $1.durationMin }
        let buf = spots.reduce(0) { $0 + $1.bufferAfterMin }
        let trv = spots.reduce(0) { $0 + $1.travelBeforeMin }
        return OverheadBreakdown(
            durationMin: dur,
            bufferMin: buf,
            travelMin: trv,
            totalMin: dur + buf + trv
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🏅 Top Spots by Load (for bar chart)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension CoreOverloadEngine {
    
    struct SpotLoadEntry: Identifiable {
        let id: UUID
        let title: String
        let loadMin: Int
        let kind: SpotKind
        let zone: DayZone
    }
    
    /// Top N spots by total load
    static func topSpotsByLoad(
        variant: HavenVariantSeed,
        limit: Int = 6
    ) -> [SpotLoadEntry] {
        variant.spots
            .sorted { $0.computedLoadMin > $1.computedLoadMin }
            .prefix(limit)
            .map { SpotLoadEntry(
                id: $0.id,
                title: $0.title,
                loadMin: $0.computedLoadMin,
                kind: $0.kind,
                zone: $0.zone
            )}
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🔄 Variant Comparison
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension CoreOverloadEngine {
    
    struct VariantComparison {
        let variantA: VariantSnapshot
        let variantB: VariantSnapshot
        let addedSpots: [String]      // titles in B but not A
        let removedSpots: [String]    // titles in A but not B
        let movedSpots: [String]      // same title, different zone
        let compressedSpots: [String] // same title, shorter duration
    }
    
    struct VariantSnapshot {
        let id: UUID
        let title: String
        let totalMin: Int
        let spotCount: Int
        let status: OverloadPulse
        let morningMin: Int
        let daytimeMin: Int
        let eveningMin: Int
    }
    
    /// Compare two variants of the same day
    static func compareVariants(
        a: HavenVariantSeed,
        b: HavenVariantSeed,
        config: ZenConfigBlueprint
    ) -> VariantComparison {
        
        let snapA = VariantSnapshot(
            id: a.id, title: a.title,
            totalMin: a.totalPlannedMin, spotCount: a.spotCount,
            status: quickStatus(variant: a, config: config),
            morningMin: a.plannedMinIn(zone: .morning),
            daytimeMin: a.plannedMinIn(zone: .daytime),
            eveningMin: a.plannedMinIn(zone: .evening)
        )
        let snapB = VariantSnapshot(
            id: b.id, title: b.title,
            totalMin: b.totalPlannedMin, spotCount: b.spotCount,
            status: quickStatus(variant: b, config: config),
            morningMin: b.plannedMinIn(zone: .morning),
            daytimeMin: b.plannedMinIn(zone: .daytime),
            eveningMin: b.plannedMinIn(zone: .evening)
        )
        
        let titlesA = Set(a.spots.map(\.title))
        let titlesB = Set(b.spots.map(\.title))
        
        let added = titlesB.subtracting(titlesA).sorted()
        let removed = titlesA.subtracting(titlesB).sorted()
        
        // Check for moved spots (same title, different zone)
        var moved: [String] = []
        var compressed: [String] = []
        let commonTitles = titlesA.intersection(titlesB)
        for title in commonTitles {
            let spotA = a.spots.first { $0.title == title }
            let spotB = b.spots.first { $0.title == title }
            if let sA = spotA, let sB = spotB {
                if sA.zone != sB.zone { moved.append(title) }
                if sB.durationMin < sA.durationMin { compressed.append(title) }
            }
        }
        
        return VariantComparison(
            variantA: snapA,
            variantB: snapB,
            addedSpots: added,
            removedSpots: removed,
            movedSpots: moved.sorted(),
            compressedSpots: compressed.sorted()
        )
    }
}
