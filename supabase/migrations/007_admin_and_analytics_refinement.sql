-- ============================================================
-- Academic Writing Coach — Supabase Database Schema
-- Migration 007: Admin Analytics & Performance Refinement
-- ============================================================

-- Function to safely fetch aggregate system statistics for admin users
CREATE OR REPLACE FUNCTION get_admin_system_stats()
RETURNS JSONB AS $$
DECLARE
  v_is_admin BOOLEAN := FALSE;
  v_total_users INT := 0;
  v_scans_today INT := 0;
  v_avg_similarity FLOAT := 0.0;
  v_active_flags INT := 0;
BEGIN
  -- Check if caller is admin
  SELECT is_admin INTO v_is_admin
  FROM profiles
  WHERE id = auth.uid();

  IF v_is_admin IS NOT TRUE THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  -- 1. Total registered users
  SELECT COUNT(*) INTO v_total_users FROM profiles;

  -- 2. Scans completed today
  SELECT COUNT(*) INTO v_scans_today
  FROM scan_results
  WHERE created_at >= CURRENT_DATE;

  -- 3. Average similarity score
  SELECT COALESCE(AVG(overall_similarity_score), 0.0) INTO v_avg_similarity
  FROM scan_results
  WHERE status = 'completed';

  -- 4. Active flagged sections today
  SELECT COUNT(*) INTO v_active_flags
  FROM flagged_sections
  WHERE created_at >= CURRENT_DATE;

  RETURN jsonb_build_object(
    'total_users', v_total_users,
    'scans_today', v_scans_today,
    'avg_similarity', ROUND(v_avg_similarity::NUMERIC, 1),
    'active_flags', v_active_flags,
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
