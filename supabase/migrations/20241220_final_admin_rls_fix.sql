-- FINAL FIX for Admin RLS Policies
-- Run this in Supabase SQL Editor
-- This script properly handles the function rename issue

-- ============================================
-- STEP 1: DROP the existing function first (IMPORTANT!)
-- ============================================
DROP FUNCTION IF EXISTS is_admin(uuid);

-- ============================================
-- STEP 2: Add is_admin column if not exists
-- ============================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- ============================================
-- STEP 3: Create SECURITY DEFINER function to check admin status
-- This function runs with elevated privileges and avoids RLS recursion
-- ============================================
CREATE OR REPLACE FUNCTION is_admin(check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT is_admin FROM profiles WHERE id = check_user_id),
    FALSE
  );
END;
$$;

-- ============================================
-- STEP 4: Drop ALL existing policies on profiles to start fresh
-- ============================================
DROP POLICY IF EXISTS "Users can view own profile or admin can view all" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile or admin can update all" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_policy" ON profiles;

-- ============================================
-- STEP 5: Enable RLS on profiles table
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 6: Create NEW policies with admin access
-- ============================================

-- SELECT: Users can view their own profile, OR admins can view all
CREATE POLICY "profiles_select_policy" ON profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR is_admin(auth.uid())
);

-- INSERT: Users can insert their own profile
CREATE POLICY "profiles_insert_policy" ON profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- UPDATE: Users can update their own profile, OR admins can update all
CREATE POLICY "profiles_update_policy" ON profiles
FOR UPDATE
TO authenticated
USING (
  id = auth.uid() OR is_admin(auth.uid())
)
WITH CHECK (
  id = auth.uid() OR is_admin(auth.uid())
);

-- DELETE: Only admins can delete profiles
CREATE POLICY "profiles_delete_policy" ON profiles
FOR DELETE
TO authenticated
USING (is_admin(auth.uid()));

-- ============================================
-- STEP 7: Fix subscriptions table RLS for admins
-- ============================================
DROP POLICY IF EXISTS "Users can view own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "subscriptions_select_policy" ON subscriptions;
DROP POLICY IF EXISTS "subscriptions_update_policy" ON subscriptions;
DROP POLICY IF EXISTS "subscriptions_insert_policy" ON subscriptions;

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can view their own, admins can view all
CREATE POLICY "subscriptions_select_policy" ON subscriptions
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR is_admin(auth.uid())
);

-- UPDATE: Users can update their own, admins can update all
CREATE POLICY "subscriptions_update_policy" ON subscriptions
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid() OR is_admin(auth.uid())
);

-- INSERT: Users can insert their own, admins can insert for anyone
CREATE POLICY "subscriptions_insert_policy" ON subscriptions
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() OR is_admin(auth.uid())
);

-- ============================================
-- STEP 8: Fix user_reports table RLS for admins
-- ============================================
ALTER TABLE user_reports ADD COLUMN IF NOT EXISTS admin_note TEXT;

DROP POLICY IF EXISTS "reports_select_policy" ON user_reports;
DROP POLICY IF EXISTS "reports_update_policy" ON user_reports;
DROP POLICY IF EXISTS "reports_insert_policy" ON user_reports;
DROP POLICY IF EXISTS "Users can create reports" ON user_reports;
DROP POLICY IF EXISTS "Admins can view all reports" ON user_reports;

ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can see their own reports, admins can see all
CREATE POLICY "reports_select_policy" ON user_reports
FOR SELECT
TO authenticated
USING (
  reporter_id = auth.uid() OR is_admin(auth.uid())
);

-- INSERT: Any authenticated user can create a report
CREATE POLICY "reports_insert_policy" ON user_reports
FOR INSERT
TO authenticated
WITH CHECK (reporter_id = auth.uid());

-- UPDATE: Only admins can update reports
CREATE POLICY "reports_update_policy" ON user_reports
FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()));

-- ============================================
-- STEP 9: Fix verification_requests table RLS for admins
-- ============================================
DROP POLICY IF EXISTS "verifications_select_policy" ON verification_requests;
DROP POLICY IF EXISTS "verifications_update_policy" ON verification_requests;
DROP POLICY IF EXISTS "verifications_insert_policy" ON verification_requests;

ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can see their own, admins can see all
CREATE POLICY "verifications_select_policy" ON verification_requests
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR is_admin(auth.uid())
);

-- INSERT: Users can create their own verification request
CREATE POLICY "verifications_insert_policy" ON verification_requests
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- UPDATE: Only admins can update verification status
CREATE POLICY "verifications_update_policy" ON verification_requests
FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()));

-- ============================================
-- STEP 10: Set yourself as admin
-- Replace 'your-email@example.com' with your actual email
-- ============================================
-- UPDATE profiles SET is_admin = TRUE WHERE email = 'your-email@example.com';

-- Or use your user ID:
-- UPDATE profiles SET is_admin = TRUE WHERE id = 'your-user-uuid-here';

-- ============================================
-- VERIFY: Test that the function works
-- ============================================
-- SELECT is_admin(auth.uid());

-- ============================================
-- DONE! Now admins can:
-- - View all profiles
-- - Update all profiles
-- - View all subscriptions
-- - Update subscriptions
-- - View and manage all reports
-- - View and manage verification requests
-- ============================================
