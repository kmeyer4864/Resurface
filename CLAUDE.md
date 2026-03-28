# CLAUDE.md - Resurface Project Instructions

## Project Overview

Resurface is a native iOS app that serves as a universal AI-powered bookmark folder. Users capture content via iOS Share Sheet from anywhere on their phone, AI automatically organizes it, and the app helps resurface content so users actually return to what they saved.

## Key Concepts

### The Core Insight
Users get instant gratification from *saving* content (feels productive), but never *return* to it because new content is more stimulating. The app must make reviewing saved content compete with doomscrolling.

### Design Principles
1. **Zero friction capture** - Share Extension completes in <1 second, no user input required
2. **AI does the work** - No manual categorization, tagging, or filing
3. **Library, not a to-do list** - Present content for discovery, not as a backlog
4. **Multi-dimensional organization** - Classify by topic, intent, source, type (not just one)

## Architecture

### Targets
- `Resurface` - Main iOS app (SwiftUI)
- `ShareExtension` - iOS Share Extension
- `Shared` - Framework shared between app and extension
- `WidgetExtension` - Home screen widget (Phase 5)

### Data Sharing
App and Share Extension share data via App Group container:
- `group.com.keenanmeyer.resurface`
- SwiftData database in shared container
- Media files (images, PDFs) in shared Documents folder

### AI Integration
- **On-device (free)**: Apple Vision for OCR, NaturalLanguage for basic NLP
- **Cloud (Claude API)**: Categorization, tagging, insight extraction, semantic embeddings
- Processing happens in background after share completes

## Code Style

### SwiftUI Conventions
- Use `@Observable` (iOS 17+) over `@ObservableObject`
- Prefer `@State` and `@Binding` over view models for simple views
- Extract reusable components to separate files
- Use SF Symbols for icons

### SwiftData Conventions
- Models in `Models/` directory
- Use `@Model` macro
- Configure relationships explicitly
- Handle migrations for schema changes

### Service Layer
- Services are structs with static methods or actors for async work
- Use dependency injection via environment
- Errors are typed enums conforming to `Error`

## Content Type Handling

### Supported Types (MVP)
| Type | Priority | AI Processing |
|------|----------|---------------|
| URLs/Articles | P0 | Full text extraction, summarization |
| Screenshots | P0 | OCR, AI categorization |
| YouTube | P0 | Transcript via API, full AI processing |
| Images | P1 | Vision description, categorization |
| Text snippets | P1 | Direct AI processing |
| PDFs | P2 | Text extraction, summarization |

### Video Content (TikTok/Instagram)
MVP approach: Extract available metadata + require user input
- Caption/description from URL
- Thumbnail if available
- **User provides**: Short description + category selection
- Full video AI analysis deferred to post-MVP

## API Keys & Secrets

**Never commit secrets to the repository.**

Required API keys:
- `CLAUDE_API_KEY` - For AI processing

Store in:
- Xcode environment variables for development
- Keychain for production

## Testing

- Unit tests for services and models
- UI tests for critical flows
- Test Share Extension with various content types
- Test offline behavior

## Common Tasks

### Adding a New Content Extractor
1. Create new file in `ShareExtension/ContentExtractors/`
2. Conform to `ContentExtractor` protocol
3. Register in `ContentExtractorRegistry`
4. Add UTType to Share Extension Info.plist

### Adding a New AI Processing Step
1. Add method to `Shared/Services/AI/ContentAnalyzer.swift`
2. Update processing queue to include new step
3. Add fields to `BookmarkItem` model if needed
4. Update UI to display new data

### Debugging Share Extension
- Use Xcode's "Attach to Process by PID or Name"
- Check Console.app for extension logs
- Memory limit is 120MB - defer heavy processing to main app

## File Locations

| What | Where |
|------|-------|
| SwiftData models | `Resurface/Models/` |
| Main app views | `Resurface/Views/` |
| Share Extension | `ShareExtension/` |
| Shared services | `Shared/Services/` |
| AI services | `Shared/Services/AI/` |
| Documentation | `docs/` |

## Current Phase: 2 (AI Integration) - Ready to Start

### Phase 1 Completed:
- [x] Project setup
- [x] App Group configuration
- [x] SwiftData models (BookmarkItem, Category, Tag, WebContent)
- [x] Share Extension basic capture (URLs, images, text)
- [x] Main app list view with category filtering
- [x] URL metadata extraction (LinkPresentation + HTML fallback)
- [x] Thumbnail generation (OG images, favicons, YouTube thumbnails)
- [x] Background processing pipeline
- [x] Network monitoring for offline support
- [x] Cross-process notifications (Share Extension → Main App)

### Phase 2 Focus (AI Integration):
- [ ] Claude API integration for categorization
- [ ] Tag generation
- [ ] Key insights extraction
- [ ] Content summarization

Do NOT work on:
- Semantic search (Phase 3)
- Digests (Phase 4 - deferred)
- iCloud sync (Phase 5)
