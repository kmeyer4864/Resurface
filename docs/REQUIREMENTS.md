# Resurface - Requirements Document

## User Stories

### Epic 1: Content Capture

#### US1.1: Universal Share
**As a** user browsing content on my phone,
**I want to** save any content to one place with a single tap,
**So that** I don't have to think about where to put it.

**Acceptance Criteria:**
- [ ] Share Extension appears in iOS Share Sheet
- [ ] Works from any app that supports sharing
- [ ] Completes in under 1 second
- [ ] Shows brief success confirmation
- [ ] Auto-dismisses after save

#### US1.2: URL Capture
**As a** user sharing a web link,
**I want to** have the article content automatically extracted,
**So that** I can read it later even if offline.

**Acceptance Criteria:**
- [ ] Captures URL from any browser or app
- [ ] Fetches page title, description, favicon
- [ ] Extracts main article text (when possible)
- [ ] Generates thumbnail from OG image or screenshot

#### US1.3: Screenshot Capture
**As a** user taking screenshots of information,
**I want to** have the text automatically extracted,
**So that** I can search for it later.

**Acceptance Criteria:**
- [ ] Accepts images shared from Photos or screenshot
- [ ] Runs OCR to extract text
- [ ] Detects if image is a screenshot
- [ ] Stores both image and extracted text

#### US1.4: YouTube Video Capture
**As a** user saving YouTube videos,
**I want to** have the transcript analyzed,
**So that** I can search and get insights without rewatching.

**Acceptance Criteria:**
- [ ] Detects YouTube URLs
- [ ] Fetches video metadata (title, channel, description)
- [ ] Retrieves transcript via YouTube API
- [ ] Generates thumbnail
- [ ] Processes transcript for insights

#### US1.5: Social Media Video Capture (MVP Limited)
**As a** user saving TikTok or Instagram content,
**I want to** still save it with some context,
**So that** I can find it later.

**Acceptance Criteria:**
- [ ] Detects TikTok/Instagram URLs
- [ ] Extracts available metadata (caption, thumbnail)
- [ ] Prompts user for brief description
- [ ] Prompts user to select category
- [ ] Saves link and user-provided context

---

### Epic 2: AI Organization

#### US2.1: Automatic Categorization
**As a** user who saves diverse content,
**I want to** have content automatically categorized,
**So that** I can browse by topic without manual filing.

**Acceptance Criteria:**
- [ ] AI assigns 1 primary category per item
- [ ] Categories are predefined but flexible
- [ ] User can manually override category
- [ ] Categorization happens in background

#### US2.2: Automatic Tagging
**As a** user searching for specific content,
**I want to** have relevant tags generated,
**So that** I can find content through multiple paths.

**Acceptance Criteria:**
- [ ] AI generates 3-8 tags per item
- [ ] Tags are derived from content, not predefined
- [ ] Similar tags are consolidated (e.g., "habit" and "habits")
- [ ] User can add/remove tags manually

#### US2.3: Key Insights Extraction
**As a** user with limited time,
**I want to** see the key points of saved content,
**So that** I can decide if I want to engage deeper.

**Acceptance Criteria:**
- [ ] AI extracts 2-5 key insights per item
- [ ] Insights are shown on item detail view
- [ ] Insights are useful without reading full content

#### US2.4: Content Type Detection
**As a** user with diverse content,
**I want to** see what type of content each item is,
**So that** I can filter by format.

**Acceptance Criteria:**
- [ ] AI detects subtype (article, thread, recipe, product, tutorial, etc.)
- [ ] Subtype displayed on item card
- [ ] Filterable by subtype

---

### Epic 3: Content Retrieval

#### US3.1: Library View
**As a** user returning to saved content,
**I want to** browse my library by topic,
**So that** I can explore what I've saved.

**Acceptance Criteria:**
- [ ] Main screen shows topics/categories grid
- [ ] Tapping topic shows items in that category
- [ ] Recently saved section visible
- [ ] Can filter by multiple dimensions

#### US3.2: Search
**As a** user looking for specific content,
**I want to** search by keywords,
**So that** I can find what I'm looking for.

