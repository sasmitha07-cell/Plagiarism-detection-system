-- Migration 005: Ultra-Speed Batch Search
-- 1. Ensure document_chunks table exists
CREATE TABLE IF NOT EXISTS document_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  embedding vector(768),
  page_number INTEGER,
  paragraph_number INTEGER,
  sentence_number INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Optimize with Indexes
CREATE INDEX IF NOT EXISTS document_chunks_embedding_idx ON document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX IF NOT EXISTS document_chunks_document_id_idx ON document_chunks(document_id);

-- 3. Batch Match Function
-- This function processes an array of embeddings in ONE database call.
CREATE OR REPLACE FUNCTION match_document_chunks_batch(
  query_embeddings vector(768)[],
  match_threshold FLOAT DEFAULT 0.8,
  match_count INT DEFAULT 5,
  target_document_id UUID DEFAULT NULL,
  exclude_document_id UUID DEFAULT NULL
)
RETURNS TABLE (
  query_index INT,
  content TEXT,
  similarity FLOAT,
  page_number INT,
  paragraph_number INT,
  sentence_number INT,
  document_id UUID
) AS $$
BEGIN
  RETURN QUERY
  WITH queries AS (
    SELECT
      query_embedding,
      ordinality as q_idx
    FROM unnest(query_embeddings) WITH ORDINALITY AS t(query_embedding, ordinality)
  )
  SELECT
    q.q_idx::INT,
    dc.content,
    1 - (dc.embedding <=> q.query_embedding) AS similarity,
    dc.page_number,
    dc.paragraph_number,
    dc.sentence_number,
    dc.document_id
  FROM queries q
  CROSS JOIN LATERAL (
    SELECT *
    FROM document_chunks dc
    WHERE
      (target_document_id IS NULL OR dc.document_id = target_document_id)
      AND (exclude_document_id IS NULL OR dc.document_id != exclude_document_id)
      AND 1 - (dc.embedding <=> q.query_embedding) > match_threshold
    ORDER BY dc.embedding <=> q.query_embedding
    LIMIT match_count
  ) dc;
END;
$$ LANGUAGE plpgsql;
