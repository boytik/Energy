import SwiftUI
import Combine

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 🧠 SparkCareLogMind — Pet Care Tab ViewModel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Drives the "Pet Care" tab:
//   - Pet profiles (add/edit/delete)
//   - Care products (add/edit/delete)
//   - Reaction log (pet + product + rating + notes)
//   - Filter by pet / product / rating
//   - Average ratings per product
//   - XP for adding reactions
//
// View file: SparkCareLogCanvas.swift

final class SparkCareLogMind: ObservableObject {
    
    // ── Dependencies ──
    private let vault: VitalVault
    private var cancellables = Set<AnyCancellable>()
    
    // ── Published State ──
    @Published var pets: [SparkPetProfileCapsule] = []
    @Published var products: [SparkCareProductCapsule] = []
    @Published var reactions: [SparkPetReactionSeed] = []
    
    // Filters
    @Published var filterPetId: UUID?
    @Published var filterProductId: UUID?
    @Published var filterRating: PetReactionRating?
    
    // UI state
    @Published var showAddPetSheet = false
    @Published var showAddProductSheet = false
    @Published var showAddReactionSheet = false
    @Published var showDeleteConfirmation = false
    @Published var itemToDeleteId: UUID?
    @Published var deleteItemType: DeleteItemType = .pet
    
    enum DeleteItemType {
        case pet, product, reaction
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Init
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    init(vault: VitalVault = .shared) {
        self.vault = vault
        
        vault.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.refreshFromState(state)
            }
            .store(in: &cancellables)
        
        refreshFromState(vault.state)
    }
    
    private func refreshFromState(_ state: VitalAppState) {
        pets = state.petProfiles
        products = state.careProducts
        reactions = state.petReactions
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Filtered Reactions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    var filteredReactions: [SparkPetReactionSeed] {
        var result = reactions
        
        if let petId = filterPetId {
            result = result.filter { $0.petId == petId }
        }
        if let productId = filterProductId {
            result = result.filter { $0.productId == productId }
        }
        if let rating = filterRating {
            result = result.filter { $0.rating == rating }
        }
        
        return result.sorted { $0.dateRecorded > $1.dateRecorded }
    }
    
    var hasActiveFilters: Bool {
        filterPetId != nil || filterProductId != nil || filterRating != nil
    }
    
    func clearFilters() {
        withAnimation(.easeInOut(duration: 0.2)) {
            filterPetId = nil
            filterProductId = nil
            filterRating = nil
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Computed
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func petName(for id: UUID) -> String {
        pets.first { $0.id == id }?.name ?? "Unknown"
    }
    
    func petEmoji(for id: UUID) -> String {
        pets.first { $0.id == id }?.emoji ?? "🐾"
    }
    
    func productName(for id: UUID) -> String {
        products.first { $0.id == id }?.name ?? "Unknown"
    }
    
    func productCategory(for id: UUID) -> String {
        products.first { $0.id == id }?.category ?? ""
    }
    
    func averageRating(for productId: UUID) -> Double? {
        vault.averageRating(forProductId: productId)
    }
    
    func reactionCount(for productId: UUID) -> Int {
        reactions.filter { $0.productId == productId }.count
    }
    
    func reactionCount(forPet petId: UUID) -> Int {
        reactions.filter { $0.petId == petId }.count
    }
    
    // Product leaderboard: sorted by average rating
    var productRankings: [ProductRanking] {
        products.compactMap { product in
            guard let avg = averageRating(for: product.id) else { return nil }
            return ProductRanking(
                productId: product.id,
                name: product.name,
                category: product.category,
                brand: product.brand,
                averageRating: avg,
                reactionCount: reactionCount(for: product.id)
            )
        }
        .sorted { $0.averageRating > $1.averageRating }
    }
    
    struct ProductRanking: Identifiable {
        let productId: UUID
        let name: String
        let category: String
        let brand: String
        let averageRating: Double
        let reactionCount: Int
        
        var id: UUID { productId }
        
        var starsText: String {
            String(format: "%.1f", averageRating)
        }
        
        var ratingEmoji: String {
            if averageRating >= 4.5 { return "🤩" }
            if averageRating >= 3.5 { return "😊" }
            if averageRating >= 2.5 { return "😐" }
            if averageRating >= 1.5 { return "😟" }
            return "😫"
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Pet Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func addPet(name: String, species: String, emoji: String) {
        let pet = SparkPetProfileCapsule(name: name, species: species, emoji: emoji)
        vault.addPetProfile(pet)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func deletePet(_ id: UUID) {
        vault.deletePetProfile(id: id)
        if filterPetId == id { filterPetId = nil }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Product Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func addProduct(name: String, category: String, brand: String) {
        let product = SparkCareProductCapsule(name: name, category: category, brand: brand)
        vault.addCareProduct(product)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func deleteProduct(_ id: UUID) {
        vault.deleteCareProduct(id: id)
        if filterProductId == id { filterProductId = nil }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Reaction Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func addReaction(petId: UUID, productId: UUID, rating: PetReactionRating, notes: String) {
        let reaction = SparkPetReactionSeed(
            petId: petId,
            productId: productId,
            rating: rating,
            notes: notes
        )
        vault.addPetReaction(reaction)  // auto earns XP
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func deleteReaction(_ id: UUID) {
        vault.deletePetReaction(id: id)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Delete Confirmation
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    func confirmDelete(id: UUID, type: DeleteItemType) {
        itemToDeleteId = id
        deleteItemType = type
        showDeleteConfirmation = true
    }
    
    func performDelete() {
        guard let id = itemToDeleteId else { return }
        switch deleteItemType {
        case .pet:      deletePet(id)
        case .product:  deleteProduct(id)
        case .reaction: deleteReaction(id)
        }
        itemToDeleteId = nil
        showDeleteConfirmation = false
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: – Convenience
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    var hasPets: Bool { !pets.isEmpty }
    var hasProducts: Bool { !products.isEmpty }
    var hasReactions: Bool { !reactions.isEmpty }
    var canAddReaction: Bool { hasPets && hasProducts }
    
    // Pet emoji options
    let petEmojiOptions = ["🐶", "🐱", "🐰", "🐹", "🐦", "🐟", "🐢", "🦎", "🐍", "🦜", "🐴", "🐔"]
    
    // Product category options
    let categoryOptions = ["Shampoo", "Conditioner", "Flea Treatment", "Ear Cleaner",
                           "Toothpaste", "Paw Balm", "Skin Spray", "Deodorizer", "Other"]
}
