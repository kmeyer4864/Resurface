# Implementation Plan: Phase 2 - Deploy & Test AI Integration

## Task Type
- [x] Backend (→ Cloudflare Worker deployment)
- [x] iOS (→ Integration testing)
- [x] Fullstack (→ End-to-end verification)

## Overview

Deploy the Cloudflare Worker backend and test the complete AI integration pipeline:
1. Deploy worker with Claude API key
2. Verify health endpoint
3. Test AI analysis endpoint
4. Run iOS app to verify end-to-end flow

## Technical Context

### Current State
- **Backend**: Fully implemented in `backend/workers/ai-processor/`
- **iOS Client**: `ResurfaceAPIClient` configured for `resurface-ai.keenanmeyer25.workers.dev`
- **Wrangler**: Authenticated as `keenanmeyer25@gmail.com`

### Architecture
```
iOS App → ResurfaceAPIClient → Cloudflare Worker → Claude API
                                   ↓
                          /analyze endpoint
                          - Validates request
                          - Calls Claude claude-sonnet-4-20250514
                          - Returns category, tags, insights
```

## Implementation Steps

### Step 1: Set Claude API Secret
**Action**: Configure CLAUDE_API_KEY in Cloudflare Worker secrets

```bash
cd backend/workers/ai-processor
npx wrangler secret put CLAUDE_API_KEY
# When prompted, paste your Anthropic API key
```

**Expected Result**: Secret stored securely in Cloudflare

---

### Step 2: Deploy Worker
**Action**: Deploy to Cloudflare Workers

```bash
cd backend/workers/ai-processor
npm run deploy
```

**Expected Result**:
- Worker deployed to `https://resurface-ai.keenanmeyer25.workers.dev`
- Console shows deployment success

---

### Step 3: Verify Health Endpoint
**Action**: Test the health check endpoint

```bash
curl https://resurface-ai.keenanmeyer25.workers.dev/health
```

**Expected Response**:
```json
{"status":"ok","timestamp":"2026-03-28T..."}
```

---

### Step 4: Test Analyze Endpoint
**Action**: Send a test analysis request

```bash
curl -X POST https://resurface-ai.keenanmeyer25.workers.dev/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "contentType": "article",
    "title": "How to Build iOS Apps with SwiftUI",
    "url": "https://developer.apple.com/tutorials",
    "rawText": "SwiftUI is a modern framework for building user interfaces across all Apple platforms.",
    "siteName": "Apple Developer"
  }'
```

**Expected Response**:
```json
{
  "category": "Tech",
  "tags": ["swift", "ios", "swiftui", "apple", "tutorial"],
  "keyInsights": [
    "Covers SwiftUI framework basics",
    "Apple's official documentation",
    "Cross-platform UI development"
  ],
  "contentSubtype": "tutorial",
  "confidence": 0.9
}
```

---

### Step 5: Test Error Handling
**Action**: Verify error responses work correctly

```bash
# Test missing required field
curl -X POST https://resurface-ai.keenanmeyer25.workers.dev/analyze \
  -H "Content-Type: application/json" \
  -d '{"contentType": "article"}'

# Expected: {"error":"title is required...","code":"MISSING_TITLE"}
```

---

### Step 6: iOS Integration Test
**Action**: Build and run iOS app, share content to test AI processing

1. Open Xcode project: `open Resurface.xcodeproj`
2. Build and run on device/simulator (iOS 17+)
3. Use Safari to share a URL via Share Sheet to Resurface
4. Open Resurface app
5. Verify:
   - Item appears in library
   - AI processing status shows "Analyzing" then "Analyzed"
   - Category is assigned
   - Tags appear
   - Key insights shown in detail view

---

### Step 7: Verify Offline Graceful Degradation
**Action**: Test behavior when network unavailable

1. Enable Airplane Mode on device
2. Share a URL via Share Sheet
3. Open Resurface app
4. Verify:
   - Item is saved (metadata still pending)
   - AI status shows "Pending"
5. Disable Airplane Mode
6. Verify:
   - App retries AI processing
   - Status updates to "Analyzed"

---

## Key Files

| File | Purpose |
|------|---------|
| `backend/workers/ai-processor/wrangler.toml` | Worker config |
| `backend/workers/ai-processor/src/index.ts` | Main handler |
| `Shared/Services/AI/ResurfaceAPIClient.swift` | iOS HTTP client |
| `Shared/Services/Processing/BackgroundProcessor.swift` | AI processing orchestration |

## Verification Checklist

- [ ] Worker deployed successfully
- [ ] `/health` returns 200 OK
- [ ] `/analyze` returns valid categorization
- [ ] iOS app receives and displays AI analysis
- [ ] Offline items are queued and processed when online
- [ ] Error states handled gracefully
- [ ] Categories display on bookmark cards
- [ ] Tags appear in detail view
- [ ] Key insights shown

## Troubleshooting

### Worker not deploying
- Check `npx wrangler whoami` shows logged in
- Run `npm install` to ensure dependencies

### 500 errors from /analyze
- Verify CLAUDE_API_KEY is set: `npx wrangler secret list`
- Check Cloudflare dashboard logs for details

### iOS not connecting
- Verify URL in `ResurfaceAPIClient.swift` matches deployed worker
- Check device has network connectivity
- Look for errors in Xcode console

### AI analysis returning wrong categories
- Check `prompts.ts` SYSTEM_PROMPT
- Verify CATEGORIES in `types.ts` matches iOS `Category.systemCategories`

## Cost Considerations

| Service | Free Tier | Est. Usage |
|---------|-----------|------------|
| Cloudflare Workers | 100K req/day | ~500 req/day |
| Claude claude-sonnet-4-20250514 | Paid | ~$5-15/month |

---

## SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: N/A (No external model calls needed)
- GEMINI_SESSION: N/A (No external model calls needed)
