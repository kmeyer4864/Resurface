import SwiftUI
import SwiftData

/// View for creating a new category with emoji, description, and AI prompt
struct CategoryCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var emoji: String = "📁"
    @State private var description: String = ""
    @State private var aiPrompt: String = ""
    @State private var showInFeed: Bool = true
    @State private var showPromptEditor = false

    // Validation
    @State private var showValidationError = false
    @State private var validationMessage = ""

    // Optional: pending content to save after creation
    var pendingContentId: UUID?
    var onCategoryCreated: ((Category) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Emoji picker
                    emojiSection

                    // Name input
                    nameSection

                    // Description input
                    descriptionSection

                    // AI Prompt section
                    aiPromptSection

                    // Feed visibility
                    feedToggleSection

                    // Tips
                    tipsSection
                }
                .padding()
            }
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createCategory()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? ResurfaceTheme.Colors.accent : ResurfaceTheme.Colors.textTertiary)
                    .disabled(!isValid)
                }
            }
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Missing Information", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .onChange(of: description) { _, newValue in
                generateAIPrompt(from: newValue)
            }
        }
    }

    // MARK: - Sections

    private var emojiSection: some View {
        VStack(spacing: Spacing.sm) {
            EmojiPickerButton(selectedEmoji: $emoji)

            Text("Tap to change")
                .font(Typography.caption)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Name")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

            TextField("e.g., HSA Receipts, Trip Ideas", text: $name)
                .textFieldStyle(.plain)
                .font(Typography.body)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                .padding()
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                        .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                )
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("What will you use this for?")
                .font(Typography.subheadlineMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

            TextField("Describe the types of content you'll save here...", text: $description, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Typography.body)
                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                .lineLimit(3...6)
                .padding()
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                        .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                )

            Text("This helps the AI understand what to focus on when analyzing content in this category.")
                .font(Typography.caption)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        }
    }

    private var aiPromptSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("AI Instructions")
                    .font(Typography.subheadlineMedium)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

                Spacer()

                if !aiPrompt.isEmpty {
                    Button {
                        showPromptEditor.toggle()
                    } label: {
                        Text(showPromptEditor ? "Done" : "Edit")
                            .font(Typography.caption)
                            .foregroundStyle(ResurfaceTheme.Colors.accent)
                    }
                }
            }

            if aiPrompt.isEmpty {
                // Placeholder before description is entered
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                    Text("Enter a description above to generate AI instructions")
                        .font(Typography.subheadline)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ResurfaceTheme.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                        .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                )
            } else if showPromptEditor {
                // Editable prompt
                TextField("Custom AI instructions...", text: $aiPrompt, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Typography.body)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                    .lineLimit(4...8)
                    .padding()
                    .background(ResurfaceTheme.Colors.surfaceFallback)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                            .stroke(ResurfaceTheme.Colors.accent.opacity(0.5), lineWidth: 1)
                    )
            } else {
                // Preview of generated prompt
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ResurfaceTheme.Colors.accent)

                    Text(aiPrompt)
                        .font(Typography.subheadline)
                        .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                        .lineLimit(4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ResurfaceTheme.Colors.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
            }
        }
    }

    private var feedToggleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Toggle(isOn: $showInFeed) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Show in Feed")
                        .font(Typography.subheadlineMedium)
                        .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                    Text("Items will appear in your daily resurfacing feed")
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                }
            }
            .tint(ResurfaceTheme.Colors.accent)
            .padding()
            .background(ResurfaceTheme.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tips for good results")
                .font(Typography.captionMedium)
                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                tipRow("Be specific about what you'll save")
                tipRow("Mention what details to extract")
                tipRow("The AI will focus only on relevant info")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ResurfaceTheme.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(ResurfaceTheme.Colors.success)
            Text(text)
                .font(Typography.caption)
                .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
        }
    }

    // MARK: - Logic

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func generateAIPrompt(from description: String) {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            aiPrompt = ""
            return
        }

        // Generate a prompt based on the description
        aiPrompt = """
        For content saved to "\(name.isEmpty ? "this category" : name)": \(trimmed.lowercased())

        Focus on extracting relevant details and ignore unrelated information. Identify key dates, amounts, names, or action items if present.
        """
    }

    private func createCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a name for your category."
            showValidationError = true
            return
        }

        guard !trimmedDesc.isEmpty else {
            validationMessage = "Please describe what you'll use this category for."
            showValidationError = true
            return
        }

        // Get next sort order
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        let maxSortOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1

        let category = Category(
            name: trimmedName,
            emoji: emoji,
            description: trimmedDesc,
            aiPrompt: aiPrompt.isEmpty ? "Analyze this content and extract key information relevant to: \(trimmedDesc)" : aiPrompt,
            isDefault: false,
            showInFeed: showInFeed,
            sortOrder: maxSortOrder + 1
        )

        modelContext.insert(category)

        do {
            try modelContext.save()
            onCategoryCreated?(category)
            dismiss()
        } catch {
            validationMessage = "Failed to save category. Please try again."
            showValidationError = true
        }
    }
}

