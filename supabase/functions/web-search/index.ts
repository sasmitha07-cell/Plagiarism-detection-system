import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const SEARCH_API_KEY = Deno.env.get('SEARCH_API_KEY')
const SEARCH_ENGINE_ID = Deno.env.get('SEARCH_ENGINE_ID')

console.log("Web Search Edge Function Initialized")

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
    const { query } = await req.json()

    if (!query) {
      return new Response(JSON.stringify({ error: 'Query is required' }), { headers, status: 400 })
    }

    if (!SEARCH_API_KEY || !SEARCH_ENGINE_ID) {
      console.warn("Search credentials missing. Returning simulated results.");
      return new Response(JSON.stringify([]), { headers })
    }

    // Call Google Custom Search API
    const response = await fetch(
      `https://customsearch.googleapis.com/customsearch/v1?key=${SEARCH_API_KEY}&cx=${SEARCH_ENGINE_ID}&q=${encodeURIComponent(query)}&num=5`
    )

    const data = await response.json()

    if (data.error) {
      return new Response(JSON.stringify({ error: data.error.message }), { headers, status: 502 })
    }

    const items = data.items || []
    const results = items.map((item: any, index: number) => ({
      title: item.title,
      url: item.link,
      domain: new URL(item.link).hostname,
      snippet: item.snippet,
      query: query,
      rank: index + 1,
      sourceType: 'web'
    }))

    // Basic Deduplication by URL
    const uniqueResults = Array.from(new Map(results.map((r: any) => [r.url, r])).values())

    return new Response(JSON.stringify(uniqueResults), { headers })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { headers, status: 500 })
  }
})
