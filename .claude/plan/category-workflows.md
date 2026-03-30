# Implementation Plan: User-Defined Category Workflows

## Task Type
- [x] Backend (→ AI lens integration)
- [x] Frontend (→ Share Extension UI, Category creation)
- [x] Fullstack (→ End-to-end flow)

## Overview

Transform Resurface from auto-categorization to **user-defined workflow buckets**. Users create categories with custom AI prompts, select category at share time, and optionally schedule "resurface" notifications.

## Architecture Change

```
BEFORE:
Share → Auto-save → AI auto-categorizes

AFTER:
Share → Category Picker Card → Save with category → AI processes through category "lens"
              ↓
      Resurface time picker
              ↓
      Schedule notification (optional)
```

## Data Model Changes

### Category (Revised)

```swift
@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String              // "HSA Receipts"
    var emoji: String             // "🧾" (actual emoji, not SF Symbol)
    var description: String       // "Medical bills, receipts, EOBs"
    var aiPrompt: String          // "Extract: date, amount, provider..."
    var isDefault: Bool           // Only one true at a time
    var isArchived: Bool          // Hidden but data preserved
    var createdAt: Date
    var sortOrder: Int            // For manual ordering

    @Relationship(deleteRule: .nullify, inverse: \BookmarkItem.category)
    var items: [BookmarkItem] = []
}
```

**Migration**: Delete all existing categories, seed one "Universal Folder" category.

### BookmarkItem (Add resurface fields)

```swift
// Add to BookmarkItem:
var resurfaceAt: Date?            // When to notify (nil = never)
var resurfaceNotificationId: String?  // For cancellation
```

### ResurfaceOption Enum

```swift
enum ResurfaceOption: String, CaseIterable {
    case never
    case laterToday      // +6 hours
    case tomorrow        // Next day 9am
    case nextWeek        // +7 days 9am
    case nextMonth       // +30 days 9am
    case nextYear        // +365 days 9am

    var displayName: String { ... }

    func targetDate(from now: Date) -> Date? {
        // Returns nil for .never
    }
}
```

---

## Implementation Steps

### Phase A: Category Model Overhaul

#### Step A1: Update Category Model
**File**: `Shared/Models/Category.swift`

- Remove: `icon` (SF Symbol), `color`, `isSystem`
- Add: `emoji`, `description`, `aiPrompt`, `isDefault`, `isArchived`, `sortOrder`
- Remove `systemCategories` static property

**Deliverable**: Updated Category model

#### Step A2: Update CategorySeeder
**File**: `Shared/Services/Data/CategorySeeder.swift`

- Delete all existing categories on first run of new version
- Seed single "Universal Folder" category:
  ```swift
  Category(
      name: "Universal Folder",
      emoji: "📁",
      description: "A catch-all for anything you want to save",
      aiPrompt: "Categorize this content and extract key information.",
      isDefault: true
  )
  ```

**Deliverable**: Clean migration to new category system

#### Step A3: Add Resurface Fields to BookmarkItem
**File**: `Shared/Models/BookmarkItem.swift`

- Add `resurfaceAt: Date?`
- Add `resurfaceNotificationId: String?`

**Deliverable**: BookmarkItem supports resurface scheduling

#### Step A4: Create ResurfaceOption Enum
**File**: `Shared/Models/ResurfaceOption.swift` (new)

- Enum with all time options
- `targetDate(from:)` method
- Display names

**Deliverable**: Resurface time options defined

---

### Phase B: Category Creation UI

#### Step B1: Category Creation View
**File**: `Resurface/Views/Categories/CategoryCreationView.swift` (new)

UI Flow:
1. Name input
2. Emoji picker (grid of common emojis + keyboard)
3. Description input ("What will you use this for?")
4. AI prompt (auto-generated from description, editable)
5. Save button

Prompt guidance text:
> "Based on your description, we've created a prompt for the AI. You can customize what to extract or focus on."

**Deliverable**: Full category creation screen

