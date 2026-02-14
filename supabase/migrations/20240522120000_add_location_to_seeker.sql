ALTER TABLE job_seeker_profiles
ADD COLUMN IF NOT EXISTS latitude float8,
ADD COLUMN IF NOT EXISTS longitude float8,
ADD COLUMN IF NOT EXISTS address_line text,
ADD COLUMN IF NOT EXISTS preferred_distance int DEFAULT 50;

-- Optional: Create index if we plan to query *seekers* by location often
-- CREATE INDEX IF NOT EXISTS idx_seeker_location ON job_seeker_profiles(latitude, longitude);
