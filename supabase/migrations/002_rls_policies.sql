-- ============================================================
-- Migration 002: Row Level Security Policies
-- ============================================================

-- ============================================================
-- PROFILES RLS
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- ============================================================
-- DOCUMENTS RLS
-- ============================================================

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own documents"
  ON documents FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own documents"
  ON documents FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own documents"
  ON documents FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- SCAN RESULTS RLS
-- ============================================================

ALTER TABLE scan_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own scan results"
  ON scan_results FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own scan results"
  ON scan_results FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own scan results"
  ON scan_results FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all scan results"
  ON scan_results FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- ============================================================
-- FLAGGED SECTIONS RLS
-- ============================================================

ALTER TABLE flagged_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own flagged sections"
  ON flagged_sections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM scan_results sr
      WHERE sr.id = scan_id AND sr.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert flagged sections for their scans"
  ON flagged_sections FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM scan_results sr
      WHERE sr.id = scan_id AND sr.user_id = auth.uid()
    )
  );

-- ============================================================
-- SIMILARITY SOURCES RLS
-- ============================================================

ALTER TABLE similarity_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own similarity sources"
  ON similarity_sources FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM scan_results sr
      WHERE sr.id = scan_id AND sr.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert similarity sources for their scans"
  ON similarity_sources FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM scan_results sr
      WHERE sr.id = scan_id AND sr.user_id = auth.uid()
    )
  );

-- ============================================================
-- DOCUMENT COMPARISONS RLS
-- ============================================================

ALTER TABLE document_comparisons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own comparisons"
  ON document_comparisons FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- CITATIONS RLS
-- ============================================================

ALTER TABLE citations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own citations"
  ON citations FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- WRITING ANALYTICS RLS
-- ============================================================

ALTER TABLE writing_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own writing analytics"
  ON writing_analytics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own writing analytics"
  ON writing_analytics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- ACHIEVEMENTS RLS
-- ============================================================

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own achievements"
  ON achievements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert achievements for users"
  ON achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- badge_definitions is public read
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Badge definitions are publicly readable"
  ON badge_definitions FOR SELECT
  USING (TRUE);

-- ============================================================
-- NOTIFICATIONS RLS
-- ============================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- PERSONAL SOURCES RLS
-- ============================================================

ALTER TABLE personal_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own personal sources"
  ON personal_sources FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- ANALYTICS SNAPSHOTS RLS
-- ============================================================

ALTER TABLE analytics_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own analytics"
  ON analytics_snapshots FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own analytics"
  ON analytics_snapshots FOR INSERT
  WITH CHECK (auth.uid() = user_id);
