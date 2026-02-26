-- Migration: Add Phase 2 Features (Employer Verification & Screening Questions)
-- Date: 2026-02-25

-- 1. Add is_verified to employer_profiles
ALTER TABLE employer_profiles
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- 2. Add screening_questions to job_posts
-- We use TEXT ARRAY to store a list of questions (e.g., up to 3)
ALTER TABLE job_posts
ADD COLUMN IF NOT EXISTS screening_questions TEXT[] DEFAULT '{}';