#### Step B2: Emoji Picker Component
**File**: `Resurface/Views/Components/EmojiPicker.swift` (new)

- Grid of ~50 common emojis
- Keyboard input option
- Recently used

**Deliverable**: Reusable emoji picker

#### Step B3: AI Prompt Generator
**File**: `Shared/Services/AI/PromptGenerator.swift` (new)

```swift
actor PromptGenerator {
    static func generatePrompt(from description: String) -> String {
        // Template-based generation
        // e.g., "For [description], extract relevant details..."
    }
}
```

**Deliverable**: Auto-generate prompt from description

#### Step B4: Update Settings - Category Management
**File**: `Resurface/Views/Settings/SettingsView.swift`

- List user categories (not archived)
- Set default category
- Edit category
- Archive category
- Reorder categories

**Deliverable**: Full category management in settings

---

### Phase C: Share Extension Redesign

#### Step C1: Share Extension Category Picker
**File**: `ShareExtension/Views/CategoryPickerCard.swift` (new)

```
┌─────────────────────────────────────┐
│  Save to Resurface                  │
├─────────────────────────────────────┤
│  📁 Universal Folder    ✓           │
│  🧾 HSA Receipts                    │
│  💡 Date Ideas                      │
│  ＋ New Category...                 │
├─────────────────────────────────────┤
│  Resurface this?                    │
│  [Never ▼]                          │
├─────────────────────────────────────┤
│          [ Save ]                   │
└─────────────────────────────────────┘
```

**Deliverable**: New share extension UI

#### Step C2: Update ShareViewController
**File**: `ShareExtension/ShareViewController.swift`

- Present CategoryPickerCard instead of instant save
- Pass selected category ID to BookmarkItem
- Pass resurface option
- Handle "New Category" → open main app with deep link

**Deliverable**: Share extension uses new flow

#### Step C3: Deep Link for Category Creation
**File**: `Resurface/ResurfaceApp.swift`

- Handle URL scheme: `resurface://create-category?pendingContentId=XXX`
- After category creation, save pending content to new category

**Deliverable**: Seamless "create category" from share extension

#### Step C4: Resurface Time Picker Component
**File**: `ShareExtension/Views/ResurfaceTimePicker.swift` (new)

- Dropdown or segmented picker
- Options: Never, Later Today, Tomorrow, Next Week, Next Month, Next Year
- Default: Never

**Deliverable**: Time picker for share card

---

### Phase D: AI Lens Integration

#### Step D1: Update Backend Types
**File**: `backend/workers/ai-processor/src/types.ts`

```typescript
interface AnalyzeRequest {
    // existing fields...
    categoryName?: string;       // "HSA Receipts"
    categoryDescription?: string; // "Medical bills..."
    categoryPrompt?: string;     // "Extract: date, amount..."
}
```

**Deliverable**: Backend accepts category context

#### Step D2: Update Backend Prompts
**File**: `backend/workers/ai-processor/src/prompts.ts`

Modify SYSTEM_PROMPT to incorporate category context:
```
You are analyzing content saved to the category "${categoryName}".
Category purpose: ${categoryDescription}
User instructions: ${categoryPrompt}

Focus ONLY on information relevant to this category's purpose.
Ignore unrelated content in the same source.
```

**Deliverable**: AI processes through category "lens"

#### Step D3: Update iOS API Client
**File**: `Shared/Services/AI/AIAnalysisTypes.swift`

Add category fields to `AIAnalysisRequest`:
```swift
struct AIAnalysisRequest: Codable {
    // existing...
    let categoryName: String?
    let categoryDescription: String?
    let categoryPrompt: String?
}
```

**Deliverable**: iOS sends category context to backend

#### Step D4: Update AIContentProcessor
**File**: `Shared/Services/AI/AIContentProcessor.swift`

- Include category context when building request
- Remove auto-categorization (category already selected by user)

**Deliverable**: AI processor uses category lens

---

### Phase E: Resurface Notifications

#### Step E1: Notification Service
**File**: `Shared/Services/Notifications/ResurfaceNotificationService.swift` (new)

