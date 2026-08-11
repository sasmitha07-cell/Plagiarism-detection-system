-- ============================================================
-- Academic Writing Coach — Supabase Database Schema
-- Migration 001: Core Tables + pgvector Extension
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE document_type AS ENUM ('pdf', 'docx', 'doc', 'txt', 'rtf', 'image', 'voice');
CREATE TYPE scan_status AS ENUM ('pending', 'processing', 'completed', 'failed');
CREATE TYPE plagiarism_type AS ENUM (
  'exact_copy',
  'partial_copy',
  'semantic_similarity',
  'missing_citation',
  'paraphrased',
  'ai_rewritten'
);
CREATE TYPE risk_level AS ENUM ('safe', 'low', 'medium', 'high', 'critical');
CREATE TYPE citation_style AS ENUM ('apa', 'mla', 'ieee', 'harvard', 'chicago');
CREATE TYPE academic_level AS ENUM ('high_school', 'undergraduate', 'graduate', 'doctorate', 'faculty', 'researcher', 'other');
CREATE TYPE rewrite_style AS ENUM ('academic', 'research', 'formal', 'concise', 'humanized');
CREATE TYPE content_type AS ENUM ('human', 'ai', 'mixed');

-- ============================================================
-- PROFILES TABLE
-- ============================================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT UNIQUE NOT NULL,
  institution TEXT,
  department TEXT,
  academic_level academic_level DEFAULT 'undergraduate',
  avatar_url TEXT,
  bio TEXT,
  total_scans INTEGER DEFAULT 0,
  total_documents INTEGER DEFAULT 0,
  average_similarity_score DECIMAL(5,2) DEFAULT 0,
  average_writing_score DECIMAL(5,2) DEFAULT 0,
  zero_plagiarism_streak INTEGER DEFAULT 0,
  is_admin BOOLEAN DEFAULT FALSE,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DOCUMENTS TABLE
-- ============================================================

CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  word_count INTEGER DEFAULT 0,
  character_count INTEGER DEFAULT 0,
  file_url TEXT,
  file_type document_type DEFAULT 'txt',
  file_size_bytes BIGINT,
  language TEXT DEFAULT 'en',
  is_personal_source BOOLEAN DEFAULT FALSE,
  embedding vector(768),  -- pgvector embedding for semantic search
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX documents_user_id_idx ON documents(user_id);
CREATE INDEX documents_embedding_idx ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX documents_content_trgm_idx ON documents USING gin (content gin_trgm_ops);

-- ============================================================
-- SCAN RESULTS TABLE
-- ============================================================

CREATE TABLE scan_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  status scan_status DEFAULT 'pending',

  -- Overall scores
  overall_similarity_score DECIMAL(5,2) DEFAULT 0,
  exact_match_score DECIMAL(5,2) DEFAULT 0,
  semantic_similarity_score DECIMAL(5,2) DEFAULT 0,
  paraphrase_score DECIMAL(5,2) DEFAULT 0,

  -- AI detection scores
  ai_generated_score DECIMAL(5,2) DEFAULT 0,
  human_written_score DECIMAL(5,2) DEFAULT 0,
  ai_detection_confidence DECIMAL(5,2) DEFAULT 0,
  content_type content_type DEFAULT 'human',

  -- Writing quality scores
  grammar_score DECIMAL(5,2),
  readability_score DECIMAL(5,2),
  academic_tone_score DECIMAL(5,2),
  vocabulary_score DECIMAL(5,2),
  structure_score DECIMAL(5,2),
  overall_writing_score DECIMAL(5,2),

  -- Statistics
  total_flagged_sections INTEGER DEFAULT 0,
  total_sources_found INTEGER DEFAULT 0,
  sources_checked INTEGER DEFAULT 0,
  processing_time_ms INTEGER,

  -- Report
  report_url TEXT,
  executive_summary TEXT,
  recommendations TEXT[],

  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX scan_results_user_id_idx ON scan_results(user_id);
CREATE INDEX scan_results_document_id_idx ON scan_results(document_id);
CREATE INDEX scan_results_created_at_idx ON scan_results(created_at DESC);

-- ============================================================
-- FLAGGED SECTIONS TABLE
-- ============================================================

