# Implementation Plan: Phase 1 Completion - URL Metadata, Thumbnails, and Data Flow

## Overview

Complete Phase 1 of the Resurface iOS app by implementing URL metadata extraction (title, description, favicon), thumbnail generation for URLs and images, and verifying the data flow from Share Extension to Main App.

## Task Type
- [x] Backend (data services, processing)
- [x] Frontend (UI updates for thumbnails)
- [x] Fullstack

## Architecture

### Two-Phase Processing Model

```
Share Extension (Fast, <120MB)     Main App (Background Processing)
┌─────────────────────────┐        ┌────────────────────────────────┐
│ 1. Extract URL/Image    │        │ 1. Detect pending items        │
│ 2. Save raw content     │   →    │ 2. Fetch URL metadata          │
│ 3. Set status: pending  │        │ 3. Generate thumbnails         │
│ 4. Dismiss immediately  │        │ 4. Set status: completed       │
└─────────────────────────┘        └────────────────────────────────┘
```

### Technical Solution

1. **Metadata Extraction**: Use `LinkPresentation` framework (LPMetadataProvider) with HTML parsing fallback
2. **Thumbnail Generation**: Download OG images/favicons for URLs, downscale saved images
3. **Background Processing**: Process pending items on app launch and when returning from background
4. **Offline Support**: Queue items for later processing when network unavailable

## Implementation Steps

### Phase 1: Core Services (4 files)

#### Step 1. Create MetadataTypes
**File:** `Shared/Services/Metadata/MetadataTypes.swift`
- Define `URLMetadata` struct and `MetadataError` enum
- Expected deliverable: Type definitions for metadata extraction

#### Step 2. Implement LinkMetadataProvider
**File:** `Shared/Services/Metadata/LinkMetadataProvider.swift`
- Wrap `LPMetadataProvider` from LinkPresentation framework
- Uses 10s timeout, extracts imageProvider and iconProvider data
- Expected deliverable: Primary metadata fetcher

#### Step 3. Implement HTMLMetadataParser (Fallback)
**File:** `Shared/Services/Metadata/HTMLMetadataParser.swift`
- Parse HTML `<meta>` tags for Open Graph and standard metadata
- Extracts: og:title, og:description, og:image, `<title>`, `<meta name="description">`
- Expected deliverable: Fallback parser for blocked sites

#### Step 4. Create MetadataService Orchestrator
**File:** `Shared/Services/Metadata/MetadataService.swift`
- Coordinate LinkMetadataProvider and HTMLMetadataParser with fallback logic
- Try LinkMetadataProvider first (5s timeout), fall back to HTML parser
- Expected deliverable: Single entry point for metadata extraction

### Phase 2: Thumbnail Service (3 files)

#### Step 5. Create ImageResizer Utility
**File:** `Shared/Services/Thumbnail/ImageResizer.swift`
- Downscale images to thumbnail sizes (88px, 160px, 240px width)
- Returns JPEG data with 0.8 quality
- Expected deliverable: Reusable image resizing utility

#### Step 6. Create ThumbnailService
**File:** `Shared/Services/Thumbnail/ThumbnailService.swift`
- Generate and cache thumbnails for different content types
- For URLs: Download OG image or favicon, resize, save to thumbnails/
- For images: Load from mediaPath, resize, save to thumbnails/
- Expected deliverable: Central thumbnail management service

#### Step 7. Add YouTube Thumbnail Support
**File:** `Shared/Services/Thumbnail/YouTubeThumbnailProvider.swift`
- Extract video ID from YouTube URLs
- Construct thumbnail URL: `https://img.youtube.com/vi/{ID}/maxresdefault.jpg`
- Expected deliverable: YouTube-specific thumbnail provider

### Phase 3: Background Processing (2 files)

#### Step 8. Create BackgroundProcessor
**File:** `Shared/Services/Processing/BackgroundProcessor.swift`
- Process pending BookmarkItems in main app on launch
- Fetch metadata, generate thumbnail, update item, save
- Update status to .completed or .failed
- Expected deliverable: Background processing coordinator

#### Step 9. Integrate BackgroundProcessor into App Lifecycle
**File:** `Resurface/ResurfaceApp.swift` (modify)
- Trigger processing on app launch and returning from background
- Add .task for initial processing
- Add observer for didBecomeActiveNotification
- Expected deliverable: Integrated background processing

### Phase 4: Model Updates (2 files)

#### Step 10. Add Favicon Fields to WebContent Model
**File:** `Shared/Models/WebContent.swift` (modify)
- Add `faviconPath`, `ogImageURL`, `metadataFetchedAt` fields
- Expected deliverable: Extended WebContent model

#### Step 11. Add Processing Error Tracking to BookmarkItem
**File:** `Shared/Models/BookmarkItem.swift` (modify)
- Add `lastProcessingError`, `processingAttempts`, `lastProcessedAt` fields
- Expected deliverable: Processing status tracking

### Phase 5: UI Updates (2 files)

#### Step 12. Upgrade ThumbnailView
**File:** `Resurface/Views/Components/ThumbnailView.swift` (modify)
- Load actual thumbnail from `thumbnailPath` when available
- Fall back to current gradient+icon placeholder
- Use async loading with loading state
- Expected deliverable: Real thumbnail display

