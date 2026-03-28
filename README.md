# Resurface

**Your AI-Powered Content Memory**

Save anything from anywhere. AI organizes it. Actually come back to it.

## The Problem

You frequently encounter content on your phone that sparks "I want to save this for later" — but:
- Deciding *where* to save it creates friction
- Content gets scattered across different apps (bookmarks, screenshots, notes, reminders)
- You rarely return to saved content because new content is more stimulating
- The saved content becomes a graveyard

## The Solution

**One universal inbox** that:
1. **Captures anything** via iOS Share Sheet (zero friction, 1 tap)
2. **AI does the organizing** (no manual filing, categorization, or tagging)
3. **Resurfaces content intelligently** (so you actually use it)

## Key Features

- **Universal Capture**: Share Extension works from any app (Safari, X, Instagram, Reddit, YouTube, Photos, etc.)
- **AI Organization**: Automatic categorization, tagging, and insight extraction
- **Smart Resurfacing**: AI picks relevant content to show you, not just chronological lists
- **Semantic Search**: Find content by meaning, not just keywords ("that article about sleep")
- **Multi-dimensional Filtering**: By topic, intent, source, content type, or time

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI |
| Data | SwiftData + SQLite |
| AI (Cloud) | Claude API |
| AI (On-Device) | Apple Vision (OCR), NaturalLanguage |
| Sync | iCloud via CloudKit |

## Project Structure

```
Resurface/
├── Resurface/                      # Main App Target
│   ├── Models/                 # SwiftData models
│   ├── Views/                  # SwiftUI views
│   ├── ViewModels/             # View models
│   └── Services/               # Business logic
├── ShareExtension/             # Share Extension Target
│   └── ContentExtractors/      # Content type handlers
├── Shared/                     # Shared Framework
│   └── Services/               # Shared services (AI, storage)
├── WidgetExtension/            # Widget Target (Phase 5)
└── docs/                       # Documentation
    ├── PLANNING.md             # Full planning context
    ├── ARCHITECTURE.md         # Technical architecture
    ├── REQUIREMENTS.md         # User requirements
    └── COMPETITIVE_ANALYSIS.md # Market research
```

## Development Phases

| Phase | Scope | Status |
|-------|-------|--------|
| 1. Foundation | Share Extension + basic list view | 🚧 In Progress |
| 2. AI Integration | Categorization, tagging, search | ⏳ Planned |
| 3. Enhanced Features | Semantic search, summarization | ⏳ Planned |
| 4. Digests | Daily/weekly AI summaries | ⏳ Deferred |
| 5. Polish | iCloud sync, widget, onboarding | ⏳ Planned |

## Getting Started

### Prerequisites

- macOS with Xcode 15+
- iOS 17+ deployment target
- Apple Developer Account (for device testing)
- Claude API key (for AI features)

### Setup

1. Clone the repository
2. Open `Resurface.xcodeproj` in Xcode
3. Configure your development team in Signing & Capabilities
4. Add your Claude API key to the environment or config
5. Build and run on simulator or device

## License

Private - All rights reserved
