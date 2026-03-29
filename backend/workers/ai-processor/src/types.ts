// Request from iOS app
export interface AnalyzeRequest {
  contentType: string;       // url, article, screenshot, youtube, etc.
  title: string;
  url?: string;
  rawText?: string;          // Description, extracted text
  siteName?: string;
  imageDescription?: string; // For screenshots/images (future: Vision API)

  // Category context for "lens" processing
  categoryName?: string;        // User's category name (e.g., "HSA Receipts")
  categoryDescription?: string; // What the category is used for
  categoryPrompt?: string;      // User's custom AI instructions
}

// Response to iOS app
export interface AnalyzeResponse {
  category: string;          // Must match predefined list
  tags: string[];            // 3-8 tags
  keyInsights: string[];     // 2-5 bullet points
  contentSubtype: string;    // article, thread, recipe, product, etc.
  confidence: number;        // 0.0-1.0

  // New fields for enhanced content understanding
  suggestedTitle: string;    // Clean, human-readable title (always generated)
  extractedFields?: Record<string, string>; // Category-specific key-value data
}

// Error response
export interface ErrorResponse {
  error: string;
  code: string;
}

// Cloudflare Worker environment
export interface Env {
  CLAUDE_API_KEY: string;
  APP_SECRET?: string;
  ENVIRONMENT: string;
}

// Predefined categories - must match iOS Category.systemCategories
export const CATEGORIES = [
  'Health',
  'Finance',
  'Tech',
  'Career',
  'Learning',
  'Entertainment',
  'Shopping',
  'Travel',
  'Food',
  'News',
  'Lifestyle',
  'Sports',
  'Science',
  'Art',
  'Music',
  'Gaming',
  'Social',
  'Reference',
] as const;

export type Category = typeof CATEGORIES[number];

// Content subtypes
export const CONTENT_SUBTYPES = [
  'article',
  'thread',
  'recipe',
  'product',
  'tutorial',
  'news',
  'review',
  'discussion',
  'video',
  'podcast',
  'tool',
  'reference',
  'other',
] as const;

export type ContentSubtype = typeof CONTENT_SUBTYPES[number];
