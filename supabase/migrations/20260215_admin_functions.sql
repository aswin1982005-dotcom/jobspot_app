-- ============================================================================
-- 1. get_admin_users_list
-- ============================================================================
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
    u.id as user_id,
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
  LEFT JOIN job_seeker_profiles s ON u.id = s.user_id
  LEFT JOIN employer_profiles e ON u.id = e.user_id
  WHERE 
    (role_filter IS NULL OR u.role::text = role_filter) AND
    (disabled_only IS NULL OR u.is_disabled = disabled_only)
  ORDER BY u.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- ============================================================================
-- 2. get_admin_dashboard_stats
-- ============================================================================
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
  -- Reuse existing logic or functions if available, or re-implement for speed
  -- For now, calling the existing functions if they exist, or implementing logic inline
  -- Assuming underlying tables: user_profiles, job_posts, user_reports, job_reports
  
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

-- ============================================================================
-- 3. get_admin_recent_activity
-- ============================================================================
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
    LEFT JOIN job_seeker_profiles s ON u.id = s.user_id AND u.role = 'seeker'
    LEFT JOIN employer_profiles e ON u.id = e.user_id AND u.role = 'employer'
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

-- ============================================================================
-- 4. get_admin_actions
-- ============================================================================
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
  JOIN user_profiles u ON a.admin_id = u.id
  LEFT JOIN job_seeker_profiles s ON u.id = s.user_id AND u.role = 'seeker'
  LEFT JOIN employer_profiles e ON u.id = e.user_id AND u.role = 'employer'
  ORDER BY a.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- ============================================================================
-- 5. get_job_reports
-- ============================================================================
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
  LEFT JOIN user_profiles res ON r.resolved_by = res.id
  LEFT JOIN job_seeker_profiles ress ON res.id = ress.user_id AND res.role = 'seeker'
  LEFT JOIN employer_profiles rese ON res.id = rese.user_id AND res.role = 'employer'
  WHERE (status_filter IS NULL OR r.status = status_filter)
  ORDER BY r.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;

-- ============================================================================
-- 6. get_user_reports
-- ============================================================================
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
  JOIN user_profiles u_reported ON r.reported_user_id = u_reported.id
  LEFT JOIN job_seeker_profiles s ON u_reported.id = s.user_id AND u_reported.role = 'seeker'
  LEFT JOIN employer_profiles e ON u_reported.id = e.user_id AND u_reported.role = 'employer'
  LEFT JOIN user_profiles res ON r.resolved_by = res.id
  LEFT JOIN job_seeker_profiles ress ON res.id = ress.user_id AND res.role = 'seeker'
  LEFT JOIN employer_profiles rese ON res.id = rese.user_id AND res.role = 'employer'
  WHERE (status_filter IS NULL OR r.status = status_filter)
  ORDER BY r.created_at DESC
  LIMIT page_limit OFFSET page_offset;
END;
$$;
