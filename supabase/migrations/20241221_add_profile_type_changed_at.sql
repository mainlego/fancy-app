-- Add profile_type_changed_at column to profiles table
-- This column tracks when the user changed their profile type (can only change once)

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS profile_type_changed_at TIMESTAMPTZ DEFAULT NULL;

-- Add comment explaining the column
COMMENT ON COLUMN profiles.profile_type_changed_at IS 'Timestamp when profile type was changed. If not null, user cannot change profile type again.';

SELECT 'profile_type_changed_at column added successfully!' as result;