CREATE TABLE flagged_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scan_id UUID NOT NULL REFERENCES scan_results(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

  -- Position in original text
  start_position INTEGER NOT NULL,
  end_position INTEGER NOT NULL,
  flagged_text TEXT NOT NULL,

  -- Match details
  plagiarism_type plagiarism_type NOT NULL,
  risk_level risk_level NOT NULL,
  confidence_score DECIMAL(5,2) NOT NULL,
  similarity_score DECIMAL(5,2) NOT NULL,

  -- Source details
  source_url TEXT,
  source_title TEXT,
  source_author TEXT,
  source_publication_date TEXT,
  matched_source_text TEXT,

  -- AI explanation
  explanation TEXT NOT NULL,
  suggested_action TEXT,

  -- Rewrite suggestions
  rewrite_suggestions JSONB DEFAULT '[]',

  -- Citation suggestion
  citation_suggestion JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX flagged_sections_scan_id_idx ON flagged_sections(scan_id);
CREATE INDEX flagged_sections_document_id_idx ON flagged_sections(document_id);

-- ============================================================
-- SIMILARITY SOURCES TABLE
-- ============================================================

CREATE TABLE similarity_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scan_id UUID NOT NULL REFERENCES scan_results(id) ON DELETE CASCADE,
  url TEXT,
  title TEXT,
  author TEXT,
  publication_date TEXT,
  domain TEXT,
  snippet TEXT,
  similarity_percentage DECIMAL(5,2) NOT NULL,
  match_count INTEGER DEFAULT 1,
  source_type TEXT DEFAULT 'web',  -- web, academic, user_document, personal_source
  accessed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX similarity_sources_scan_id_idx ON similarity_sources(scan_id);

-- ============================================================
-- DOCUMENT COMPARISONS TABLE
-- ============================================================

CREATE TABLE document_comparisons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_a_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  document_b_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  document_a_title TEXT NOT NULL,
  document_b_title TEXT NOT NULL,
  status scan_status DEFAULT 'pending',

  -- Scores
  overall_similarity DECIMAL(5,2) DEFAULT 0,
  exact_match_percentage DECIMAL(5,2) DEFAULT 0,
  semantic_similarity_percentage DECIMAL(5,2) DEFAULT 0,
  paraphrase_percentage DECIMAL(5,2) DEFAULT 0,

  -- Matched sections
  matched_sections JSONB DEFAULT '[]',
  executive_summary TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX document_comparisons_user_id_idx ON document_comparisons(user_id);

-- ============================================================
-- CITATIONS TABLE
-- ============================================================

CREATE TABLE citations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  scan_id UUID REFERENCES scan_results(id) ON DELETE SET NULL,
  document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  source_url TEXT,
  source_title TEXT,
  source_author TEXT,
  source_publication_date TEXT,
  source_publisher TEXT,
  source_volume TEXT,
  source_issue TEXT,
  source_pages TEXT,
  citation_apa TEXT,
  citation_mla TEXT,
  citation_ieee TEXT,
  citation_harvard TEXT,
  citation_chicago TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX citations_user_id_idx ON citations(user_id);
CREATE INDEX citations_scan_id_idx ON citations(scan_id);

-- ============================================================
-- WRITING ANALYTICS TABLE
-- ============================================================

CREATE TABLE writing_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  scan_id UUID NOT NULL REFERENCES scan_results(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

  -- Detailed writing issues
  grammar_issues JSONB DEFAULT '[]',
  readability_issues JSONB DEFAULT '[]',
  tone_issues JSONB DEFAULT '[]',
  vocabulary_suggestions JSONB DEFAULT '[]',
  structure_suggestions JSONB DEFAULT '[]',

  -- Learning tips generated
  learning_tips JSONB DEFAULT '[]',

  -- Flesch reading ease score
  flesch_score DECIMAL(5,2),
  avg_sentence_length DECIMAL(5,2),
  avg_syllables_per_word DECIMAL(5,2),
  passive_voice_percentage DECIMAL(5,2),
  academic_word_percentage DECIMAL(5,2),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX writing_analytics_user_id_idx ON writing_analytics(user_id);
CREATE INDEX writing_analytics_document_id_idx ON writing_analytics(document_id);

-- ============================================================
-- ACHIEVEMENTS TABLE
-- ============================================================

CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id TEXT NOT NULL,
  badge_name TEXT NOT NULL,
  badge_description TEXT,
  badge_icon TEXT,
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

CREATE INDEX achievements_user_id_idx ON achievements(user_id);

-- Available badges reference table
CREATE TABLE badge_definitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category TEXT NOT NULL,
  requirement_type TEXT NOT NULL,
  requirement_value INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO badge_definitions (id, name, description, icon, category, requirement_type, requirement_value) VALUES
  ('first_scan', 'First Scan', 'Completed your first plagiarism scan', '🔍', 'milestone', 'scan_count', 1),
  ('clean_writer', 'Clean Writer', 'Achieved 0% plagiarism on a document', '✨', 'quality', 'zero_plagiarism', 1),
  ('citation_master', 'Citation Master', 'Generated 10 citations', '📚', 'citations', 'citation_count', 10),
  ('academic_writer', 'Academic Writer', 'Achieved writing score above 85', '🎓', 'writing', 'writing_score', 85),
  ('research_expert', 'Research Expert', 'Completed 25 scans', '🔬', 'milestone', 'scan_count', 25),
  ('zero_streak_3', 'Zero Plagiarism Streak', '3 consecutive clean documents', '🏆', 'streak', 'zero_streak', 3),
  ('zero_streak_7', 'Plagiarism Free Champion', '7 consecutive clean documents', '🌟', 'streak', 'zero_streak', 7),
  ('improver', 'Writing Improver', 'Improved writing score by 20 points', '📈', 'progress', 'score_improvement', 20),
  ('comparison_pro', 'Comparison Pro', 'Used document comparison 5 times', '⚖️', 'features', 'comparison_count', 5),
  ('voice_user', 'Voice Analyst', 'Used voice-to-text analysis', '🎤', 'features', 'voice_scan', 1);

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL,  -- scan_complete, achievement, weekly_summary, writing_tip
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX notifications_user_id_idx ON notifications(user_id);
CREATE INDEX notifications_is_read_idx ON notifications(user_id, is_read);

-- ============================================================
-- PERSONAL SOURCES TABLE  
-- ============================================================

CREATE TABLE personal_sources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  embedding vector(768),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX personal_sources_user_id_idx ON personal_sources(user_id);
CREATE INDEX personal_sources_embedding_idx ON personal_sources USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);

-- ============================================================
-- WEEKLY ANALYTICS SNAPSHOTS
-- ============================================================

CREATE TABLE analytics_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  scans_count INTEGER DEFAULT 0,
  avg_similarity_score DECIMAL(5,2),
  avg_writing_score DECIMAL(5,2),
  avg_ai_score DECIMAL(5,2),
  documents_improved INTEGER DEFAULT 0,
  citations_generated INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update user scan stats after scan completion
CREATE OR REPLACE FUNCTION update_user_scan_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE profiles SET
      total_scans = total_scans + 1,
      average_similarity_score = (
        SELECT AVG(overall_similarity_score)
        FROM scan_results
        WHERE user_id = NEW.user_id AND status = 'completed'
      ),
      average_writing_score = (
        SELECT AVG(overall_writing_score)
        FROM scan_results
        WHERE user_id = NEW.user_id AND status = 'completed' AND overall_writing_score IS NOT NULL
      )
    WHERE id = NEW.user_id;

    -- Update zero plagiarism streak
    IF NEW.overall_similarity_score = 0 THEN
      UPDATE profiles SET
        zero_plagiarism_streak = zero_plagiarism_streak + 1
      WHERE id = NEW.user_id;
    ELSE
      UPDATE profiles SET
        zero_plagiarism_streak = 0
      WHERE id = NEW.user_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_scan_completed
  AFTER UPDATE ON scan_results
  FOR EACH ROW EXECUTE FUNCTION update_user_scan_stats();

-- Semantic similarity search function
CREATE OR REPLACE FUNCTION search_similar_documents(
  query_embedding vector(768),
  user_uuid UUID,
  match_threshold FLOAT DEFAULT 0.75,
  match_count INT DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  content TEXT,
  similarity FLOAT,
  user_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.title,
    d.content,
    1 - (d.embedding <=> query_embedding) AS similarity,
    d.user_id
  FROM documents d
  WHERE
    d.user_id = user_uuid
    AND d.embedding IS NOT NULL
    AND 1 - (d.embedding <=> query_embedding) > match_threshold
  ORDER BY d.embedding <=> query_embedding
  LIMIT match_count;
END;
$$ LANGUAGE plpgsql;