// MARK: - Edit Category View

struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var category: Category

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var description: String = ""
    @State private var aiPrompt: String = ""
    @State private var showInFeed: Bool = true
    @State private var showPromptEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Emoji
                    EmojiPickerButton(selectedEmoji: $emoji)

                    // Name
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Name")
                            .font(Typography.subheadlineMedium)
                            .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

                        TextField("Category name", text: $name)
                            .textFieldStyle(.plain)
                            .font(Typography.body)
                            .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                            .padding()
                            .background(ResurfaceTheme.Colors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                                    .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                            )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Description")
                            .font(Typography.subheadlineMedium)
                            .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

                        TextField("What is this category for?", text: $description, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(Typography.body)
                            .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                            .lineLimit(3...6)
                            .padding()
                            .background(ResurfaceTheme.Colors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                                    .stroke(ResurfaceTheme.Colors.border, lineWidth: 0.5)
                            )
                    }

                    // Feed visibility
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Toggle(isOn: $showInFeed) {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Show in Feed")
                                    .font(Typography.subheadlineMedium)
                                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                                Text("Items will appear in your daily resurfacing feed")
                                    .font(Typography.caption)
                                    .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                            }
                        }
                        .tint(ResurfaceTheme.Colors.accent)
                        .padding()
                        .background(ResurfaceTheme.Colors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                    }

                    // AI Prompt
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("AI Instructions")
                                .font(Typography.subheadlineMedium)
                                .foregroundStyle(ResurfaceTheme.Colors.textSecondary)

                            Spacer()

                            Button {
                                showPromptEditor.toggle()
                            } label: {
                                Text(showPromptEditor ? "Done" : "Edit")
                                    .font(Typography.caption)
                                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                            }
                        }

                        if showPromptEditor {
                            TextField("AI instructions...", text: $aiPrompt, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(Typography.body)
                                .foregroundStyle(ResurfaceTheme.Colors.textPrimary)
                                .lineLimit(4...8)
                                .padding()
                                .background(ResurfaceTheme.Colors.surfaceFallback)
                                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                                        .stroke(ResurfaceTheme.Colors.accent.opacity(0.5), lineWidth: 1)
                                )
                        } else {
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(ResurfaceTheme.Colors.accent)

                                Text(aiPrompt)
                                    .font(Typography.subheadline)
                                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                                    .lineLimit(4)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ResurfaceTheme.Colors.accentSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
                        }
                    }
                }
                .padding()
            }
            .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                }
            }
            .toolbarBackground(ResurfaceTheme.Colors.backgroundFallback, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                name = category.name
                emoji = category.emoji
                description = category.categoryDescription
                aiPrompt = category.aiPrompt
                showInFeed = category.showInFeed
            }
        }
    }

    private func saveChanges() {
        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.emoji = emoji
        category.categoryDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        category.aiPrompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        category.showInFeed = showInFeed
        category.markUpdated()

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Category Extension

extension Category {
    func markUpdated() {
        // Could track updatedAt if needed
    }
}

#Preview {
    CategoryCreationView()
        .modelContainer(for: [Category.self], inMemory: true)
}
