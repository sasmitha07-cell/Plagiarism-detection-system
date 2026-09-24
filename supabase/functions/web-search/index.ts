import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const SEARCH_API_KEY = Deno.env.get('SEARCH_API_KEY')
const SEARCH_ENGINE_ID = Deno.env.get('SEARCH_ENGINE_ID')

console.log("Web Search & Academic Literature Edge Function Initialized")

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

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return new Response(JSON.stringify({ error: 'Query is required' }), { headers, status: 400 })
    }

    const cleanQuery = query.replace(/["]/g, '').trim()
    const allResults: any[] = []

    // 1. Primary: Google Custom Search API (if credentials configured)
    if (SEARCH_API_KEY && SEARCH_ENGINE_ID) {
      try {
        const response = await fetch(
          `https://customsearch.googleapis.com/customsearch/v1?key=${SEARCH_API_KEY}&cx=${SEARCH_ENGINE_ID}&q=${encodeURIComponent(query)}&num=5`
        )
        const data = await response.json()
        if (!data.error && data.items && Array.isArray(data.items)) {
          for (let i = 0; i < data.items.length; i++) {
            const item = data.items[i]
            let domain = 'web'
            try {
              domain = new URL(item.link).hostname
            } catch (_) {}
            allResults.push({
              title: item.title,
              url: item.link,
              domain: domain,
              snippet: item.snippet || '',
              query: query,
              rank: i + 1,
              sourceType: domain.includes('doi.org') || domain.includes('sciencedirect') || domain.includes('ncbi') || domain.includes('arxiv')
                ? 'academic'
                : 'web'
            })
          }
        }
      } catch (err) {
        console.warn("Google CSE query error:", err)
      }
    }

    // 2. Open Academic Literature Search (CrossRef Open API: 150M+ scholarly works)
    try {
      const crossrefRes = await fetch(
        `https://api.crossref.org/works?query=${encodeURIComponent(cleanQuery)}&rows=3&mailto=academic-coach@antigravity.dev`,
        { headers: { 'User-Agent': 'AcademicWritingCoach/1.0 (mailto:academic-coach@antigravity.dev)' } }
      )
      if (crossrefRes.ok) {
        const crData = await crossrefRes.json()
        const items = crData.message?.items || []
        for (let i = 0; i < items.length; i++) {
          const item = items[i]
          const title = (item.title && item.title.length > 0) ? item.title[0] : 'Academic Publication'
          const url = item.URL || (item.DOI ? `https://doi.org/${item.DOI}` : '')
          const journal = (item['container-title'] && item['container-title'].length > 0) ? item['container-title'][0] : 'Scholarly Journal'
          const author = (item.author && item.author.length > 0)
            ? `${item.author[0].family || item.author[0].name || ''} et al.`
            : ''
          const snippet = item.abstract
            ? item.abstract.replace(/<[^>]*>/g, '').slice(0, 300)
            : `${title} (${author ? `${author}, ` : ''}${journal}). Academic literature source.`

          if (url) {
            allResults.push({
              title: `${title} - ${journal}`,
              url: url,
              domain: 'crossref.org',
              snippet: snippet,
              query: query,
              rank: allResults.length + 1,
              sourceType: 'academic'
            })
          }
        }
      }
    } catch (crErr) {
      console.warn("CrossRef search note:", crErr)
    }

    // 3. Open Encyclopedia & Web Knowledge Search (Wikipedia Open Search API)
    try {
      const wikiRes = await fetch(
        `https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(cleanQuery)}&utf8=&format=json`
      )
      if (wikiRes.ok) {
        const wikiData = await wikiRes.json()
        const items = wikiData.query?.search || []
        for (let i = 0; i < Math.min(items.length, 3); i++) {
          const item = items[i]
          const cleanSnippet = (item.snippet || '').replace(/<[^>]*>/g, '').replace(/&quot;/g, '"').replace(/&#039;/g, "'")
          allResults.push({
            title: `${item.title} - Wikipedia`,
            url: `https://en.wikipedia.org/wiki/${encodeURIComponent(item.title.replace(/\s+/g, '_'))}`,
            domain: 'en.wikipedia.org',
            snippet: cleanSnippet,
            query: query,
            rank: allResults.length + 1,
            sourceType: 'web'
          })
        }
      }
    } catch (wikiErr) {
      console.warn("Wikipedia search note:", wikiErr)
    }

    // Deduplicate by URL
    const uniqueResults = Array.from(new Map(allResults.map((r) => [r.url, r])).values())

    return new Response(JSON.stringify(uniqueResults), { headers })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error?.message || 'Unknown search error' }), { headers, status: 500 })
  }
})
