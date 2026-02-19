-- Add experience_years and assets columns to job_posts table

ALTER TABLE job_posts 
ADD COLUMN IF NOT EXISTS experience_years TEXT,
ADD COLUMN IF NOT EXISTS assets TEXT[];

-- Add comment to explain columns
COMMENT ON COLUMN job_posts.experience_years IS 'Experience level required: 0-1, 1-3, 3-5, 5+';
COMMENT ON COLUMN job_posts.assets IS 'List of assets required/owned: Own Bike, Driving License, Smartphone, Laptop';
