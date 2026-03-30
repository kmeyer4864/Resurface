import SwiftUI
import SwiftData

struct CategoryTemplatePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTemplates: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(ResurfaceTheme.Colors.accent)
                    .padding(.top, Spacing.xxl)

                Text("What do you save?")
                    .font(Typography.title2)
                    .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                Text("Pick categories to organize your bookmarks.\nYou can always change these later.")
                    .font(Typography.subheadline)
                    .foregroundStyle(ResurfaceTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, Spacing.xl)

            // Template grid
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Spacing.sm
                ) {
                    ForEach(CategoryTemplates.all) { template in
                        TemplateTile(
                            template: template,
                            isSelected: selectedTemplates.contains(template.name),
                            onTap: { toggleTemplate(template.name) }
                        )
                    }
                }
                .padding(.horizontal, Spacing.layout.horizontalPadding)
            }

            Spacer()

            // Continue button
            Button {
                Task {
                    await createSelectedCategories()
                    dismiss()
                }
            } label: {
                Text(selectedTemplates.isEmpty ? "Skip for now" : "Continue with \(selectedTemplates.count) categories")
                    .font(Typography.bodyMedium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        selectedTemplates.isEmpty
                            ? ResurfaceTheme.Colors.surfaceElevatedFallback
                            : ResurfaceTheme.Colors.accent
                    )
                    .foregroundStyle(
                        selectedTemplates.isEmpty
                            ? ResurfaceTheme.Colors.textSecondary
                            : .white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.large))
            }
            .padding(.horizontal, Spacing.layout.horizontalPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ResurfaceTheme.Colors.backgroundFallback.ignoresSafeArea())
    }

    // MARK: - Actions

    private func toggleTemplate(_ name: String) {
        if selectedTemplates.contains(name) {
            selectedTemplates.remove(name)
        } else {
            selectedTemplates.insert(name)
        }
    }

    private func createSelectedCategories() async {
        guard !selectedTemplates.isEmpty else { return }

        let seeder = CategorySeeder.shared

        var sortOrder = 1
        for template in CategoryTemplates.all where selectedTemplates.contains(template.name) {
            let exists = await seeder.categoryExists(named: template.name, in: modelContext)
            if !exists {
                _ = await seeder.createTemplateCategory(template, sortOrder: sortOrder, in: modelContext)
                sortOrder += 1
            }
        }

        try? modelContext.save()
    }
}

// MARK: - Template Tile

private struct TemplateTile: View {
    let template: CategoryTemplates.Template
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                Text(template.emoji)
                    .font(.system(size: 32))

                VStack(spacing: Spacing.xxs) {
                    Text(template.name)
                        .font(Typography.subheadlineMedium)
                        .foregroundStyle(ResurfaceTheme.Colors.textPrimary)

                    Text(template.description)
                        .font(Typography.caption)
                        .foregroundStyle(ResurfaceTheme.Colors.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.sm)
            .background(
                isSelected
                    ? ResurfaceTheme.Colors.accentSubtle
                    : ResurfaceTheme.Colors.surfaceFallback
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius.medium)
                    .stroke(
                        isSelected ? ResurfaceTheme.Colors.accent : ResurfaceTheme.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryTemplatePickerView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
        .preferredColorScheme(.dark)
}
