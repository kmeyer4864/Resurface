# Resurface - Planning Document

## Project Genesis

This document captures the full planning conversation and decisions made during the design phase of Resurface.

---

## The Problem Statement

### User's Words
> "The core problem I'm trying to solve is the innate desire I have when doing things on my phone to want to save content and come back to it later but then I never end up doing it. If I had one universal place to do it that used AI to make all of my content easier to find/access when I want to see it again this would be helpful."

### The Insight
Saving content provides **instant gratification** — the act of saving feels productive ("I'll become a better person by reading this later"). But when "later" comes, the brain prefers the easy dopamine of **new content** over the effort of reviewing saved content.

Current behavior:
- Save content → feel good → never return
- Content scattered across: bookmarks, screenshots, notes, reminders, multiple apps
- Backlog becomes overwhelming → avoid it entirely
- New content always wins over saved content

### Content Types Most Saved
1. Self-help / personal development
2. Educational articles and videos
3. Health-related content
4. Anything that doesn't give instant gratification but "feels good to save"

---

## The Solution

### Core Concept
**One universal inbox** accessible via iOS Share Sheet that:
1. Captures anything with zero friction (1 tap)
2. Uses AI to automatically organize (no manual work)
3. Resurfaces content intelligently (competes with doomscrolling)

### Key Design Decisions

#### Capture Experience
**Decision: Instant save, no UI**
- User taps Share → selects Resurface → content saved immediately
- No preview, no note field, no category selection
- AI handles all organization in background
- Exception: TikTok/Instagram videos require brief user input (description + category)

#### Main Screen Design
**Decision: Library view (B) with search (C) and AI picks (D)**
- Primary: Organized library browsable by topic
- Secondary: Search box for finding specific items
- Tertiary: AI-curated "picks for you" section
- NOT a chronological feed (avoids infinite scroll pattern)

#### Organization Philosophy
**Decision: Multi-dimensional AI classification**
- By topic: Health, Finance, Recipes, Work, etc.
- By intent: To read, To buy, To try, Reference
- By source: X, Reddit, Screenshots, Safari
- By type: Article, Video, Image, Thread, Product
- All dimensions available for filtering, not mutually exclusive

#### Reward Mechanism
**Decision: Just good content, well-presented**
- No gamification (streaks, badges, scores)
- No guilt-inducing metrics ("you've only reviewed 5%")
- Focus on making the content itself compelling
- AI picks should feel like discovery, not homework

---

## Technical Decisions

### Platform & Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Platform | iOS native | User's primary use case is iPhone |
| UI Framework | SwiftUI | Modern, declarative, rapid iteration |
| Data | SwiftData | Native Swift, automatic iCloud sync, type-safe |
| Min iOS | iOS 17+ | Required for SwiftData, @Observable |
| AI - Cloud | Claude API | Best reasoning for categorization/extraction |
| AI - On-Device | Apple Vision/NaturalLanguage | Free, private, fast for OCR |

### Video Content Strategy

**MVP Approach:**
- YouTube: Full support (transcripts available via API)
- TikTok/Instagram: Limited support
  - Extract caption and thumbnail
  - Require user to provide: short description + category
  - Full video AI analysis deferred to post-MVP

**Future Option (Premium Feature):**
- Use Twelve Labs or Gemini for video understanding
- Can analyze visual content, audio, actions
- Trade-off: Cost (~$0.05-0.10/video), processing time (30-60s)

### AI Cost Estimation

| Operation | Model | Cost per 1K operations |
|-----------|-------|------------------------|
| Content analysis | Claude Haiku | $0.38 |
| Summarization | Claude Sonnet | $0.90 |
| Embeddings | OpenAI ada-002 | $0.10 |

**Estimated monthly cost per active user: $2-5** (50 saves/month)

---

## Feature Scope

### MVP (Phases 1-2)

**Must Have:**
- Share Extension captures URLs and images
- Instant save with no UI
- Web page metadata extraction (title, favicon, description)
- OCR for screenshots (on-device)
- YouTube video support with transcripts
- AI categorization and tagging
- Basic full-text search
- Category and tag filtering
- Library view with topics

**Explicitly Deferred:**
- Daily/weekly digests (revisit post-MVP)
- Social/sharing features (revisit post-MVP)
- Video AI for TikTok/Instagram
- Mac app
- Browser extension

### Future Phases

**Phase 3: Enhanced Features**
- Semantic search (natural language queries)
- On-demand summarization
- Related items suggestions
- Smart collections

**Phase 5: Polish**
- iCloud sync across devices
- Home screen widget
- Onboarding flow
- App Store preparation

---

## User Experience Flows

### Primary Flow: Capture

```
User browsing X
    ↓
Sees interesting thread
    ↓
Taps Share → Resurface icon
    ↓
Brief checkmark animation → auto-dismiss
    ↓
(Background) AI processes content
    ↓
Item appears in library, categorized
```

### Primary Flow: Retrieval

```
User opens Resurface
    ↓
Sees "AI Picks for You" section
    ↓
Taps on item from 2 weeks ago
    ↓
Views full content with AI summary
    ↓
Optionally taps to open original source
```

### Search Flow

```
User opens Resurface
    ↓
Taps search bar
    ↓
Types "that article about habits"
    ↓
AI finds relevant items (not just keyword match)
    ↓
User finds the item they were looking for
```

---

## Success Vision

> "6 months from now I am spending more time going through my curated list of content and less time discovering new content. This leads me to remember more of the things that I like, leading me to try new things, have better habits, spend less time doomscrolling and more time on the good content."

### Success Metrics
- User returns to app 3+ times per week
- User "opens" (views/acts on) saved content, not just saves it
- Time spent in app reviewing content > time spent saving
- User saves content more frequently (knowing they'll actually use it)

---

## Competitive Positioning

### Direct Competitors

| App | Focus | Gap vs Resurface |
|-----|-------|--------------|
| Rodeo | Events/planning from screenshots | Not general content, no resurfacing |
| Mymind | Visual AI bookmarking | Browser-centric, no resurfacing |
| Raindrop.io | Structured bookmarks | Manual organization, desktop-first |
| Readwise Reader | Articles + highlights | Not universal (no screenshots, social) |

### Resurface Differentiation
1. **Universal capture** via native Share Sheet (not browser extension)
2. **Multi-dimensional AI** (topic + intent + source + type)
3. **Active resurfacing** (AI surfaces content to you)
4. **Mobile-first** (iOS-native from day one)
5. **Solves the real problem** (why you don't return, not just organization)

---

## Open Questions

### Resolved
- [x] Name: **Resurface**
- [x] Capture UX: Instant, no UI
- [x] Main screen: Library with search and AI picks
- [x] Gamification: No
- [x] Video AI: Defer to post-MVP
- [x] Digests: Defer to post-MVP
- [x] Social features: Defer to post-MVP

### To Be Decided Later
- [ ] Monetization model (free tier limits, subscription pricing)
- [ ] Account requirement (anonymous local-only option?)
- [ ] Specific category taxonomy
- [ ] AI model selection for embeddings

---

## Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| Phase 1 | 2-3 weeks | Foundation (Share Extension, data layer, basic UI) |
| Phase 2 | 2-3 weeks | AI Integration (categorization, tagging, search) |
| Phase 3 | 2-3 weeks | Enhanced Features (semantic search, summaries) |
| Phase 5 | 2 weeks | Polish (sync, widget, App Store) |

**Total MVP: ~8-11 weeks**

---

*Document created: March 2026*
*Last updated: March 2026*
