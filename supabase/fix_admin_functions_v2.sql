-- Fix for Admin Dashboard Functions (Version 2)
-- Issue: Type mismatch for 'reporter_email' (varchar vs text).
-- Fix: Explicitly casting email columns to text.

-- 1. Fix get_job_reports
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
    u_reporter.email::text as reporter_email, -- Cast to text
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

-- 2. Fix get_user_reports
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
    u_reporter.email::text as reporter_email, -- Cast to text
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
