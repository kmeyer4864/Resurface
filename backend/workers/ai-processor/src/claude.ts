import { AnalyzeRequest, AnalyzeResponse, Env } from './types';
import { buildSystemPrompt, buildUserPrompt } from './prompts';
import { validateResponse } from './validation';

const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';
const CLAUDE_MODEL = 'claude-sonnet-4-20250514';
const MAX_TOKENS = 1024;

export interface ClaudeError {
  error: string;
  code: string;
  status?: number;
}

export async function analyzeContent(
  content: AnalyzeRequest,
  apiKey: string
): Promise<AnalyzeResponse | ClaudeError> {
  const userPrompt = buildUserPrompt(content);
  const systemPrompt = buildSystemPrompt(content);

  // Log the prompts for debugging
  console.log('=== AI ANALYSIS REQUEST ===');
  console.log('Category Context:', {
    name: content.categoryName || '(none)',
    description: content.categoryDescription || '(none)',
    prompt: content.categoryPrompt || '(none)',
  });
  console.log('--- SYSTEM PROMPT ---');
  console.log(systemPrompt);
  console.log('--- USER PROMPT ---');
  console.log(userPrompt);
  console.log('========================');

  try {
    const response = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: MAX_TOKENS,
        messages: [
          {
            role: 'user',
            content: userPrompt,
          },
        ],
        system: systemPrompt,
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      console.error('Claude API error:', response.status, errorBody);

      if (response.status === 429) {
        return { error: 'Rate limited', code: 'RATE_LIMITED', status: 429 };
      }

      if (response.status === 401) {
        return { error: 'Invalid API key', code: 'UNAUTHORIZED', status: 401 };
      }

      return {
        error: `Claude API error: ${response.status}`,
        code: 'CLAUDE_ERROR',
        status: response.status,
      };
    }

    const data = await response.json() as {
      content: Array<{ type: string; text?: string }>;
    };

    // Extract text from response
    const textContent = data.content?.find(c => c.type === 'text');
    if (!textContent?.text) {
      return { error: 'Empty response from Claude', code: 'EMPTY_RESPONSE' };
    }

    // Parse JSON response
    let parsed: unknown;
    try {
      // Claude sometimes wraps JSON in markdown code blocks
      let jsonText = textContent.text.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.slice(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.slice(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.slice(0, -3);
      }
      parsed = JSON.parse(jsonText.trim());
    } catch (e) {
      console.error('Failed to parse Claude response:', textContent.text);
      return { error: 'Failed to parse AI response', code: 'PARSE_ERROR' };
    }

    // Validate and normalize response
    const validated = validateResponse(parsed);
    if ('error' in validated) {
      console.log('=== VALIDATION ERROR ===');
      console.log(validated);
      return validated;
    }

    // Log the successful response
    console.log('=== AI ANALYSIS RESPONSE ===');
    console.log('Suggested Title:', validated.suggestedTitle || '(not provided)');
    console.log('Category:', validated.category);
    console.log('Tags:', validated.tags);
    console.log('Key Insights:', validated.keyInsights);
    console.log('Extracted Fields:', validated.extractedFields || '(none)');
    console.log('Confidence:', validated.confidence);
    console.log('============================');

    return validated;
  } catch (e) {
    console.error('Claude API exception:', e);
    return {
      error: e instanceof Error ? e.message : 'Unknown error',
      code: 'NETWORK_ERROR',
    };
  }
}
