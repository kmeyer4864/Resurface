import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the shared model container
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.keenanmeyer.resurface"
        ) else {
            showError("App group not configured")
            return
        }

        let storeURL = containerURL.appendingPathComponent("default.store")

        let schema = Schema([
            BookmarkItem.self,
            Category.self,
            Tag.self,
            WebContent.self,
        ])

        do {
            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])

            let contentView = ShareExtensionView(
                extensionContext: extensionContext,
                modelContainer: container,
                containerURL: containerURL,
                onComplete: { [weak self] in
                    self?.extensionContext?.completeRequest(returningItems: nil)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: NSError(domain: "com.resurface.share", code: 0))
                },
                onOpenApp: { [weak self] url in
                    self?.openMainApp(with: url)
                }
            )

            let hostingController = UIHostingController(rootView: contentView)
            hostingController.view.backgroundColor = .clear

            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

            hostingController.didMove(toParent: self)

        } catch {
            showError("Failed to initialize: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.cancelRequest(withError: NSError(domain: "com.resurface.share", code: 1))
        })
        present(alert, animated: true)
    }

    private func openMainApp(with url: URL) {
        // Open the main app via URL scheme
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }

        // Also try the selector method for Share Extensions
        let selector = sel_registerName("openURL:")
        var currentResponder: UIResponder? = self
        while currentResponder != nil {
            if currentResponder!.responds(to: selector) {
                currentResponder!.perform(selector, with: url)
                break
            }
            currentResponder = currentResponder?.next
        }
    }
}

// MARK: - Share Extension View

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    let modelContainer: ModelContainer
    let containerURL: URL
    let onComplete: () -> Void
    let onCancel: () -> Void
    let onOpenApp: (URL) -> Void

    // State
    @State private var phase: SharePhase = .extracting
    @State private var extractedContent: ExtractedContent?
    @State private var categories: [Category] = []
    @State private var selectedCategory: Category?
    @State private var selectedResurfaceOption: ResurfaceOption = .never
    @State private var errorMessage: String?

    enum SharePhase {
        case extracting
        case selecting
        case saving
        case success
        case error
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            // Card
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    switch phase {
                    case .extracting:
                        extractingView
                    case .selecting:
                        selectingView
                    case .saving:
                        savingView
                    case .success:
                        successView
                    case .error:
                        errorView
                    }
                }
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .task {
            await loadCategoriesAndExtractContent()
        }
    }

    // MARK: - Phase Views

    private var extractingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Preparing...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var selectingView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text("Save to Resurface")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    saveContent()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.purple)
            }
            .padding()

            Divider()

            // Content preview
            if let content = extractedContent {
                HStack(spacing: 12) {
                    // Icon based on content type
                    Image(systemName: content.contentType.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(Color.purple)
                        .frame(width: 44, height: 44)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(content.title ?? "Untitled")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)

                        if let host = content.url?.host?.replacingOccurrences(of: "www.", with: "") {
                            Text(host)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
            }

            Divider()

            // Category picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                onTap: { selectedCategory = category }
                            )
                        }

                        // Create new category button
                        Button {
                            openCreateCategory()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("New")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.purple)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Divider()
                .padding(.top, 12)

            // Resurface picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Resurface this?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ResurfaceOption.allCases) { option in
                            ResurfaceChip(
                                option: option,
                                isSelected: selectedResurfaceOption == option,
                                onTap: { selectedResurfaceOption = option }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }

    private var savingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Saving...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            Text("Saved!")
                .font(.headline)

            if selectedResurfaceOption != .never {
                Text("Reminder set for \(selectedResurfaceOption.shortName.lowercased())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            Text(errorMessage ?? "Something went wrong")
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                phase = .extracting
                Task {
                    await loadCategoriesAndExtractContent()
                }
            }
            .foregroundStyle(Color.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func loadCategoriesAndExtractContent() async {
        // Load categories
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            categories = try context.fetch(descriptor)

            // Set default category as selected
            selectedCategory = categories.first { $0.isDefault } ?? categories.first

            // If no categories exist, create Universal Folder
            if categories.isEmpty {
                let universal = Category.createUniversalFolder()
                context.insert(universal)
                try context.save()
                categories = [universal]
                selectedCategory = universal
            }
        } catch {
            // Continue without categories
        }

        // Extract content
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            errorMessage = "No content to save"
            phase = .error
            return
        }

        do {
            for extensionItem in extensionItems {
                guard let attachments = extensionItem.attachments else { continue }

                for attachment in attachments {
                    extractedContent = try await ContentExtractorRegistry.shared.extract(from: attachment)
                    phase = .selecting
                    return
                }
            }

            errorMessage = "No supported content found"
            phase = .error
        } catch {
            errorMessage = "Failed to process: \(error.localizedDescription)"
            phase = .error
        }
    }

    private func saveContent() {
        guard let content = extractedContent else {
            errorMessage = "No content to save"
            phase = .error
            return
        }

        phase = .saving

        Task {
            do {
                let context = ModelContext(modelContainer)

                // Create the bookmark item
                let item = BookmarkItem(
                    contentType: content.contentType,
                    title: content.title ?? "Untitled",
                    sourceURL: content.url
                )
                item.rawText = content.text

                // Set category
                if let selectedCategory = selectedCategory {
                    // Fetch the category in this context
                    let categoryId = selectedCategory.id
                    let descriptor = FetchDescriptor<Category>(
                        predicate: #Predicate<Category> { $0.id == categoryId }
                    )
                    if let category = try? context.fetch(descriptor).first {
                        item.category = category
                    }
                }

                // Set resurface time
                if let resurfaceDate = selectedResurfaceOption.targetDate() {
                    item.resurfaceAt = resurfaceDate
                }

                // Save media if present
                if let imageData = content.imageData {
                    let mediaURL = containerURL
                        .appendingPathComponent("Documents/media", isDirectory: true)
                    try FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)

                    let fileName = "\(item.id.uuidString).jpg"
                    let fileURL = mediaURL.appendingPathComponent(fileName)
                    try imageData.write(to: fileURL)
                    item.mediaPath = "media/\(fileName)"
                }

                context.insert(item)
                try context.save()

                // Notify main app
                ShareNotification.postNewContent()

                phase = .success

                // Auto-dismiss after success
                try? await Task.sleep(for: .seconds(0.8))
                onComplete()

            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                phase = .error
            }
        }
    }

    private func openCreateCategory() {
        // Save current content ID for later
        // Open main app with deep link
        if let url = URL(string: "resurface://create-category") {
            onOpenApp(url)
            onCancel()
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.system(size: 16))
                Text(category.name)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple.opacity(0.2) : Color(uiColor: .secondarySystemBackground))
            .foregroundStyle(isSelected ? Color.purple : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Resurface Chip

struct ResurfaceChip: View {
    let option: ResurfaceOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: option.iconName)
                    .font(.system(size: 12))
                Text(option.shortName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple.opacity(0.2) : Color(uiColor: .secondarySystemBackground))
            .foregroundStyle(isSelected ? Color.purple : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Errors

enum ShareError: LocalizedError {
    case appGroupNotAvailable
    case noContent
    case extractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .appGroupNotAvailable:
            return "App group not configured"
        case .noContent:
            return "No content to save"
        case .extractionFailed(let reason):
            return "Extraction failed: \(reason)"
        }
    }
}
