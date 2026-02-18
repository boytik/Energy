import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🐾 SparkCareLogCanvas — Pet Care Tab View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Features (5 key actions):
//   1. Pet profiles row — horizontal scroll with add
//   2. Product rankings — sorted by avg rating
//   3. Reaction log — filtered list with rating emojis
//   4. Add reaction — pet + product + emoji rating + notes
//   5. Filter by pet / product / rating
//
// ViewModel: SparkCareLogMind.swift

struct SparkCareLogCanvas: View {
    
    @EnvironmentObject var vault: VitalVault
    @StateObject private var mind = SparkCareLogMind()
    
    var body: some View {
        NavigationStack {
            ZStack {
                GoldBlackGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // ── Pets Row ──
                        petsSection
                        
                        // ── Product Rankings ──
                        if mind.hasProducts {
                            productRankingsSection
                                .padding(.horizontal, 20)
                        }
                        
                        // ── Filters ──
                        if mind.hasReactions {
                            filtersRow
                                .padding(.horizontal, 20)
                        }
                        
                        // ── Reaction Log ──
                        if mind.hasReactions {
                            reactionsList
                        } else {
                            emptyState
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Pet Care")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { mind.showAddPetSheet = true } label: {
                            Label("Add Pet", systemImage: "plus.circle")
                        }
                        Button { mind.showAddProductSheet = true } label: {
                            Label("Add Product", systemImage: "tag")
                        }
                        if mind.canAddReaction {
                            Button { mind.showAddReactionSheet = true } label: {
                                Label("Log Reaction", systemImage: "star.bubble")
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(VitalPalette.zenJetStone)
                    }
                }
            }
            .sheet(isPresented: $mind.showAddPetSheet) {
                SparkAddPetSheet(mind: mind)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $mind.showAddProductSheet) {
                SparkAddProductSheet(mind: mind)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $mind.showAddReactionSheet) {
                SparkAddReactionSheet(mind: mind)
                    .presentationDetents([.large])
            }
            .alert("Delete?", isPresented: $mind.showDeleteConfirmation) {
                Button("Delete", role: .destructive) { mind.performDelete() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Pets Section
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("My Pets")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                Spacer()
                
                Button { mind.showAddPetSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(VitalPalette.zenCharcoalDepth)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mind.pets) { pet in
                        petChip(pet)
                            .contextMenu {
                                Button {
                                    mind.filterPetId = pet.id
                                } label: {
                                    Label("Filter reactions", systemImage: "line.3.horizontal.decrease.circle")
                                }
                                Button(role: .destructive) {
                                    mind.confirmDelete(id: pet.id, type: .pet)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    
                    if mind.pets.isEmpty {
                        Button { mind.showAddPetSheet = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.dashed")
                                Text("Add your first pet")
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(VitalPalette.zenSilentStone)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(VitalPalette.zenSilentStone.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func petChip(_ pet: SparkPetProfileCapsule) -> some View {
        let isFiltered = mind.filterPetId == pet.id
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mind.filterPetId = isFiltered ? nil : pet.id
            }
        } label: {
            VStack(spacing: 6) {
                Text(pet.emoji)
                    .font(.system(size: 28))
                
                Text(pet.name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                    .lineLimit(1)
                
                Text("\(mind.reactionCount(forPet: pet.id)) logs")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(VitalPalette.driftSnowField.opacity(isFiltered ? 0.95 : 0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isFiltered ? VitalPalette.zenJetStone : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Product Rankings
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var productRankingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Product Ratings")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            
            if mind.productRankings.isEmpty {
                // Show products without ratings
                ForEach(mind.products) { product in
                    productRow(product)
                }
            } else {
                ForEach(mind.productRankings) { ranking in
                    productRankingRow(ranking)
                }
            }
        }
    }
    
    private func productRow(_ product: SparkCareProductCapsule) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenJetStone)
                
                HStack(spacing: 6) {
                    Text(product.category)
                    if !product.brand.isEmpty {
                        Text("•")
                        Text(product.brand)
                    }
                }
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
            }
            
            Spacer()
            
            Text("No ratings")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(VitalPalette.zenSilentStone)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VitalPalette.driftSnowField.opacity(0.75))
        )
        .contextMenu {
            Button(role: .destructive) {
                mind.confirmDelete(id: product.id, type: .product)
            } label: {
                Label("Delete Product", systemImage: "trash")
            }
        }
    }
    
    private func productRankingRow(_ ranking: SparkCareLogMind.ProductRanking) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mind.filterProductId = mind.filterProductId == ranking.productId ? nil : ranking.productId
            }
        } label: {
            HStack(spacing: 12) {
                Text(ranking.ratingEmoji)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ranking.name)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(VitalPalette.zenJetStone)
                    
                    HStack(spacing: 6) {
                        Text(ranking.category)
                        if !ranking.brand.isEmpty {
                            Text("•")
                            Text(ranking.brand)
                        }
                    }
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ranking.starsText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(VitalPalette.surgeXPGold)
                    
                    Text("\(ranking.reactionCount) logs")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VitalPalette.driftSnowField.opacity(
                        mind.filterProductId == ranking.productId ? 0.95 : 0.75
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                mind.filterProductId == ranking.productId
                                ? VitalPalette.zenJetStone : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                mind.confirmDelete(id: ranking.productId, type: .product)
            } label: {
                Label("Delete Product", systemImage: "trash")
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Filters Row
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var filtersRow: some View {
        HStack(spacing: 8) {
            Text("Reactions")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            
            if mind.hasActiveFilters {
                Button {
                    mind.clearFilters()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenCharcoalDepth)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(VitalPalette.driftFogVeil))
                }
            }
            
            Spacer()
            
            // Rating filter
            Menu {
                Button("All Ratings") { mind.filterRating = nil }
                ForEach(PetReactionRating.allCases, id: \.self) { rating in
                    Button("\(rating.emoji) \(rating.title)") { mind.filterRating = rating }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text(mind.filterRating?.emoji ?? "All")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(VitalPalette.driftFogVeil))
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Reactions List
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var reactionsList: some View {
        LazyVStack(spacing: 10) {
            let filtered = mind.filteredReactions
            
            if filtered.isEmpty {
                Text("No reactions match filters")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(VitalPalette.zenSilentStone)
                    .padding(.vertical, 20)
            } else {
                ForEach(filtered) { reaction in
                    reactionRow(reaction)
                        .padding(.horizontal, 20)
                        .contextMenu {
                            Button(role: .destructive) {
                                mind.confirmDelete(id: reaction.id, type: .reaction)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
    
    private func reactionRow(_ reaction: SparkPetReactionSeed) -> some View {
        HStack(spacing: 12) {
            // Pet emoji
            Text(mind.petEmoji(for: reaction.petId))
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(VitalPalette.driftFogVeil)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(mind.petName(for: reaction.petId))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text("→")
                        .foregroundColor(VitalPalette.zenSilentStone)
                    Text(mind.productName(for: reaction.productId))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundColor(VitalPalette.zenJetStone)
                .lineLimit(1)
                
                if !reaction.notes.isEmpty {
                    Text(reaction.notes)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(VitalPalette.zenAshWhisper)
                        .lineLimit(2)
                }
                
                Text(reaction.dateRecorded, style: .relative)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(VitalPalette.zenSilentStone)
            }
            
            Spacer()
            
            // Rating
            VStack(spacing: 2) {
                Text(reaction.rating.emoji)
                    .font(.system(size: 22))
                Text(reaction.rating.title)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(VitalPalette.zenAshWhisper)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(VitalPalette.driftSnowField.opacity(0.85))
        )
        .shadow(color: VitalPalette.driftShadowMist, radius: 3, x: 0, y: 2)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Empty State
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 48))
                .foregroundColor(VitalPalette.zenSilentStone)
            
            Text("Track Pet Hygiene Reactions")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenCharcoalDepth)
            
            Text("Add your pets and products, then log how they react to each product")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(VitalPalette.zenAshWhisper)
                .multilineTextAlignment(.center)
            
            if mind.canAddReaction {
                Button { mind.showAddReactionSheet = true } label: {
                    Text("Log First Reaction")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(VitalPalette.glowZincSunrise)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(VitalPalette.zenJetStone))
                }
            }
        }
        .padding(.vertical, 50)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🐶 SparkAddPetSheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SparkAddPetSheet: View {
    @ObservedObject var mind: SparkCareLogMind
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var species = ""
    @State private var selectedEmoji = "🐶"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Emoji picker
                VStack(spacing: 10) {
                    Text(selectedEmoji)
                        .font(.system(size: 56))
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(mind.petEmojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .padding(6)
                                    .background(
                                        Circle().fill(
                                            selectedEmoji == emoji
                                            ? VitalPalette.driftFogVeil
                                            : Color.clear
                                        )
                                    )
                            }
                        }
                    }
                }
                
                TextField("Pet name", text: $name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                
                TextField("Species (e.g., Golden Retriever)", text: $species)
                    .font(.system(size: 15, design: .rounded))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        mind.addPet(name: name, species: species, emoji: selectedEmoji)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧴 SparkAddProductSheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SparkAddProductSheet: View {
    @ObservedObject var mind: SparkCareLogMind
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var brand = ""
    @State private var selectedCategory = "Shampoo"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Product name", text: $name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                
                TextField("Brand (optional)", text: $brand)
                    .font(.system(size: 15, design: .rounded))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(mind.categoryOptions, id: \.self) { cat in
                            ChipButton(title: cat, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        mind.addProduct(name: name, category: selectedCategory, brand: brand)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ⭐ SparkAddReactionSheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SparkAddReactionSheet: View {
    @ObservedObject var mind: SparkCareLogMind
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPetId: UUID?
    @State private var selectedProductId: UUID?
    @State private var selectedRating: PetReactionRating = .good
    @State private var notes = ""
    
    var canSave: Bool {
        selectedPetId != nil && selectedProductId != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    petSelectionSection
                    productSelectionSection
                    ratingSelectionSection
                    notesField
                    xpPreview
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let petId = selectedPetId, let productId = selectedProductId else { return }
                        mind.addReaction(
                            petId: petId,
                            productId: productId,
                            rating: selectedRating,
                            notes: notes
                        )
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var petSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which pet?")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mind.pets) { pet in
                        Button {
                            selectedPetId = pet.id
                        } label: {
                            VStack(spacing: 4) {
                                Text(pet.emoji)
                                    .font(.system(size: 32))
                                Text(pet.name)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(VitalPalette.zenJetStone)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(VitalPalette.driftSnowField.opacity(
                                        selectedPetId == pet.id ? 0.95 : 0.6
                                    ))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedPetId == pet.id
                                                ? VitalPalette.zenJetStone : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var productSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which product?")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(mind.products) { product in
                    Button {
                        selectedProductId = product.id
                    } label: {
                        VStack(spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineLimit(1)
                            Text(product.category)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(VitalPalette.zenAshWhisper)
                        }
                        .foregroundColor(VitalPalette.zenJetStone)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(VitalPalette.driftSnowField.opacity(
                                    selectedProductId == product.id ? 0.95 : 0.6
                                ))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedProductId == product.id
                                            ? VitalPalette.zenJetStone : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var ratingSelectionSection: some View {
        VStack(spacing: 12) {
            Text("How did they react?")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.zenJetStone)
            
            HStack(spacing: 10) {
                ForEach(PetReactionRating.allCases, id: \.self) { rating in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRating = rating
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(rating.emoji)
                                .font(.system(size: selectedRating == rating ? 36 : 28))
                            Text(rating.title)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(
                                    selectedRating == rating
                                    ? VitalPalette.zenJetStone
                                    : VitalPalette.zenAshWhisper
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedRating == rating
                                      ? VitalPalette.driftFogVeil
                                      : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var notesField: some View {
        TextField("Notes (optional — redness, scratching, shiny coat...)", text: $notes, axis: .vertical)
            .font(.system(size: 14, design: .rounded))
            .lineLimit(3...6)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(VitalPalette.driftFogVeil))
    }
    
    private var xpPreview: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundColor(VitalPalette.surgeXPGold)
            Text("+\(SurgeXPReward.addPetReaction) XP")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(VitalPalette.surgeXPGold)
        }
    }
}