```swift
actor ResurfaceNotificationService {
    static let shared = ResurfaceNotificationService()

    func scheduleNotification(for item: BookmarkItem) async -> String?
    func cancelNotification(id: String) async
    func requestPermission() async -> Bool
}
```

**Deliverable**: Local notification scheduling

#### Step E2: Notification Content
- Title: "Time to resurface!"
- Body: Item title (truncated)
- Deep link to item detail

**Deliverable**: Notification displays item info

#### Step E3: Handle Notification Tap
**File**: `Resurface/ResurfaceApp.swift`

- Handle notification tap → navigate to item detail
- Mark as "resurfaced"

**Deliverable**: Tapping notification opens item

#### Step E4: Request Notification Permission
**File**: `Resurface/ResurfaceApp.swift`

- Request on first use of resurface feature
- Show explanation before requesting

**Deliverable**: Permission flow

---

### Phase F: UI Cleanup

#### Step F1: Update BookmarkCard
**File**: `Resurface/Views/Components/BookmarkCard.swift`

- Show emoji instead of SF Symbol for category
- Remove color-based styling (or derive from emoji)

**Deliverable**: Cards show emoji categories

#### Step F2: Update BookmarkDetailView
**File**: `Resurface/Views/Detail/BookmarkDetailView.swift`

- Show category with emoji
- Show resurface time if set
- Allow editing resurface time

**Deliverable**: Detail view shows resurface info

#### Step F3: Update Library/Home Views
- Filter by category with emoji
- Show resurface indicators

**Deliverable**: Consistent emoji category display

---

## File Summary

### New Files (10)
| File | Purpose |
|------|---------|
| `Shared/Models/ResurfaceOption.swift` | Resurface time enum |
| `Resurface/Views/Categories/CategoryCreationView.swift` | Create category screen |
| `Resurface/Views/Components/EmojiPicker.swift` | Emoji selection |
| `Shared/Services/AI/PromptGenerator.swift` | Generate AI prompt from description |
| `ShareExtension/Views/CategoryPickerCard.swift` | Share extension UI |
| `ShareExtension/Views/ResurfaceTimePicker.swift` | Time picker component |
| `Shared/Services/Notifications/ResurfaceNotificationService.swift` | Local notifications |

### Modified Files (12)
| File | Changes |
|------|---------|
| `Shared/Models/Category.swift` | New fields, remove system categories |
| `Shared/Models/BookmarkItem.swift` | Add resurface fields |
| `Shared/Services/Data/CategorySeeder.swift` | Seed Universal Folder only |
| `ShareExtension/ShareViewController.swift` | New UI flow |
| `Resurface/ResurfaceApp.swift` | Deep links, notification handling |
| `Resurface/Views/Settings/SettingsView.swift` | Category management |
| `Resurface/Views/Components/BookmarkCard.swift` | Emoji display |
| `Resurface/Views/Detail/BookmarkDetailView.swift` | Resurface info |
| `Shared/Services/AI/AIAnalysisTypes.swift` | Category context fields |
| `Shared/Services/AI/AIContentProcessor.swift` | Use category lens |
| `backend/workers/ai-processor/src/types.ts` | Category context |
| `backend/workers/ai-processor/src/prompts.ts` | Category-aware prompts |

---

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Share Extension memory limits | Keep picker UI lightweight, defer heavy ops to main app |
| Deep link reliability | Test thoroughly on device, handle edge cases |
| Notification permissions denied | Graceful degradation, explain value before asking |
| Migration breaks existing data | Start fresh (pre-launch), clean slate |

---

## Success Criteria

- [ ] User can create category with emoji + description + AI prompt
- [ ] Share extension shows category picker card
- [ ] User can select resurface time at share
- [ ] AI processes content through category "lens"
- [ ] Notifications fire at scheduled time
- [ ] Tapping notification opens item
- [ ] Categories manageable in settings
- [ ] "Create new category" from share extension works

---

## SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: N/A
- GEMINI_SESSION: N/A
