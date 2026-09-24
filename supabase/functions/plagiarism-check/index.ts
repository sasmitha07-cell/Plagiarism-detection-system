import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

console.log("Plagiarism Check Router Edge Function Initialized")

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const { text, evidence = [] } = await req.json()

    if (!text || text.trim().length === 0) {
      return new Response(JSON.stringify({ error: 'Text content is required' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const words = text.trim().split(/\s+/).filter((w: string) => w.length > 0)
    
    // Transparent deterministic aggregation over submitted evidence
    let exactCount = 0
    let semanticCount = 0
    let webCount = 0
    
    for (const ev of evidence) {
      if (ev.signals && ev.signals.includes('exactCopy')) exactCount++
      if (ev.signals && ev.signals.includes('semanticSimilarity')) semanticCount++
      if (ev.signals && ev.signals.includes('webDiscovery')) webCount++
    }

    const totalEv = Math.max(1, evidence.length)
    const exactScore = Math.min(100, Math.round((exactCount / totalEv) * 100))
    const semanticScore = Math.min(100, Math.round((semanticCount / totalEv) * 100))
    const webScore = Math.min(100, Math.round((webCount / totalEv) * 100))
    const overall = Math.min(100, Math.round((exactScore * 0.5) + (webScore * 0.3) + (semanticScore * 0.2)))

    const result = {
      similarity_score: overall,
      exact_match_score: exactScore,
      semantic_score: semanticScore,
      web_score: webScore,
      word_count: words.length,
      evidence_count: evidence.length,
      flagged_sections: evidence.map((e: any) => ({
        text_segment: e.submittedText || '',
        similarity: Math.round((e.exactSimilarity || e.webSimilarity || e.semanticSimilarity || 0) * 100),
        source_url: e.sourceUrl || null,
        source_title: e.sourceTitle || 'Database / Web Source',
        reason: e.reason || 'Similarity flagged by multi-layer detection pipeline'
      })),
      status: 'success'
    }

    return new Response(JSON.stringify(result), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
