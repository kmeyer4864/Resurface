# Resurface AI Worker

Cloudflare Worker that handles AI-powered content analysis for the Resurface iOS app.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Login to Cloudflare:
   ```bash
   npx wrangler login
   ```

3. Set your Claude API key:
   ```bash
   npx wrangler secret put CLAUDE_API_KEY
   # Paste your Anthropic API key when prompted
   ```

4. Deploy:
   ```bash
   npm run deploy
   ```

5. Note your worker URL (e.g., `https://resurface-ai.your-subdomain.workers.dev`)

## Development

Run locally:
```bash
npm run dev
```

## API

### POST /analyze

Analyze content and return categorization.

**Request:**
```json
{
  "contentType": "article",
  "title": "How to Build iOS Apps with SwiftUI",
  "url": "https://example.com/article",
  "rawText": "This tutorial covers...",
  "siteName": "Example Blog"
}
```

**Response:**
```json
{
  "category": "Tech",
  "tags": ["swift", "ios", "swiftui", "tutorial"],
  "keyInsights": [
    "Covers iOS 17+ features",
    "Includes code examples",
    "Explains @Observable macro"
  ],
  "contentSubtype": "tutorial",
  "confidence": 0.92
}
```

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-03-28T10:00:00.000Z"
}
```

## Cost

- Cloudflare Workers: Free tier (100K requests/day)
- Claude Haiku: ~$0.25 per 1M input tokens, ~$1.25 per 1M output tokens
- Estimated: ~$5-15/month for 50 users with moderate usage
