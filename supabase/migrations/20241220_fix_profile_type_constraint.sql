-- Fix profile_type constraint to allow all valid values
-- Run this in Supabase SQL Editor

-- First, check for any existing constraints on profile_type
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'profiles'::regclass
-- AND conname LIKE '%profile_type%';

-- Drop any existing check constraint on profile_type
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    FOR constraint_name IN
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'profiles'::regclass
        AND pg_get_constraintdef(oid) LIKE '%profile_type%'
    LOOP
        EXECUTE format('ALTER TABLE profiles DROP CONSTRAINT IF EXISTS %I', constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Add the correct constraint with all valid profile types
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_profile_type_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_profile_type_check
CHECK (profile_type IN ('woman', 'man', 'manAndWoman', 'manPair', 'womanPair'));

-- Also add profile_type_changed_at column if not exists
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_type_changed_at TIMESTAMPTZ;

-- Verify the constraint
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'profiles'::regclass
AND conname LIKE '%profile_type%';