#### Step 13. Update BookmarkCard
**File:** `Resurface/Views/Components/BookmarkCard.swift` (modify)
- Pass `item.thumbnailPath` to ThumbnailView
- Expected deliverable: Connected thumbnail display

### Phase 6: Data Flow Verification (3 files)

#### Step 14. Add Darwin Notification for Share Extension
**File:** `Shared/Services/Notifications/ShareNotification.swift`
- Post Darwin notification when Share Extension saves content
- Wake main app to process immediately if running
- Expected deliverable: Cross-process notification

#### Step 15. Update ShareViewController
**File:** `ShareExtension/ShareViewController.swift` (modify)
- Post Darwin notification after successfully saving
- Expected deliverable: Integrated notification posting

#### Step 16. Create Integration Tests
**File:** `ResurfaceTests/DataFlowTests.swift`
- Test pending item processing, metadata updates, thumbnail generation
- Expected deliverable: Data flow test coverage

### Phase 7: Offline Support (2 files)

#### Step 17. Add NetworkMonitor Service
**File:** `Shared/Services/Network/NetworkMonitor.swift`
- Monitor network connectivity using NWPathMonitor
- Expected deliverable: Network status monitoring

#### Step 18. Update BackgroundProcessor for Offline
**File:** `Shared/Services/Processing/BackgroundProcessor.swift` (modify)
- Check network before processing
- Resume when connectivity returns
- Expected deliverable: Offline-aware processing

## Key Files

| File | Operation | Description |
|------|-----------|-------------|
| Shared/Services/Metadata/MetadataTypes.swift | Create | URLMetadata struct, MetadataError enum |
| Shared/Services/Metadata/LinkMetadataProvider.swift | Create | LPMetadataProvider wrapper |
| Shared/Services/Metadata/HTMLMetadataParser.swift | Create | Fallback HTML parser |
| Shared/Services/Metadata/MetadataService.swift | Create | Orchestrator with fallback |
| Shared/Services/Thumbnail/ImageResizer.swift | Create | Image downscaling utility |
| Shared/Services/Thumbnail/ThumbnailService.swift | Create | Thumbnail generation/caching |
| Shared/Services/Thumbnail/YouTubeThumbnailProvider.swift | Create | YouTube thumbnail URLs |
| Shared/Services/Processing/BackgroundProcessor.swift | Create | Pending item processor |
| Shared/Services/Notifications/ShareNotification.swift | Create | Darwin notifications |
| Shared/Services/Network/NetworkMonitor.swift | Create | Network monitoring |
| ResurfaceTests/DataFlowTests.swift | Create | Integration tests |
| Shared/Models/WebContent.swift | Modify | Add favicon/OG fields |
| Shared/Models/BookmarkItem.swift | Modify | Add processing tracking |
| Resurface/ResurfaceApp.swift | Modify | Integrate BackgroundProcessor |
| Resurface/Views/Components/ThumbnailView.swift | Modify | Load real thumbnails |
| ShareExtension/ShareViewController.swift | Modify | Post notification |

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| LPMetadataProvider blocked by websites | HTMLMetadataParser fallback, URL as fallback title |
| Memory pressure when processing many items | Process one at a time with autoreleasepool |
| Thumbnail storage consumption | JPEG 0.7 quality, max 240px width, cleanup deleted items |
| Network requests slow app launch | All processing async/non-blocking, immediate UI with pending indicator |
| SwiftData migration issues | All new fields optional with defaults |

## Success Criteria

- [ ] URLs shared from Safari display extracted page title within 5 seconds
- [ ] URL bookmarks show favicon or OG image as thumbnail
- [ ] Image bookmarks show downscaled thumbnail
- [ ] YouTube links show video thumbnail
- [ ] Items saved offline are processed when connectivity returns
- [ ] Share Extension completes in under 1 second
- [ ] Main app displays items saved by Share Extension without restart
- [ ] All unit tests pass with 80%+ coverage
- [ ] Memory usage stays under 100MB during processing

## File Summary

### New Files (11)
1. `Shared/Services/Metadata/MetadataTypes.swift`
2. `Shared/Services/Metadata/LinkMetadataProvider.swift`
3. `Shared/Services/Metadata/HTMLMetadataParser.swift`
4. `Shared/Services/Metadata/MetadataService.swift`
5. `Shared/Services/Thumbnail/ImageResizer.swift`
6. `Shared/Services/Thumbnail/ThumbnailService.swift`
7. `Shared/Services/Thumbnail/YouTubeThumbnailProvider.swift`
8. `Shared/Services/Processing/BackgroundProcessor.swift`
9. `Shared/Services/Notifications/ShareNotification.swift`
10. `Shared/Services/Network/NetworkMonitor.swift`
11. `ResurfaceTests/DataFlowTests.swift`

### Modified Files (5)
1. `Shared/Models/WebContent.swift`
2. `Shared/Models/BookmarkItem.swift`
3. `Resurface/ResurfaceApp.swift`
4. `Resurface/Views/Components/ThumbnailView.swift`
5. `ShareExtension/ShareViewController.swift`

## SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: N/A (wrapper unavailable)
- GEMINI_SESSION: N/A (wrapper unavailable)
- PLANNER_AGENT: ad6748f
