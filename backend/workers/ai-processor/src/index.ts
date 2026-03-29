import { Env, AnalyzeResponse, ErrorResponse } from './types';
import { validateRequest } from './validation';
import { analyzeContent } from './claude';

// Simple in-memory rate limiting (resets on worker restart)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 100; // requests per minute
const RATE_WINDOW = 60 * 1000; // 1 minute

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // CORS headers for all responses
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-App-Bundle-Id',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Health check endpoint
    if (url.pathname === '/health' && request.method === 'GET') {
      return jsonResponse({ status: 'ok', timestamp: new Date().toISOString() }, 200, corsHeaders);
    }

    // Analyze endpoint
    if (url.pathname === '/analyze' && request.method === 'POST') {
      return handleAnalyze(request, env, corsHeaders);
    }

    // 404 for unknown routes
    return jsonResponse({ error: 'Not found', code: 'NOT_FOUND' }, 404, corsHeaders);
  },
};

async function handleAnalyze(
  request: Request,
  env: Env,
  corsHeaders: Record<string, string>
): Promise<Response> {
  // Check API key is configured
  if (!env.CLAUDE_API_KEY) {
    console.error('CLAUDE_API_KEY not configured');
    return jsonResponse(
      { error: 'Server configuration error', code: 'CONFIG_ERROR' },
      500,
      corsHeaders
    );
  }

  // Rate limiting by IP
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  const rateLimitResult = checkRateLimit(clientIP);
  if (!rateLimitResult.allowed) {
    return jsonResponse(
      { error: 'Rate limit exceeded', code: 'RATE_LIMITED' },
      429,
      {
        ...corsHeaders,
        'Retry-After': String(Math.ceil(rateLimitResult.retryAfter / 1000)),
      }
    );
  }

  // Parse request body
  let body: unknown;
  try {
    body = await request.json();
  } catch (e) {
    return jsonResponse(
      { error: 'Invalid JSON body', code: 'INVALID_JSON' },
      400,
      corsHeaders
    );
  }

  // Validate request
  const validationResult = validateRequest(body);
  if ('error' in validationResult) {
    return jsonResponse(validationResult, 400, corsHeaders);
  }

  // Call Claude API
  const result = await analyzeContent(validationResult, env.CLAUDE_API_KEY);

  if ('error' in result) {
    const status = result.status || 500;
    return jsonResponse(
      { error: result.error, code: result.code },
      status,
      corsHeaders
    );
  }

  // Success
  return jsonResponse(result, 200, corsHeaders);
}

function checkRateLimit(clientIP: string): { allowed: boolean; retryAfter: number } {
  const now = Date.now();
  const existing = rateLimitMap.get(clientIP);

  // Clean up expired entries periodically
  if (Math.random() < 0.01) {
    for (const [key, value] of rateLimitMap.entries()) {
      if (value.resetAt < now) {
        rateLimitMap.delete(key);
      }
    }
  }

  if (!existing || existing.resetAt < now) {
    // New window
    rateLimitMap.set(clientIP, { count: 1, resetAt: now + RATE_WINDOW });
    return { allowed: true, retryAfter: 0 };
  }

  if (existing.count >= RATE_LIMIT) {
    return { allowed: false, retryAfter: existing.resetAt - now };
  }

  existing.count++;
  return { allowed: true, retryAfter: 0 };
}

function jsonResponse(
  data: AnalyzeResponse | ErrorResponse | { status: string; timestamp: string },
  status: number,
  headers: Record<string, string>
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}
