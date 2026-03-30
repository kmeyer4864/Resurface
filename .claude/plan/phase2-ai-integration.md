# Implementation Plan: Phase 2 - AI Integration

## Overview

Add AI-powered content analysis via a Cloudflare Worker backend. The iOS app sends content to the backend during background processing, which calls Claude API for categorization, tagging, and insight extraction.

## Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────┐
│   iOS App       │────▶│  Cloudflare Worker   │────▶│  Claude API │
│ (BackgroundProc)│◀────│  (resurface-ai)      │◀────│  (Haiku)    │
└─────────────────┘     └──────────────────────┘     └─────────────┘
```

**Key Decisions:**
- No user-configurable API keys
- Claude API key stored in Worker secrets only
- Graceful degradation when offline/unavailable

## Cost Estimate (50 users)

| Component | Free Tier | Estimated Usage |
|-----------|-----------|-----------------|
| Cloudflare Workers | 100K req/day | ~500 req/day |
| Claude API (Haiku) | Paid | ~$5-15/month |

## Implementation Phases

### Phase 1: Backend (Cloudflare Worker)

| File | Purpose |
|------|---------|
| `backend/workers/ai-processor/wrangler.toml` | Worker config |
| `backend/workers/ai-processor/src/index.ts` | Main handler |
| `backend/workers/ai-processor/src/types.ts` | Request/response types |
| `backend/workers/ai-processor/src/claude.ts` | Claude API client |
| `backend/workers/ai-processor/src/prompts.ts` | AI prompts |
| `backend/workers/ai-processor/src/validation.ts` | Input validation |

**Endpoints:**
- `POST /analyze` - Analyze content, return category/tags/insights
- `GET /health` - Health check

### Phase 2: iOS API Client

| File | Purpose |
|------|---------|
| `Shared/Services/AI/AIAnalysisTypes.swift` | Request/response models |
| `Shared/Services/AI/ResurfaceAPIClient.swift` | HTTP client with retry |
| `Shared/Services/AI/AIContentProcessor.swift` | Orchestrates AI flow |
| `Shared/Models/AIProcessingStatus.swift` | Processing status enum |

### Phase 3: Integration

| File | Changes |
|------|---------|
| `Shared/Services/Processing/BackgroundProcessor.swift` | Add AI step after metadata |
| `Shared/Models/BookmarkItem.swift` | Add aiProcessingStatus, aiConfidence |

### Phase 4: Categories & Tags

| File | Changes |
|------|---------|
| `Shared/Models/Category.swift` | Expand to 18 system categories |
| `Shared/Services/Data/CategorySeeder.swift` | Seed on first launch |
| `Resurface/ResurfaceApp.swift` | Call seeder |

### Phase 5: UI Updates

| File | Changes |
|------|---------|
| `Resurface/Views/Settings/SettingsView.swift` | Remove API Configuration |
| `Resurface/Views/Detail/BookmarkDetailView.swift` | Show AI status/confidence |
| `Resurface/Views/Components/ContentSubtypeBadge.swift` | New badge component |
| `Resurface/Views/Components/BookmarkCard.swift` | Show subtype badge |

### Phase 6: Error Handling

| File | Changes |
|------|---------|
| `Shared/Services/AI/ResurfaceAPIClient.swift` | Exponential backoff |
| `Resurface/ResurfaceApp.swift` | Retry on network return |

## Predefined Categories (18)

| Category | Icon | Color |
|----------|------|-------|
| Health | heart.fill | #FF2D55 |
| Finance | dollarsign.circle.fill | #34C759 |
| Tech | cpu.fill | #5856D6 |
| Career | briefcase.fill | #FF9500 |
| Learning | book.fill | #007AFF |
| Entertainment | tv.fill | #AF52DE |
| Shopping | cart.fill | #FF3B30 |
| Travel | airplane | #00C7BE |
| Food | fork.knife | #FFCC00 |
| News | newspaper.fill | #8E8E93 |
| Lifestyle | sparkles | #FF6B6B |
| Sports | sportscourt.fill | #32D74B |
| Science | atom | #64D2FF |
| Art | paintpalette.fill | #BF5AF2 |
| Music | music.note | #FF375F |
| Gaming | gamecontroller.fill | #30D158 |
| Social | person.2.fill | #5E5CE6 |
| Reference | books.vertical.fill | #AC8E68 |

## AI Response Format

```json
{
  "category": "Tech",
  "tags": ["swift", "ios", "swiftui", "tutorial"],
  "keyInsights": [
    "Explains @Observable macro usage",
    "Covers iOS 17+ features",
    "Includes code examples"
  ],
  "contentSubtype": "tutorial",
  "confidence": 0.92
}
```

## Content Subtypes

- article, thread, recipe, product, tutorial
- news, review, discussion, video, podcast
- tool, reference, other

## Success Criteria

- [ ] Backend deployed (`/health` returns 200)
- [ ] 90%+ items categorized within 60 seconds
- [ ] Offline items processed when network returns
- [ ] No API keys in iOS app
- [ ] Categories display on cards
- [ ] Tags are searchable
- [ ] Key insights in detail view
- [ ] <5% backend error rate

## File Summary

### New Files (7 iOS + 6 Backend)

**iOS:**
1. `Shared/Services/AI/AIAnalysisTypes.swift`
2. `Shared/Services/AI/ResurfaceAPIClient.swift`
3. `Shared/Services/AI/AIContentProcessor.swift`
4. `Shared/Models/AIProcessingStatus.swift`
5. `Shared/Services/Data/CategorySeeder.swift`
6. `Resurface/Views/Components/ContentSubtypeBadge.swift`

**Backend:**
1. `backend/workers/ai-processor/wrangler.toml`
2. `backend/workers/ai-processor/package.json`
3. `backend/workers/ai-processor/src/index.ts`
4. `backend/workers/ai-processor/src/types.ts`
5. `backend/workers/ai-processor/src/claude.ts`
6. `backend/workers/ai-processor/src/prompts.ts`

### Modified Files (7)

1. `Shared/Models/BookmarkItem.swift` - AI fields
2. `Shared/Models/Category.swift` - More categories
3. `Shared/Services/Processing/BackgroundProcessor.swift` - AI step
4. `Resurface/ResurfaceApp.swift` - Seeding, retry
5. `Resurface/Views/Settings/SettingsView.swift` - Remove API config
6. `Resurface/Views/Detail/BookmarkDetailView.swift` - AI status
7. `Resurface/Views/Components/BookmarkCard.swift` - Subtype badge