**Acceptance Criteria:**
- [ ] Search box on main screen
- [ ] Full-text search across title, text, tags
- [ ] Results ranked by relevance
- [ ] Search is fast (< 200ms)

#### US3.3: AI Picks
**As a** user who forgets what they saved,
**I want to** see AI-surfaced relevant content,
**So that** I rediscover valuable items.

**Acceptance Criteria:**
- [ ] "AI Picks for You" section on home
- [ ] Shows 3-5 items selected by AI
- [ ] Selection considers recency, relevance, engagement
- [ ] Refreshes periodically

#### US3.4: Item Detail View
**As a** user engaging with saved content,
**I want to** see the full content and insights,
**So that** I can consume or act on it.

**Acceptance Criteria:**
- [ ] Shows title, source, date saved
- [ ] Shows AI-generated insights
- [ ] Shows category and tags
- [ ] Link to open original source
- [ ] For articles: shows extracted text
- [ ] For images: shows full image

---

### Epic 4: Settings & Management

#### US4.1: Archive Items
**As a** user with old content,
**I want to** archive items I'm done with,
**So that** my active library stays fresh.

**Acceptance Criteria:**
- [ ] Swipe to archive
- [ ] Archived items hidden from main view
- [ ] Can view archived items in settings
- [ ] Can unarchive

#### US4.2: Delete Items
**As a** user who saved something by mistake,
**I want to** delete items,
**So that** they don't clutter my library.

**Acceptance Criteria:**
- [ ] Swipe to delete
- [ ] Confirmation before permanent delete
- [ ] Deletes associated media files

#### US4.3: Favorite Items
**As a** user with important content,
**I want to** mark favorites,
**So that** I can quickly access my best saves.

**Acceptance Criteria:**
- [ ] Tap to favorite
- [ ] Favorites section available
- [ ] Favorites appear in AI picks more often

---

## Non-Functional Requirements

### Performance

| Requirement | Target |
|-------------|--------|
| Share Extension perceived latency | < 1 second |
| App cold start | < 2 seconds |
| Search response | < 200ms |
| AI processing | < 30 seconds per item |
| Offline browsing | All saved content available |

### Reliability

| Requirement | Target |
|-------------|--------|
| Crash rate | < 0.1% of sessions |
| Data loss | 0% (local persistence) |
| AI processing success rate | > 95% |
| Share Extension success rate | > 99% |

### Security

- No hardcoded API keys
- Keychain storage for sensitive data
- App Group data is sandboxed
- HTTPS for all network requests

### Privacy

- Content processed via Claude API (user consent required)
- No third-party analytics in MVP
- User data stays in their iCloud account
- Option for local-only mode (future)

---

## Content Type Matrix

| Content Type | Capture | Extract Text | AI Analysis | Priority |
|--------------|---------|--------------|-------------|----------|
| URLs (articles) | Share Sheet | Web scrape | Full | P0 |
| Screenshots | Share Sheet | OCR | Full | P0 |
| YouTube videos | Share Sheet | Transcript API | Full | P0 |
| Images | Share Sheet | Vision describe | Limited | P1 |
| Plain text | Share Sheet | Direct | Full | P1 |
| PDFs | Share Sheet | PDF extract | Full | P2 |
| TikTok | Share Sheet | Caption only | Limited + user input | P2 |
| Instagram | Share Sheet | Caption only | Limited + user input | P2 |

---

## Category Taxonomy (Initial)

| Category | Icon | Example Content |
|----------|------|-----------------|
| Health | heart.fill | Fitness, nutrition, sleep, mental health |
| Finance | dollarsign.circle.fill | Investing, budgeting, money advice |
| Personal Development | sparkles | Habits, productivity, self-help |
| Technology | desktopcomputer | Tech news, tutorials, tools |
| Work | briefcase.fill | Career, business, professional |
| Food | fork.knife | Recipes, restaurants, cooking |
| Entertainment | play.circle.fill | Movies, TV, games, music |
| News | newspaper.fill | Current events, journalism |
| Travel | airplane | Destinations, travel tips |
| Shopping | bag.fill | Products, deals, wishlists |
| Reference | book.fill | Tutorials, guides, documentation |
| Other | folder.fill | Uncategorized |

Categories are system-defined but can be extended based on usage patterns.
