-- Add is_admin column to profiles table for admin panel access
-- Run this migration in your Supabase SQL Editor

-- Add is_admin column
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Create index for faster admin lookups
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON profiles(is_admin) WHERE is_admin = TRUE;

-- Set yourself as admin (replace with your actual user ID)
-- UPDATE profiles SET is_admin = TRUE WHERE id = 'your-user-id-here';

-- Example: Set admin by email
-- UPDATE profiles SET is_admin = TRUE WHERE email = 'admin@example.com';

COMMENT ON COLUMN profiles.is_admin IS 'Whether this user has admin privileges';

-- Grant admin privileges to see all data (optional RLS policies for admin)
-- You may want to add these policies to allow admins to see all data

-- Example policy to allow admins to see all profiles
CREATE POLICY "Admins can view all profiles" ON profiles
FOR SELECT
TO authenticated
USING (
  auth.uid() IN (SELECT id FROM profiles WHERE is_admin = TRUE)
);

-- Example policy to allow admins to update all profiles
CREATE POLICY "Admins can update all profiles" ON profiles
FOR UPDATE
TO authenticated
USING (
  auth.uid() IN (SELECT id FROM profiles WHERE is_admin = TRUE)
);

-- Add admin note column to reports table
ALTER TABLE user_reports
ADD COLUMN IF NOT EXISTS admin_note TEXT;

COMMENT ON COLUMN user_reports.admin_note IS 'Note added by admin when reviewing the report';
