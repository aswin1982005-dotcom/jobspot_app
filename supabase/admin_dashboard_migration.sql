-- Admin Dashboard Database Schema
-- This file contains all the database changes needed for the admin dashboard

-- ============================================================================
-- 1. CREATE NEW TABLES FOR ADMIN FEATURES
-- ============================================================================

-- Admin action logging (audit trail)
CREATE TABLE IF NOT EXISTS admin_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL, 
  -- Possible values: 'disable_user', 'enable_user', 'disable_job', 'enable_job', 
  -- 'resolve_report', 'add_job_note', 'send_message'
  target_type TEXT NOT NULL, -- 'user', 'job', 'report'
  target_id UUID NOT NULL,
  reason TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin_id ON admin_actions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_created_at ON admin_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target ON admin_actions(target_type, target_id);

-- User complaints/reports
CREATE TABLE IF NOT EXISTS user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL, 
  -- Possible values: 'spam', 'harassment', 'fraud', 'inappropriate', 'other'
  description TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'resolved', 'dismissed'
  admin_notes TEXT,
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_created_at ON user_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user ON user_reports(reported_user_id);

-- Job reports
CREATE TABLE IF NOT EXISTS job_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  job_id UUID REFERENCES job_posts(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL, 
  -- Possible values: 'fake', 'inappropriate', 'discriminatory', 'spam', 'other'
  description TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'resolved', 'dismissed'
  admin_notes TEXT,
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_job_reports_status ON job_reports(status);
CREATE INDEX IF NOT EXISTS idx_job_reports_created_at ON job_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_job_reports_job_id ON job_reports(job_id);

-- ============================================================================
-- 2. ALTER EXISTING TABLES - ADD ADMIN CONTROL COLUMNS
-- ============================================================================

-- Add admin control columns to user_profiles
ALTER TABLE user_profiles 
  ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS disabled_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS disable_reason TEXT;

-- Create index for disabled users
CREATE INDEX IF NOT EXISTS idx_user_profiles_disabled ON user_profiles(is_disabled);

-- Add admin control columns to job_posts  
ALTER TABLE job_posts 
  ADD COLUMN IF NOT EXISTS is_reported BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS reported_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS admin_disabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_job_posts_reported ON job_posts(is_reported);
CREATE INDEX IF NOT EXISTS idx_job_posts_admin_disabled ON job_posts(admin_disabled);

-- ============================================================================
-- 3. ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_reports ENABLE ROW LEVEL SECURITY;

-- Admin Actions Policies
-- Only admins can view admin actions
CREATE POLICY "Admins can view all admin actions"
  ON admin_actions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can insert admin actions
CREATE POLICY "Admins can insert admin actions"
  ON admin_actions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- User Reports Policies
-- Users can view their own reports
CREATE POLICY "Users can view their own reports"
  ON user_reports FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid());

-- Admins can view all reports
CREATE POLICY "Admins can view all user reports"
  ON user_reports FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Users can create reports
CREATE POLICY "Users can create reports"
  ON user_reports FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- Admins can update reports
CREATE POLICY "Admins can update user reports"
  ON user_reports FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Job Reports Policies  
-- Users can view their own job reports
CREATE POLICY "Users can view their own job reports"
  ON job_reports FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid());

-- Admins can view all job reports
CREATE POLICY "Admins can view all job reports"
  ON job_reports FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Users can create job reports
CREATE POLICY "Users can create job reports"
  ON job_reports FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- Admins can update job reports
CREATE POLICY "Admins can update job reports"
  ON job_reports FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 4. DATABASE FUNCTIONS
-- ============================================================================

