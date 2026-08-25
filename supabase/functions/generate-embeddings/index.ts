import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const MODEL = 'gemini-embedding-2'

console.log("Gemini Embedding Edge Function (Batch Optimized) Initialized")

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
    const { text, texts } = await req.json()

    if (!GEMINI_API_KEY) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not set' }), { headers, status: 500 })
    }

    if (texts && Array.isArray(texts)) {
      // BATCH MODE
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:batchEmbedContents?key=${GEMINI_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            requests: texts.map((t: string) => ({
              model: `models/${MODEL}`,
              content: { parts: [{ text: t }] },
              output_dimensionality: 768
            }))
          })
        }
      )

      const data = await response.json()
      if (data.error) throw new Error(data.error.message)

      return new Response(JSON.stringify({
        embeddings: data.embeddings.map((e: any) => e.values),
        count: data.embeddings.length
      }), { headers })

    } else {
      // SINGLE MODE (Legacy Fallback)
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:embedContent?key=${GEMINI_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            content: { parts: [{ text: text }] },
            output_dimensionality: 768
          })
        }
      )

      const data = await response.json()
      if (data.error) throw new Error(data.error.message)

      return new Response(JSON.stringify({
        embedding: data.embedding.values
      }), { headers })
    }

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { headers, status: 500 })
  }
})
