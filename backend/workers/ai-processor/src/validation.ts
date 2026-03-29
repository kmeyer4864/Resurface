import { AnalyzeRequest, AnalyzeResponse, CATEGORIES, CONTENT_SUBTYPES } from './types';

export interface ValidationError {
  error: string;
  code: string;
}

export function validateRequest(body: unknown): AnalyzeRequest | ValidationError {
  if (!body || typeof body !== 'object') {
    return { error: 'Request body must be a JSON object', code: 'INVALID_BODY' };
  }

  const req = body as Record<string, unknown>;

  // Required fields
  if (!req.contentType || typeof req.contentType !== 'string') {
    return { error: 'contentType is required and must be a string', code: 'MISSING_CONTENT_TYPE' };
  }

  if (!req.title || typeof req.title !== 'string') {
    return { error: 'title is required and must be a string', code: 'MISSING_TITLE' };
  }

  // Sanitize and build request
  const sanitized: AnalyzeRequest = {
    contentType: sanitizeText(req.contentType as string, 50),
    title: sanitizeText(req.title as string, 500),
  };

  if (req.url && typeof req.url === 'string') {
    sanitized.url = sanitizeText(req.url, 2000);
  }

  if (req.rawText && typeof req.rawText === 'string') {
    sanitized.rawText = sanitizeText(req.rawText, 5000);
  }

  if (req.siteName && typeof req.siteName === 'string') {
    sanitized.siteName = sanitizeText(req.siteName, 200);
  }

  if (req.imageDescription && typeof req.imageDescription === 'string') {
    sanitized.imageDescription = sanitizeText(req.imageDescription, 1000);
  }

  // Category context for "lens" processing
  if (req.categoryName && typeof req.categoryName === 'string') {
    sanitized.categoryName = sanitizeText(req.categoryName, 100);
  }

  if (req.categoryDescription && typeof req.categoryDescription === 'string') {
    sanitized.categoryDescription = sanitizeText(req.categoryDescription, 500);
  }

  if (req.categoryPrompt && typeof req.categoryPrompt === 'string') {
    sanitized.categoryPrompt = sanitizeText(req.categoryPrompt, 1000);
  }

  return sanitized;
}

export function validateResponse(response: unknown): AnalyzeResponse | ValidationError {
  if (!response || typeof response !== 'object') {
    return { error: 'Invalid AI response format', code: 'INVALID_RESPONSE' };
  }

  const res = response as Record<string, unknown>;

  // Validate category
  if (!res.category || typeof res.category !== 'string') {
    return { error: 'Missing category in response', code: 'MISSING_CATEGORY' };
  }

  const category = res.category as string;
  if (!CATEGORIES.includes(category as any)) {
    // Try to find closest match
    const closest = findClosestCategory(category);
    res.category = closest;
  }

  // Validate tags
  if (!Array.isArray(res.tags)) {
    res.tags = [];
  }
  const tags = (res.tags as unknown[])
    .filter((t): t is string => typeof t === 'string')
    .map(t => t.toLowerCase().replace(/[^a-z0-9-]/g, ''))
    .filter(t => t.length > 0)
    .slice(0, 8);

  // Validate keyInsights
  if (!Array.isArray(res.keyInsights)) {
    res.keyInsights = [];
  }
  const keyInsights = (res.keyInsights as unknown[])
    .filter((k): k is string => typeof k === 'string')
    .map(k => k.slice(0, 150))
    .slice(0, 5);

  // Validate contentSubtype
  let contentSubtype = 'other';
  if (res.contentSubtype && typeof res.contentSubtype === 'string') {
    const subtype = res.contentSubtype.toLowerCase();
    if (CONTENT_SUBTYPES.includes(subtype as any)) {
      contentSubtype = subtype;
    }
  }

  // Validate confidence
  let confidence = 0.5;
  if (typeof res.confidence === 'number') {
    confidence = Math.max(0, Math.min(1, res.confidence));
  }

  // Validate suggestedTitle (new field)
  let suggestedTitle: string | undefined;
  if (res.suggestedTitle && typeof res.suggestedTitle === 'string') {
    suggestedTitle = res.suggestedTitle.slice(0, 200).trim();
  }

  // Validate extractedFields (new field - dynamic key-value pairs)
  let extractedFields: Record<string, string> | undefined;
  if (res.extractedFields && typeof res.extractedFields === 'object' && !Array.isArray(res.extractedFields)) {
    extractedFields = {};
    const fields = res.extractedFields as Record<string, unknown>;
    for (const [key, value] of Object.entries(fields)) {
      if (typeof value === 'string' || typeof value === 'number') {
        // Sanitize key and value
        const cleanKey = key.slice(0, 50).trim();
        const cleanValue = String(value).slice(0, 500).trim();
        if (cleanKey && cleanValue) {
          extractedFields[cleanKey] = cleanValue;
        }
      }
    }
    // Only include if we have at least one field
    if (Object.keys(extractedFields).length === 0) {
      extractedFields = undefined;
    }
  }

  return {
    category: res.category as string,
    tags,
    keyInsights,
    contentSubtype,
    confidence,
    suggestedTitle,
    extractedFields,
  };
}

function sanitizeText(text: string, maxLength: number): string {
  return text
    .replace(/<[^>]*>/g, '') // Strip HTML
    .replace(/[\x00-\x1F\x7F]/g, ' ') // Remove control characters
    .trim()
    .slice(0, maxLength);
}

function findClosestCategory(input: string): string {
  const lower = input.toLowerCase();

  for (const category of CATEGORIES) {
    if (category.toLowerCase() === lower) {
      return category;
    }
  }

  // Simple fuzzy match
  for (const category of CATEGORIES) {
    if (category.toLowerCase().includes(lower) || lower.includes(category.toLowerCase())) {
      return category;
    }
  }

  return 'Reference'; // Default fallback
}
