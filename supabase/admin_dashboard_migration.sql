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

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied. Admin role required.';
  END IF;

  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM user_profiles),
    'total_seekers', (SELECT COUNT(*) FROM user_profiles WHERE role = 'seeker'),
    'total_employers', (SELECT COUNT(*) FROM user_profiles WHERE role = 'employer'),
    'total_admins', (SELECT COUNT(*) FROM user_profiles WHERE role = 'admin'),
    'disabled_users', (SELECT COUNT(*) FROM user_profiles WHERE is_disabled = true),
    'recent_signups', (
      SELECT COUNT(*) FROM user_profiles 
      WHERE created_at >= NOW() - INTERVAL '7 days'
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- Function to get job statistics
CREATE OR REPLACE FUNCTION get_job_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied. Admin role required.';
  END IF;

  SELECT json_build_object(
    'total_jobs', (SELECT COUNT(*) FROM job_posts),
    'active_jobs', (SELECT COUNT(*) FROM job_posts WHERE is_active = true AND admin_disabled = false),
    'closed_jobs', (SELECT COUNT(*) FROM job_posts WHERE is_active = false),
    'reported_jobs', (SELECT COUNT(*) FROM job_posts WHERE is_reported = true),
    'admin_disabled_jobs', (SELECT COUNT(*) FROM job_posts WHERE admin_disabled = true),
    'recent_posts', (
      SELECT COUNT(*) FROM job_posts 
      WHERE created_at >= NOW() - INTERVAL '7 days'
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- Function to get report statistics
CREATE OR REPLACE FUNCTION get_report_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied. Admin role required.';
  END IF;

  SELECT json_build_object(
    'total_user_reports', (SELECT COUNT(*) FROM user_reports),
    'pending_user_reports', (SELECT COUNT(*) FROM user_reports WHERE status = 'pending'),
    'total_job_reports', (SELECT COUNT(*) FROM job_reports),
    'pending_job_reports', (SELECT COUNT(*) FROM job_reports WHERE status = 'pending'),
    'resolved_reports', (
      SELECT COUNT(*) FROM (
        SELECT id FROM user_reports WHERE status = 'resolved'
        UNION ALL
        SELECT id FROM job_reports WHERE status = 'resolved'
      ) AS combined
    )
  ) INTO result;

  RETURN result;
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
