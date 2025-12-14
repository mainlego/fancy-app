-- Migration: Add looking_for field to profiles table
-- Run this in Supabase SQL Editor to add the looking_for field

-- Add looking_for column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'looking_for') THEN
    ALTER TABLE profiles ADD COLUMN looking_for TEXT[] DEFAULT '{}';
  END IF;
END $$;

-- Update existing profiles with default looking_for based on profile_type
-- Men looking for women, women looking for men
UPDATE profiles
SET looking_for = CASE
  WHEN profile_type = 'man' THEN ARRAY['woman']::TEXT[]
  WHEN profile_type = 'woman' THEN ARRAY['man']::TEXT[]
  WHEN profile_type = 'manAndWoman' THEN ARRAY['woman', 'man']::TEXT[]
  WHEN profile_type = 'manPair' THEN ARRAY['man', 'manPair']::TEXT[]
  WHEN profile_type = 'womanPair' THEN ARRAY['woman', 'womanPair']::TEXT[]
  ELSE ARRAY['woman', 'man']::TEXT[]
END
WHERE looking_for IS NULL OR looking_for = '{}';

-- Add index for faster filtering
CREATE INDEX IF NOT EXISTS idx_profiles_looking_for ON profiles USING GIN(looking_for);

-- Verify the migration
SELECT id, name, profile_type, looking_for FROM profiles LIMIT 10;
