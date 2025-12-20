-- FIX: Remove recursive admin policies that cause infinite recursion
-- Run this FIRST to fix the error

-- Drop the problematic policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- Add is_admin column if not exists
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Add admin_note column to reports table
ALTER TABLE user_reports
ADD COLUMN IF NOT EXISTS admin_note TEXT;

-- Create a security definer function to check admin status (avoids RLS recursion)
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM profiles WHERE id = user_id),
    FALSE
  );
$$;

-- Now create proper policies using the function

-- Policy: Users can view their own profile OR admins can view all
CREATE POLICY "Users can view own profile or admin can view all" ON profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR is_admin(auth.uid())
);

-- Policy: Users can update their own profile OR admins can update all
CREATE POLICY "Users can update own profile or admin can update all" ON profiles
FOR UPDATE
TO authenticated
USING (
  id = auth.uid() OR is_admin(auth.uid())
);

-- Set yourself as admin (replace with your actual user ID or email)
-- UPDATE profiles SET is_admin = TRUE WHERE id = 'your-user-id';
-- UPDATE profiles SET is_admin = TRUE WHERE email = 'your-email@example.com';

COMMENT ON FUNCTION is_admin IS 'Check if user is admin without triggering RLS recursion';
