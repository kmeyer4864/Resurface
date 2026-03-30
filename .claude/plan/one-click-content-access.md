# Implementation Plan: One-Click Content Access & Local Storage

## Task Type
- [x] Frontend (UI changes for unified open action)
- [x] Backend (file storage, new extractor, model changes)
- [x] Fullstack

## Problem Statement

When content is shared to Resurface (files, weblinks, screenshots, PDFs, documents, etc.), the original content should be:
1. **Stored locally** in the App Group container so it's always available
2. **Accessible with one tap** from the detail view — unified UX for all content types

### Current Gaps

| Content Type | Current Behavior | Gap |
|---|---|---|
| URLs/Articles | Only stores `sourceURL`, opens in Safari | No offline access; depends on external browser |
| Images/Screenshots | Stored as `.jpg` in `media/` | ✅ Works — viewable in full-screen preview |
| PDFs | Stored in `media/` | Opens via ShareLink (multi-step, not one-click) |
| Text | Stored in `rawText` field only | No exportable file |
| Generic Files (docs, spreadsheets, etc.) | **Not handled at all** | No `FileExtractor`, no storage, no UI |

## Technical Solution

### 1. New `FileExtractor` for Generic Files

Add a catch-all `FileExtractor` that handles any file type not caught by the specific extractors (PDF, Image). This covers Word docs, spreadsheets, zip files, audio, video files, etc.

```swift
// ShareExtension/ContentExtractors/FileExtractor.swift
struct FileExtractor: ContentExtractor {
    // Handles: .data, .item (broad catch-all)
    // Extracts: original filename, file data, UTType for extension mapping
    // Stores: full file in media/ with original extension preserved
}
```

### 2. New `file` Content Type

```swift
// Add to ContentType enum:
case file = "file"   // Generic file (doc, spreadsheet, zip, audio, etc.)

var displayName: String { "File" }
var iconName: String { "doc" }
```

### 3. Enhanced `ExtractedContent` Struct

```swift
struct ExtractedContent {
    var contentType: ContentType
    var title: String?
    var text: String?
    var url: URL?
    var imageData: Data?
    var fileData: Data?            // NEW: raw file bytes for non-image files
    var originalFilename: String?  // NEW: preserve original filename
    var fileExtension: String?     // NEW: preserve file extension (pdf, docx, etc.)
    var mimeType: String?          // NEW: for QuickLook and sharing
    var metadata: [String: Any] = [:]
}
```

### 4. Model Changes — `BookmarkItem`

```swift
// Add to BookmarkItem:
var originalFilename: String?  // Original filename from share
var mimeType: String?          // MIME type for proper opening
```

### 5. Unified File Storage in `ShareViewController.saveContent()`

Update the save logic to handle all file types with proper extensions:

```swift
// Pseudo-code for unified save:
if let fileData = content.fileData ?? content.imageData {
    let ext = content.fileExtension ?? "dat"
    let fileName = "\(item.id.uuidString).\(ext)"
    try AppGroupContainer.saveMedia(data: fileData, filename: fileName)
    item.mediaPath = "media/\(fileName)"
    item.originalFilename = content.originalFilename
    item.mimeType = content.mimeType
}
```

### 6. Unified One-Click "Open" Action in Detail View

Replace the current fragmented `openOriginalButton` with a single, unified action:

```swift
// Pseudo-code for unified open button:
@ViewBuilder
var openOriginalButton: some View {
    if let url = item.sourceURL {
        // URL-based: open in browser
        Link(destination: url) { openButtonLabel("Open Original", icon: "safari") }
    }

    if item.mediaPath != nil {
        // File-based: open with QuickLook (supports ALL file types)
        Button { showQuickLook = true } label: {
            openButtonLabel("View \(item.contentType.displayName)", icon: "eye")
        }
    }
}
```

**Key change**: Use `QLPreviewController` (QuickLook) instead of custom viewers. QuickLook natively handles:
- Images (jpg, png, heic, gif)
- PDFs
- Office documents (docx, xlsx, pptx)
- Audio/Video files
- Plain text
- And more

This replaces the custom `ImagePreviewView` and the PDF `ShareLink` with one unified viewer.

### 7. Add "Save to Files" / "Save to Camera Roll" Action

Add a secondary action in the toolbar menu for exporting:

```swift
// In toolbar menu, after existing items:
if let mediaPath = item.mediaPath,
   let fileURL = item.resolvedMediaURL {
    ShareLink(item: fileURL) {
        Label("Export File", systemImage: "square.and.arrow.up")
    }
}

// For images specifically:
if item.contentType == .image || item.contentType == .screenshot {
    Button { saveToPhotoLibrary() } label: {
        Label("Save to Photos", systemImage: "photo.badge.arrow.down")
    }
}
```

## Implementation Steps

### Step 1: Add `file` Content Type
- **File**: `Shared/Models/ContentType.swift`
- **Operation**: Add `case file = "file"` with display name "File" and icon "doc"
- **Deliverable**: New enum case compiles, no UI breaks

### Step 2: Enhance `ExtractedContent` struct
- **File**: `ShareExtension/ContentExtractors/ContentExtractor.swift`
- **Operation**: Add `fileData`, `originalFilename`, `fileExtension`, `mimeType` fields
- **Deliverable**: Struct has new optional fields, existing extractors unchanged

