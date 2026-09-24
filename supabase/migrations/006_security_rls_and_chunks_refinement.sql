-- ============================================================
-- Migration 006: Security RLS & Chunks Refinement
-- Self-contained migration: Ensures table, vector extension, RLS, and RPC
-- ============================================================

-- 1. Ensure required extensions exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Ensure document_chunks table exists
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

-- 3. Enable RLS on document_chunks
ALTER TABLE document_chunks ENABLE ROW LEVEL SECURITY;

-- 4. Create strict user-scoped RLS policies
DROP POLICY IF EXISTS "Users can view their own document chunks" ON document_chunks;
CREATE POLICY "Users can view their own document chunks"
  ON document_chunks FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own document chunks" ON document_chunks;
CREATE POLICY "Users can insert their own document chunks"
  ON document_chunks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own document chunks" ON document_chunks;
CREATE POLICY "Users can update their own document chunks"
  ON document_chunks FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own document chunks" ON document_chunks;
CREATE POLICY "Users can delete their own document chunks"
  ON document_chunks FOR DELETE
  USING (auth.uid() = user_id);

-- 5. Performance and Composite Indexes
CREATE INDEX IF NOT EXISTS document_chunks_user_doc_idx ON document_chunks(user_id, document_id);
CREATE INDEX IF NOT EXISTS document_chunks_document_id_idx ON document_chunks(document_id);
CREATE INDEX IF NOT EXISTS document_chunks_embedding_idx ON document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 6. Secure & Enhanced Batch Match Function with optional user-scoping for self-plagiarism
CREATE OR REPLACE FUNCTION match_document_chunks_batch(
  query_embeddings vector(768)[],
  match_threshold FLOAT DEFAULT 0.75,
  match_count INT DEFAULT 5,
  target_document_id UUID DEFAULT NULL,
  exclude_document_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  query_index INT,
  content TEXT,
  similarity FLOAT,
  page_number INT,
  paragraph_number INT,
  sentence_number INT,
  document_id UUID,
  user_id UUID
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
    (1 - (dc.embedding <=> q.query_embedding))::FLOAT AS similarity,
    dc.page_number,
    dc.paragraph_number,
    dc.sentence_number,
    dc.document_id,
    dc.user_id
  FROM queries q
  CROSS JOIN LATERAL (
    SELECT *
    FROM document_chunks dc
    WHERE
      (p_user_id IS NULL OR dc.user_id = p_user_id)
      AND (target_document_id IS NULL OR dc.document_id = target_document_id)
      AND (exclude_document_id IS NULL OR dc.document_id != exclude_document_id)
      AND 1 - (dc.embedding <=> q.query_embedding) >= match_threshold
    ORDER BY dc.embedding <=> q.query_embedding
    LIMIT match_count
  ) dc;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
