import Foundation

/// Pre-built category templates for onboarding and AI matching
struct CategoryTemplates {

    struct Template: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let description: String
        let aiPrompt: String
        /// Keywords the AI might return that map to this template
        let matchKeywords: [String]
    }

    static let all: [Template] = [
        Template(
            name: "Recipes",
            emoji: "🍳",
            description: "Recipes and food inspiration",
            aiPrompt: "Extract recipe name, ingredients list, cooking time, servings, and key preparation steps. Focus on actionable cooking details.",
            matchKeywords: ["recipe", "cooking", "food", "meal", "dinner", "baking", "cuisine"]
        ),
        Template(
            name: "Articles",
            emoji: "📖",
            description: "Long reads and interesting articles",
            aiPrompt: "Extract the main thesis, key arguments, notable quotes, and an estimated reading time. Summarize the core message concisely.",
            matchKeywords: ["article", "blog", "essay", "editorial", "longread", "opinion", "analysis"]
        ),
        Template(
            name: "Products",
            emoji: "🛍️",
            description: "Products and shopping finds",
            aiPrompt: "Extract product name, price, brand, key features, and where to buy. Note any deals or comparisons mentioned.",
            matchKeywords: ["product", "shopping", "buy", "purchase", "deal", "review", "gadget", "gear"]
        ),
        Template(
            name: "Travel",
            emoji: "✈️",
            description: "Travel destinations and planning",
            aiPrompt: "Extract destination, recommended dates or seasons, estimated costs, things to do, and booking links or tips.",
            matchKeywords: ["travel", "trip", "destination", "hotel", "flight", "vacation", "itinerary"]
        ),
        Template(
            name: "Work",
            emoji: "💼",
            description: "Professional resources and references",
            aiPrompt: "Extract key takeaways, action items, deadlines, and relevant contacts or tools. Focus on professional utility.",
            matchKeywords: ["work", "business", "career", "professional", "management", "strategy", "meeting"]
        ),
        Template(
            name: "Inspiration",
            emoji: "✨",
            description: "Design, ideas, and creative inspiration",
            aiPrompt: "Extract the creative concept, medium or format, style elements, and what makes it notable or inspiring.",
            matchKeywords: ["design", "art", "inspiration", "creative", "aesthetic", "portfolio", "mood"]
        ),
    ]

    /// Find the best matching template for an AI-suggested category name
    static func bestMatch(for suggestedCategory: String) -> Template? {
        let lowered = suggestedCategory.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Exact name match first
        if let exact = all.first(where: { $0.name.lowercased() == lowered }) {
            return exact
        }

        // Keyword match
        for template in all {
            if template.matchKeywords.contains(where: { lowered.contains($0) }) {
                return template
            }
        }

        return nil
    }
}