### Step 3: Update `BookmarkItem` model
- **File**: `Shared/Models/BookmarkItem.swift`
- **Operation**: Add `originalFilename: String?` and `mimeType: String?` properties
- **Deliverable**: Model has new fields (SwiftData auto-migration for optionals)

### Step 4: Create `FileExtractor`
- **File**: `ShareExtension/ContentExtractors/FileExtractor.swift` (new)
- **Operation**: Create extractor that handles `.item`, `.data`, `.fileURL` UTTypes
- Extract original filename from provider
- Map UTType to file extension and MIME type
- Load file data
- **Deliverable**: Generic files can be captured

### Step 5: Update `PDFExtractor` to use new fields
- **File**: `ShareExtension/ContentExtractors/PDFExtractor.swift`
- **Operation**: Set `fileData`, `fileExtension = "pdf"`, `mimeType`, `originalFilename`
- **Deliverable**: PDFs use the unified file storage path

### Step 6: Register `FileExtractor` in registry
- **File**: `ShareExtension/ContentExtractors/ContentExtractorRegistry.swift`
- **Operation**: Add `FileExtractor()` as second-to-last (before `TextExtractor`)
- Order: PDF → Image → URL → **File** → Text
- **Deliverable**: Generic files are now captured by Share Extension

### Step 7: Update `ShareViewController.saveContent()` for unified file storage
- **File**: `ShareExtension/ShareViewController.swift`
- **Operation**: Replace image-only save with unified save that handles any file type
- Use proper file extension instead of hardcoded `.jpg`
- Save `originalFilename` and `mimeType` to item
- **Deliverable**: All file types stored in `media/` with correct extensions

### Step 8: Add `resolvedMediaURL` computed property to `BookmarkItem`
- **File**: `Shared/Models/BookmarkItem.swift`
- **Operation**: Add computed property that resolves relative `mediaPath` to absolute `URL`
- **Deliverable**: Any view can get the full file URL for QuickLook/sharing

### Step 9: Replace fragmented open button with QuickLook
- **File**: `Resurface/Views/Detail/BookmarkDetailView.swift`
- **Operation**:
  - Add `@State private var showQuickLook = false`
  - Replace `openOriginalButton` with unified version
  - For URL content: keep `Link(destination:)` to open in Safari
  - For file content: use `.quickLookPreview()` modifier or `QLPreviewController` wrapper
  - Show **both** buttons when item has URL AND local file
- **Deliverable**: One-tap opens any file type natively

### Step 10: Add export actions to toolbar menu
- **File**: `Resurface/Views/Detail/BookmarkDetailView.swift`
- **Operation**: Add "Export File" ShareLink and "Save to Photos" button in toolbar menu
- **Deliverable**: Users can export stored files to Files app or Camera Roll

### Step 11: Update `ImageExtractor` to use proper file extension
- **File**: `ShareExtension/ContentExtractors/ImageExtractor.swift`
- **Operation**: Set `fileExtension` based on actual image type (jpg, png, heic) instead of always `.jpg`
- Set `originalFilename` and `mimeType`
- **Deliverable**: Images stored with correct extensions

## Key Files

| File | Operation | Description |
|------|-----------|-------------|
| `Shared/Models/ContentType.swift` | Modify | Add `file` case |
| `Shared/Models/BookmarkItem.swift` | Modify | Add `originalFilename`, `mimeType`, `resolvedMediaURL` |
| `ShareExtension/ContentExtractors/ContentExtractor.swift` | Modify | Add fields to `ExtractedContent` |
| `ShareExtension/ContentExtractors/FileExtractor.swift` | **Create** | New generic file extractor |
| `ShareExtension/ContentExtractors/ContentExtractorRegistry.swift` | Modify | Register `FileExtractor` |
| `ShareExtension/ContentExtractors/PDFExtractor.swift` | Modify | Use new `fileData`/`fileExtension` fields |
| `ShareExtension/ContentExtractors/ImageExtractor.swift` | Modify | Use proper extensions + new fields |
| `ShareExtension/ShareViewController.swift` | Modify | Unified file save logic |
| `Resurface/Views/Detail/BookmarkDetailView.swift` | Modify | QuickLook + unified open button + export |

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Share Extension 120MB memory limit with large files | Check file size before loading into memory; for files >50MB, save directly from file URL without loading into `Data` |
| QuickLook may not support exotic file types | Falls back to system's default behavior (offer to open in another app) |
| SwiftData migration for new model fields | New fields are optional (`String?`), SwiftData handles lightweight migration automatically |
| Existing bookmarks won't have `originalFilename`/`mimeType` | These are optional; UI gracefully handles nil values |
| File extension detection from UTType | Use `UTType.preferredFilenameExtension` which covers all system-known types |

## Architecture Notes

- **QuickLook** is the iOS-native file preview framework — it handles 100+ file types with zero custom code
- **No custom viewers needed** — QuickLook replaces `ImagePreviewView` and the PDF `ShareLink` approach
- The `FileExtractor` is intentionally broad (`.item` UTType) to catch anything the specific extractors miss
- File storage uses UUID-based naming to avoid collisions, but preserves `originalFilename` for display
