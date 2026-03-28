import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the SwiftUI view
        let contentView = ShareExtensionView(
            extensionContext: extensionContext,
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: NSError(domain: "com.resurface.share", code: 0))
            }
        )

        let hostingController = UIHostingController(rootView: contentView)
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
    }
}

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var isProcessing = true
    @State private var isSaved = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isProcessing {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving to Resurface...")
                    .font(.headline)
            } else if isSaved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Saved!")
                    .font(.headline)
            } else if let error = errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            await processSharedContent()
        }
    }

    private func processSharedContent() async {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            errorMessage = "No content to save"
            isProcessing = false
            return
        }

        do {
            for extensionItem in extensionItems {
                guard let attachments = extensionItem.attachments else { continue }

                for attachment in attachments {
                    let content = try await ContentExtractorRegistry.shared.extract(from: attachment)
                    try await saveContent(content)
                }
            }

            isProcessing = false
            isSaved = true

            // Auto-dismiss after success
            try? await Task.sleep(for: .seconds(0.8))
            onComplete()

        } catch {
            isProcessing = false
            errorMessage = "Failed to save: \(error.localizedDescription)"

            // Auto-dismiss after error
            try? await Task.sleep(for: .seconds(2))
            onCancel()
        }
    }

    private func saveContent(_ content: ExtractedContent) async throws {
        // Get the shared model container
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.keenanmeyer.resurface"
        ) else {
            throw ShareError.appGroupNotAvailable
        }

        let storeURL = containerURL.appendingPathComponent("default.store")

        let schema = Schema([
            BookmarkItem.self,
            Category.self,
            Tag.self,
            WebContent.self,
        ])

        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Create the bookmark item
        let item = BookmarkItem(
            contentType: content.contentType,
            title: content.title ?? "Untitled",
            sourceURL: content.url
        )
        item.rawText = content.text

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

        // Notify main app that new content was saved
        ShareNotification.postNewContent()
    }
}

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
