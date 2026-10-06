import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const MODEL = 'gemini-3.6-flash' // High-efficiency multimodal & reasoning model

console.log("Gemini Reasoning Edge Function (Academic Integrity & Writing Coach Studio) Initialized")

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
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not configured in Supabase secrets' }), { headers, status: 500 })
    }

    let systemInstruction = `You are a clinical Academic Integrity Auditor and Senior Academic Writing Coach.
    CRITICAL RULES:
    1. ZERO HALLUCINATION: Only report on sources present in the Evidence Data. Never fabricate URLs or publications.
    2. CITATION & QUOTATION AWARENESS: Text inside quotation marks with adjacent citations MUST be classified as legitimate scholarship, not plagiarism.
    3. COMMON ACADEMIC PHRASES: Do not penalize standard academic discourse boilerplate (e.g., "The results indicate that", "In order to investigate").
    4. REWRITES: Preserves the original scholarly meaning. Remind users that rewriting does not replace proper scholarly citation.
    5. ACCURACY: Base all risk assessments on multi-layer evidence (Exact, Semantic, Web, Self-Plagiarism).`;

    let prompt = '';

    switch (action) {
      case 'analyze-plagiarism':
        prompt = `
Analyze the verified Multi-Layer Evidence Data for this submitted academic text.
Evaluate originality, exact copying, paraphrasing, web discovery, and self-plagiarism.

Document Context:
"""
${payload.text}
"""

Verified Evidence Data:
${JSON.stringify(payload.evidence)}

Respond ONLY with valid JSON:
{
  "overall_similarity_score": <number 0-100>,
  "exact_match_score": <number 0-100>,
  "semantic_similarity_score": <number 0-100>,
  "paraphrase_score": <number 0-100>,
  "flagged_sections": [
    {
      "start_position": <int>,
      "end_position": <int>,
      "flagged_text": "...",
      "risk_level": "safe|low|medium|high|critical",
      "confidence_score": <int 0-100>,
      "similarity_score": <int 0-100>,
      "source_url": "...",
      "source_title": "...",
      "explanation": "Clear, explainable reason why this was flagged or exempted.",
      "suggested_action": "Actionable guidance for the student."
    }
  ],
  "executive_summary": "Thorough clinical academic integrity assessment.",
  "recommendations": ["Recommendation 1", "Recommendation 2", "Recommendation 3"]
}
`;
        break;

      case 'analyze-quality':
        prompt = `
Perform an in-depth academic writing quality review for the following text:
"""
${payload.text}
"""

Respond ONLY with valid JSON:
{
  "overall_writing_score": <int 0-100>,
  "grammar_score": <int 0-100>,
  "clarity_score": <int 0-100>,
  "academic_tone_score": <int 0-100>,
  "vocabulary_score": <int 0-100>,
  "structure_score": <int 0-100>,
  "readability_score": <int 0-100>,
  "top_strengths": ["...", "..."],
  "top_improvements": ["...", "..."],
  "summary": "Scholarly evaluation of the draft."
}
`;
        break;

      case 'generate-rewrite':
        prompt = `
You are an Academic Writing Assistant. Rewrite the following passage in a "${payload.style}" academic tone.
CRITICAL: Preserve the original factual meaning and empirical substance. Do NOT disguise plagiarism.

Original Text:
"${payload.text}"

Respond ONLY with valid JSON:
{
  "rewritten_text": "Elevated academic revision",
  "style_applied": "${payload.style}",
  "changes_made": ["Explanation of key phrasing adjustments"],
  "citation_reminder": "This passage appears to discuss empirical literature. If referencing external ideas, remember to provide formal citations."
}
`;
        break;

      case 'compare-documents':
        prompt = `
Compare Document A ("${payload.titleA}") and Document B ("${payload.titleB}") for textual and conceptual overlap.

Document A:
"""${payload.textA}"""

Document B:
"""${payload.textB}"""

Respond ONLY with valid JSON:
{
  "overall_similarity": <number 0-100>,
  "exact_match_percentage": <number 0-100>,
  "semantic_similarity_percentage": <number 0-100>,
  "paraphrase_percentage": <number 0-100>,
  "executive_summary": "Comparison overview between Document A and Document B.",
  "unique_to_a": ["Aspect 1 unique to A", "Aspect 2 unique to A"],
  "unique_to_b": ["Aspect 1 unique to B", "Aspect 2 unique to B"],
  "matched_sections": [
    {
      "text_a": "Matching passage in Document A",
      "text_b": "Corresponding passage in Document B",
      "similarity_type": "exact|semantic|paraphrased",
      "similarity_score": <int 0-100>
    }
  ]
}
`;
        break;

      case 'coach-chat': {
        const historyText = Array.isArray(payload.conversationHistory) && payload.conversationHistory.length > 0
          ? payload.conversationHistory
              .map((m: any) => `${m.role === 'user' ? 'Student' : 'Coach'}: ${m.text}`)
              .join('\n\n')
          : 'None (First inquiry)'

        const docTitle = payload.documentTitle || 'Academic Draft'
        const docText = (payload.documentText || '').slice(0, 12000)

        prompt = `
You are an expert Senior Academic Writing Coach assisting a student with their paper: "${docTitle}".
Answer the student's coaching inquiry directly, constructively, and academically.
Base your critique directly on their actual draft text provided below.

Student Document Draft ("${docTitle}"):
"""
${docText}
"""

${payload.highlightedText ? `Specific Passage in Question:\n"${payload.highlightedText}"\n\n` : ''}
${payload.writingMetrics ? `Document Analysis Metrics:\n${JSON.stringify(payload.writingMetrics)}\n\n` : ''}
Previous Conversation Context:
${historyText}

Current Student Question / Coaching Inquiry:
"${payload.question}"

Respond ONLY with a valid JSON object in this exact schema:
{
  "coach_response": "Constructive, specific academic coaching guidance addressing the student's inquiry directly with reference to their text.",
  "strengths_identified": ["Identified strength 1 in this draft"],
  "actionable_recommendations": [
    "Specific revision step 1",
    "Specific revision step 2"
  ],
  "suggested_revision_example": "Concrete example of improved scholarly phrasing (if applicable, otherwise null)",
  "citation_advice": "Advice regarding literature grounding, empirical backing, or citation style (if applicable, otherwise null)"
}
`;
        break;
      }

      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), { headers, status: 400 })
    }

    const CANDIDATE_MODELS = ['gemini-3.6-flash', 'gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash']
    let lastError: any = null
    let data: any = null

    for (const model of CANDIDATE_MODELS) {
      try {
        const response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              systemInstruction: { parts: [{ text: systemInstruction }] },
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                response_mime_type: "application/json"
              }
            })
          }
        )

        const resData = await response.json()
        if (!resData.error && resData.candidates?.[0]?.content?.parts?.[0]?.text) {
          data = resData
          break
        } else {
          lastError = resData.error || new Error(`Model ${model} returned empty response`)
        }
      } catch (mErr) {
        lastError = mErr
      }
    }

    if (!data) {
      throw lastError || new Error('All candidate models failed')
    }

    let resultText = data.candidates?.[0]?.content?.parts?.[0]?.text || '{}'
    
    // Strip possible markdown fences
    resultText = resultText.trim()
    if (resultText.startsWith('```json')) {
      resultText = resultText.replace(/^```json\s*/, '').replace(/\s*```$/, '')
    } else if (resultText.startsWith('```')) {
      resultText = resultText.replace(/^```\s*/, '').replace(/\s*```$/, '')
    }

    try {
      const parsed = JSON.parse(resultText)
      return new Response(JSON.stringify(parsed), { headers })
    } catch (_e) {
      return new Response(resultText, { headers })
    }

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error?.message || 'Unknown error' }), { headers, status: 500 })
  }
})