-- Function to get admin users list
CREATE OR REPLACE FUNCTION get_admin_users_list(
  role_filter TEXT DEFAULT NULL,
  disabled_only BOOLEAN DEFAULT NULL,
  page_limit INTEGER DEFAULT 50,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  role TEXT,
  profile_completed BOOLEAN,
  is_disabled BOOLEAN,
  disabled_at TIMESTAMPTZ,
  disable_reason TEXT,
  created_at TIMESTAMPTZ,
  seeker_profile JSONB,
  employer_profile JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.user_id as user_id,
    u.role::text,
    u.profile_completed,
    u.is_disabled,
    u.disabled_at,
    u.disable_reason,
    u.created_at,
    CASE
      WHEN u.role = 'seeker' THEN to_jsonb(s)
      ELSE NULL
    END as seeker_profile,
    CASE
      WHEN u.role = 'employer' THEN to_jsonb(e)
      ELSE NULL
    END as employer_profile
  FROM user_profiles u
  LEFT JOIN job_seeker_profiles s ON u.user_id = s.user_id
  LEFT JOIN employer_profiles e ON u.user_id = e.user_id
  WHERE
    (role_filter IS NULL OR u.role::text = role_filter) AND
    (disabled_only IS NULL OR u.is_disabled = disabled_only)
  ORDER BY u.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- Function to get admin dashboard stats
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_stats JSONB;
  job_stats JSONB;
  report_stats JSONB;
BEGIN
  -- User Stats
  SELECT jsonb_build_object(
    'total_users', COUNT(*),
    'seekers', COUNT(*) FILTER (WHERE role = 'seeker'),
    'employers', COUNT(*) FILTER (WHERE role = 'employer'),
    'disabled', COUNT(*) FILTER (WHERE is_disabled = true)
  ) INTO user_stats FROM user_profiles;

  -- Job Stats
  SELECT jsonb_build_object(
    'total_jobs', COUNT(*),
    'active', COUNT(*) FILTER (WHERE is_active = true),
    'reported', COUNT(*) FILTER (WHERE is_reported = true),
    'disabled', COUNT(*) FILTER (WHERE admin_disabled = true)
  ) INTO job_stats FROM job_posts;

  -- Report Stats
  SELECT jsonb_build_object(
    'total_reports', (SELECT COUNT(*) FROM user_reports) + (SELECT COUNT(*) FROM job_reports),
    'pending', (SELECT COUNT(*) FROM user_reports WHERE status = 'pending') + (SELECT COUNT(*) FROM job_reports WHERE status = 'pending'),
    'resolved', (SELECT COUNT(*) FROM user_reports WHERE status = 'resolved') + (SELECT COUNT(*) FROM job_reports WHERE status = 'resolved')
  ) INTO report_stats;

  RETURN jsonb_build_object(
    'user_stats', user_stats,
    'job_stats', job_stats,
    'report_stats', report_stats
  );
END;
$$;

-- Function to get admin recent activity
CREATE OR REPLACE FUNCTION get_admin_recent_activity()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  recent_users JSONB;
  recent_jobs JSONB;
BEGIN
  -- Recent Users
  SELECT jsonb_agg(t) INTO recent_users FROM (
    SELECT
      u.user_id,
      u.role,
      u.created_at,
      s.full_name as seeker_name,
      s.avatar_url as seeker_avatar,
      e.company_name as employer_name,
      e.avatar_url as employer_avatar
    FROM user_profiles u
    LEFT JOIN job_seeker_profiles s ON u.user_id = s.user_id AND u.role = 'seeker'
    LEFT JOIN employer_profiles e ON u.user_id = e.user_id AND u.role = 'employer'
    ORDER BY u.created_at DESC
    LIMIT 5
  ) t;

  -- Recent Jobs
  SELECT jsonb_agg(t) INTO recent_jobs FROM (
    SELECT
      j.id,
      j.title,
      j.location,
      j.created_at,
      j.is_active,
      j.admin_disabled,
      e.company_name,
      e.avatar_url as company_avatar
    FROM job_posts j
    LEFT JOIN employer_profiles e ON j.employer_id = e.user_id
    ORDER BY j.created_at DESC
    LIMIT 5
  ) t;

  RETURN jsonb_build_object(
    'recent_users', COALESCE(recent_users, '[]'::jsonb),
    'recent_jobs', COALESCE(recent_jobs, '[]'::jsonb)
  );
END;
$$;

-- Function to get admin actions
CREATE OR REPLACE FUNCTION get_admin_actions(
  page_limit INTEGER DEFAULT 50,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  admin_id UUID,
  action_type TEXT,
  target_type TEXT,
  target_id TEXT,
  reason TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ,
  admin_name TEXT,
  admin_role TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.admin_id,
    a.action_type,
    a.target_type,
    a.target_id,
    a.reason,
    a.metadata,
    a.created_at,
    COALESCE(s.full_name, e.company_name, 'Unknown') as admin_name,
    u.role::text as admin_role
  FROM admin_actions a
  JOIN user_profiles u ON a.admin_id = u.user_id
  LEFT JOIN job_seeker_profiles s ON u.user_id = s.user_id AND u.role = 'seeker'
  LEFT JOIN employer_profiles e ON u.user_id = e.user_id AND u.role = 'employer'
  ORDER BY a.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- Function to get job reports
CREATE OR REPLACE FUNCTION get_job_reports(
  status_filter TEXT DEFAULT NULL,
  page_limit INTEGER DEFAULT 50,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  reporter_id UUID,
  job_id UUID,
  report_type TEXT,
  description TEXT,
  status TEXT,
  admin_notes TEXT,
  created_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  reporter_email TEXT,
  job_title TEXT,
  job_location TEXT,
  job_is_active BOOLEAN,
  job_admin_disabled BOOLEAN,
  employer_company_name TEXT,
  resolver_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.reporter_id,
    r.job_id,
    r.report_type,
    r.description,
    r.status,
    r.admin_notes,
    r.created_at,
    r.resolved_at,
    r.resolved_by,
    u_reporter.email as reporter_email,
    j.title as job_title,
    j.location as job_location,
    j.is_active as job_is_active,
    j.admin_disabled as job_admin_disabled,
    e.company_name as employer_company_name,
    COALESCE(ress.full_name, rese.company_name, 'Unknown') as resolver_name
  FROM job_reports r
  JOIN auth.users u_reporter ON r.reporter_id = u_reporter.id
  JOIN job_posts j ON r.job_id = j.id
  LEFT JOIN employer_profiles e ON j.employer_id = e.user_id
  LEFT JOIN user_profiles res ON r.resolved_by = res.user_id
  LEFT JOIN job_seeker_profiles ress ON res.user_id = ress.user_id AND res.role = 'seeker'
  LEFT JOIN employer_profiles rese ON res.user_id = rese.user_id AND res.role = 'employer'
  WHERE (status_filter IS NULL OR r.status = status_filter)
  ORDER BY r.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- Function to get user reports
CREATE OR REPLACE FUNCTION get_user_reports(
  status_filter TEXT DEFAULT NULL,
  page_limit INTEGER DEFAULT 50,
  page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  reporter_id UUID,
  reported_user_id UUID,
  report_type TEXT,
  description TEXT,
  status TEXT,
  admin_notes TEXT,
  created_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  reporter_email TEXT,
  reported_user_role TEXT,
  reported_user_name TEXT,
  reported_user_avatar TEXT,
  resolver_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.reporter_id,
    r.reported_user_id,
    r.report_type,
    r.description,
    r.status,
    r.admin_notes,
    r.created_at,
    r.resolved_at,
    r.resolved_by,
    u_reporter.email as reporter_email,
    u_reported.role::text as reported_user_role,
    COALESCE(s.full_name, e.company_name) as reported_user_name,
    COALESCE(s.avatar_url, e.avatar_url) as reported_user_avatar,
    COALESCE(ress.full_name, rese.company_name, 'Unknown') as resolver_name
  FROM user_reports r
  JOIN auth.users u_reporter ON r.reporter_id = u_reporter.id
  JOIN user_profiles u_reported ON r.reported_user_id = u_reported.user_id
  LEFT JOIN job_seeker_profiles s ON u_reported.user_id = s.user_id AND u_reported.role = 'seeker'
  LEFT JOIN employer_profiles e ON u_reported.user_id = e.user_id AND u_reported.role = 'employer'
  LEFT JOIN user_profiles res ON r.resolved_by = res.user_id
  LEFT JOIN job_seeker_profiles ress ON res.user_id = ress.user_id AND res.role = 'seeker'
  LEFT JOIN employer_profiles rese ON res.user_id = rese.user_id AND res.role = 'employer'
  WHERE (status_filter IS NULL OR r.status = status_filter)
  ORDER BY r.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- ============================================================================
-- 5. HELPER SCRIPT TO PROMOTE A USER TO ADMIN
-- ============================================================================

-- Run this to promote a user to admin role (replace the email):
-- UPDATE user_profiles 
-- SET role = 'admin' 
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@example.com');

-- Grant admin permissions to the auth.users table if needed
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
