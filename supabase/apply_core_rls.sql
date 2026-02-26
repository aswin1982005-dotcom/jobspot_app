-- Core Platform Row Level Security Policies
-- This migration script ensures standard users and administrators can securely 
-- interact with the app.

-- ============================================================================
-- 0. ADMIN HELPER FUNCTION 
-- ============================================================================
-- A SECURITY DEFINER function allows us to check if a user is an admin without
-- triggering RLS evaluation on user_profiles, preventing infinite recursion!

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  );
END;
$$;

-- ============================================================================
-- 1. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE job_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_seeker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE employer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_jobs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. JOB POSTS POLICIES
-- ============================================================================

-- Everyone can read active and non-disabled jobs
CREATE POLICY "Anyone can read active jobs" 
ON job_posts FOR SELECT 
TO public 
USING (is_active = true AND admin_disabled = false);

-- Employers can read all their own jobs (even inactive ones)
CREATE POLICY "Employers can read their own jobs" 
ON job_posts FOR SELECT 
TO authenticated 
USING (employer_id = auth.uid());

-- Employers can insert their own jobs
CREATE POLICY "Employers can insert their own jobs" 
ON job_posts FOR INSERT 
TO authenticated 
WITH CHECK (employer_id = auth.uid());

-- Employers can update their own jobs
CREATE POLICY "Employers can update their own jobs" 
ON job_posts FOR UPDATE 
TO authenticated 
USING (employer_id = auth.uid())
WITH CHECK (employer_id = auth.uid());

-- Admins can read all jobs
CREATE POLICY "Admins can read all jobs" 
ON job_posts FOR SELECT 
TO authenticated 
USING (is_admin());

-- Admins can update all jobs
CREATE POLICY "Admins can update all jobs" 
ON job_posts FOR UPDATE 
TO authenticated 
USING (is_admin());

-- ============================================================================
-- 3. JOB APPLICATIONS POLICIES
-- ============================================================================

-- Seekers can read their own applications
CREATE POLICY "Seekers can read their own applications" 
ON job_applications FOR SELECT 
TO authenticated 
USING (applicant_id = auth.uid());

-- Seekers can insert their own applications
CREATE POLICY "Seekers can apply to jobs" 
ON job_applications FOR INSERT 
TO authenticated 
WITH CHECK (applicant_id = auth.uid());

-- Seekers can update their own applications (e.g. withdraw/message)
CREATE POLICY "Seekers can update their own applications" 
ON job_applications FOR UPDATE 
TO authenticated 
USING (applicant_id = auth.uid() AND status = 'applied')
WITH CHECK (applicant_id = auth.uid());

-- Employers can read applications for their jobs
CREATE POLICY "Employers can read applications for their jobs" 
ON job_applications FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM job_posts 
    WHERE job_posts.id = job_applications.job_post_id 
    AND job_posts.employer_id = auth.uid()
  )
);

-- Employers can update applications for their jobs (change status)
CREATE POLICY "Employers can update applications for their jobs" 
ON job_applications FOR UPDATE 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM job_posts 
    WHERE job_posts.id = job_applications.job_post_id 
    AND job_posts.employer_id = auth.uid()
  )
);

-- Admins can read and update all applications
CREATE POLICY "Admins can read all applications" 
ON job_applications FOR SELECT 
TO authenticated 
USING (is_admin());

CREATE POLICY "Admins can update all applications" 
ON job_applications FOR UPDATE 
TO authenticated 
USING (is_admin());

-- ============================================================================
-- 4. PROFILES POLICIES
-- ============================================================================

-- Any authenticated user can read profiles (Seekers view Employers, Employers view Seekers)
CREATE POLICY "Authenticated users can read seeker profiles" 
ON job_seeker_profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read employer profiles" 
ON employer_profiles FOR SELECT TO authenticated USING (true);

-- Users can insert/update their own profile
CREATE POLICY "Users can insert their own seeker profile" 
ON job_seeker_profiles FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own seeker profile" 
ON job_seeker_profiles FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own employer profile" 
ON employer_profiles FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own employer profile" 
ON employer_profiles FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Admins can update any profile (moderation)
CREATE POLICY "Admins can update any seeker profile" 
ON job_seeker_profiles FOR UPDATE 
TO authenticated 
USING (is_admin());

CREATE POLICY "Admins can update any employer profile" 
ON employer_profiles FOR UPDATE 
TO authenticated 
USING (is_admin());

-- Also allow admins to update the core user_profiles table (This prevents the recursion!)
DROP POLICY IF EXISTS "Admins can update user profiles" ON user_profiles;
CREATE POLICY "Admins can update user profiles" 
ON user_profiles FOR UPDATE 
TO authenticated 
USING (is_admin());


-- ============================================================================
-- 5. NOTIFICATIONS POLICIES
-- ============================================================================

-- Users can read their own notifications
CREATE POLICY "Users can read their own notifications" 
ON notifications FOR SELECT 
TO authenticated 
USING (user_id = auth.uid());

-- System/Admins can insert notifications
CREATE POLICY "Admins can insert notifications" 
ON notifications FOR INSERT 
TO authenticated 
WITH CHECK (is_admin());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications" 
ON notifications FOR UPDATE 
TO authenticated 
USING (user_id = auth.uid());

-- Admins can manage all notifications
CREATE POLICY "Admins can manage all notifications" 
ON notifications FOR ALL 
TO authenticated 
USING (is_admin());

-- ============================================================================
-- 6. SAVED JOBS POLICIES
-- ============================================================================

-- Seekers can manage their saved jobs
CREATE POLICY "Seekers can read their saved jobs" 
ON saved_jobs FOR SELECT 
TO authenticated 
USING (seeker_id = auth.uid());

CREATE POLICY "Seekers can insert saved jobs" 
ON saved_jobs FOR INSERT 
TO authenticated 
WITH CHECK (seeker_id = auth.uid());

CREATE POLICY "Seekers can delete saved jobs" 
ON saved_jobs FOR DELETE 
TO authenticated 
USING (seeker_id = auth.uid());

-- Admins can view all saved jobs
CREATE POLICY "Admins can read all saved jobs" 
ON saved_jobs FOR SELECT 
TO authenticated 
USING (is_admin());
