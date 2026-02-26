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
    'disabled', COUNT(*) FILTER (WHERE is_disabled = true),
    'recent_signups', COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days')
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
