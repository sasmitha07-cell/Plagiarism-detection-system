import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const MODEL = 'gemini-3.5-flash' // Stable August 2026 model ID

console.log("Gemini Reasoning Edge Function (v3 Auditor) Initialized")

serve(async (req) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/json'
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const { action, payload } = await req.json()

    if (!GEMINI_API_KEY) {
        return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not configured' }), { headers, status: 500 })
    }

    let systemInstruction = `You are a clinical Academic Integrity Auditor. Your role is to evaluate raw mathematical evidence and determine the risk of plagiarism.
    CRITICAL RULES:
    1. ZERO HALLUCINATION: Only report on sources provided in the Evidence Data.
    2. IGNORE COMMON PHRASES: Do not flag expressions like "The results suggest that" or "Further research is needed".
    3. DISCOVERY VS VERIFIED: If evidence has high overlap (>60%), mark as CRITICAL or HIGH. If overlap is low, mark as SAFE.
    4. ACCURACY: If the Evidence Data is empty, the overall_similarity_score MUST be 0.`;

    let prompt = '';

    switch (action) {
      case 'analyze-plagiarism':
        prompt = `
Analyze this Evidence Data for a document.
Determine the weighted similarity score based on the signals provided (EXACT, SEMANTIC, WEB).

Document Text for Context:
"""
${payload.text}
"""

Evidence Data:
${JSON.stringify(payload.evidence)}

Respond ONLY with valid JSON:
{
  "overall_similarity_score": <int 0-100>,
  "exact_match_score": <int>,
  "semantic_similarity_score": <int>,
  "paraphrase_score": <int>,
  "flagged_sections": [
    {
      "start_position": <int>,
      "end_position": <int>,
      "flagged_text": "...",
      "risk_level": "safe|low|medium|high|critical",
      "confidence_score": <int>,
      "similarity_score": <int>,
      "source_url": "...",
      "source_title": "...",
      "explanation": "Brief clinical reason (e.g., 'Verbatim match with Wikipedia').",
      "suggested_action": "Fix recommendation."
    }
  ],
  "executive_summary": "Integrity assessment.",
  "recommendations": ["Step 1", "Step 2"]
}
`;
        break;
      case 'analyze-quality':
        prompt = `Analyze writing quality. Text: """${payload.text}"""`;
        break;
      case 'generate-rewrite':
        prompt = `Rewrite in ${payload.style} style. Original: "${payload.text}"
        Respond ONLY with JSON: { "rewritten_text": "...", "changes_made": [], "similarity_reduction_estimate": <int> }`;
        break;
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), { headers, status: 400 })
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: systemInstruction }] },
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
              response_mime_type: "application/json"
          }
        })
      }
    )

    const data = await response.json()
    if (data.error) throw new Error(data.error.message)

    const resultText = data.candidates?.[0]?.content?.parts?.[0]?.text || '{}'
    return new Response(resultText, { headers })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { headers, status: 500 })
  }
})
