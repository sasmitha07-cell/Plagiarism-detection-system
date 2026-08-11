import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

console.log("Plagiarism Check Edge Function Started")

serve(async (req) => {
  // CORS headers
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
    const { text, type } = await req.json()
    
    if (!text) {
      return new Response(JSON.stringify({ error: 'Text content is required' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Mock analysis logic for plagiarism check
    // In production, this would call Copyleaks, Turnitin, or OpenAI APIs
    
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 2000))

    // Mock response payload
    const result = {
      similarity_score: 12.5,
      writing_score: 88.0,
      ai_probability: 5.2,
      word_count: text.split(/\s+/).length,
      flagged_sections: [
        {
          text_segment: "In conclusion, the results demonstrate that",
          similarity: 100,
          source_url: "https://example.com/academic-paper",
          reason: "Exact match found in public database"
        }
      ],
      grammar_issues: [
        {
          text_segment: "The data shows that",
          suggestion: "The data show that",
          reason: "Subject-verb agreement for plural noun 'data'"
        }
      ]
    }

    return new Response(JSON.stringify(result), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      status: 200,
    })
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
