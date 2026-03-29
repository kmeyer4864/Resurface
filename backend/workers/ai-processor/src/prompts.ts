import { CATEGORIES, CONTENT_SUBTYPES, AnalyzeRequest } from './types';

// Base system prompt without category context
const BASE_SYSTEM_PROMPT = `You are a content analyzer for a bookmark/read-later app called Resurface. Your job is to analyze saved content and extract relevant information.

Respond with a JSON object containing:

1. suggestedTitle: A clean, human-readable title (REQUIRED)
   - 3-8 words, concise and descriptive
   - Never use file paths, UUIDs, or technical names
   - Examples: "Headway Therapy Invoice", "React Performance Guide", "Weekend Trip to Denver"

2. category: One of these exact values: ${CATEGORIES.join(', ')}
   - Choose the SINGLE most relevant category based on the content

3. tags: 3-8 relevant tags
   - Lowercase, no special characters
   - Specific and descriptive
   - Include topic, format, and key themes

4. keyInsights: 2-5 concise bullet points
   - Each max 100 characters
   - Capture the main value/takeaways
   - Help user remember why they saved it

5. contentSubtype: One of: ${CONTENT_SUBTYPES.join(', ')}
   - article: long-form written content
   - thread: social media thread (Twitter/X, Reddit)
   - recipe: cooking instructions
   - product: item for purchase
   - tutorial: step-by-step guide
   - news: current events
   - review: opinion/analysis of something
   - discussion: forum/comment discussion
   - video: video content
   - podcast: audio content
   - tool: software, app, or utility
   - reference: documentation, wiki, reference material
   - other: doesn't fit other categories

6. confidence: 0.0-1.0
   - How confident you are in the analysis
   - Lower if content is ambiguous or lacks context

Respond ONLY with valid JSON. No markdown, no explanation.`;

// Build system prompt with optional category context
export function buildSystemPrompt(content: AnalyzeRequest): string {
  // If no category context, use base prompt
  if (!content.categoryName && !content.categoryDescription && !content.categoryPrompt) {
    return BASE_SYSTEM_PROMPT;
  }

  // Build category-aware prompt
  let categoryContext = '';

  if (content.categoryName) {
    categoryContext += `\n\nIMPORTANT CONTEXT: The user has saved this content to their "${content.categoryName}" category.`;
  }

  if (content.categoryDescription) {
    categoryContext += `\n\nCategory purpose: ${content.categoryDescription}`;
  }

  if (content.categoryPrompt) {
    categoryContext += `\n\nUser's custom instructions for this category:\n${content.categoryPrompt}`;
  }

  categoryContext += `\n\n**CRITICAL INSTRUCTIONS**:

You are analyzing this content through the lens of the user's "${content.categoryName}" folder. Think about what information would be most valuable for someone using this folder for "${content.categoryDescription || content.categoryName}".

1. **suggestedTitle**: Create a title that's meaningful for THIS category
   - For receipts: include provider and amount (e.g., "Headway Therapy - $100")
   - For date ideas: include place and vibe (e.g., "Rooftop Bar - Downtown Denver")
   - For recipes: include dish name (e.g., "Grandma's Chocolate Chip Cookies")
   - Make it scannable and useful when browsing the folder

2. **extractedFields**: Extract the details that matter for THIS category's purpose
   - Think: "What would someone using this folder want to know at a glance?"
   - Be specific and practical - extract actual values, not generic descriptions
   - Use clear, human-readable field names
   - Adapt completely to the content and category - no fixed schema

   Examples of intelligent extraction:
   - Medical receipt → Provider, Amount, Date, Service Type, Payment Status
   - Restaurant recommendation → Name, Location, Price Range, Best For, Hours
   - Product to buy → Price, Where to Buy, Rating, Key Features
   - Travel article → Destination, Best Time to Visit, Budget, Must-See Spots
   - Recipe → Prep Time, Cook Time, Servings, Difficulty, Key Ingredients
   - Gift idea → Price, For Whom, Where to Get, Why It's Good

3. **keyInsights**: Provide 2-4 actionable insights relevant to this category
   - Not generic observations, but useful takeaways
   - "The provider accepts HSA cards" > "This is a PDF document"
   - "Best visited during happy hour 4-6pm" > "This is a restaurant"

4. **tags**: Include category-relevant tags that help with filtering and search`;

  return BASE_SYSTEM_PROMPT + categoryContext;
}

// Legacy export for backward compatibility
export const SYSTEM_PROMPT = BASE_SYSTEM_PROMPT;

export function buildUserPrompt(content: AnalyzeRequest): string {
  const parts: string[] = [];

  parts.push(`Content Type: ${content.contentType}`);
  parts.push(`Title: ${content.title}`);

  if (content.url) {
    parts.push(`URL: ${content.url}`);
  }

  if (content.siteName) {
    parts.push(`Site: ${content.siteName}`);
  }

  if (content.rawText) {
    // Limit text to ~2000 chars to stay within token limits
    const text = content.rawText.slice(0, 2000);
    parts.push(`Content:\n${text}`);
  }

  if (content.imageDescription) {
    parts.push(`Image Description: ${content.imageDescription}`);
  }

  return parts.join('\n\n');
}
