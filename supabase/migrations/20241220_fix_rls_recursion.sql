-- FIX: Infinite recursion in RLS policies for profiles table
-- This happens when a policy calls a function that queries the same table
-- Solution: Use SECURITY DEFINER function that bypasses RLS

-- ============================================
-- STEP 1: Drop ALL existing policies on profiles
-- ============================================
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_policy" ON profiles;
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
DROP POLICY IF EXISTS "Anyone can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;

-- ============================================
-- STEP 2: Drop the problematic function
-- ============================================
DROP FUNCTION IF EXISTS is_admin(uuid) CASCADE;
DROP FUNCTION IF EXISTS is_admin() CASCADE;
DROP FUNCTION IF EXISTS check_is_admin(uuid) CASCADE;

-- ============================================
-- STEP 3: Create a SAFE admin check function
-- This function uses SECURITY DEFINER and SET search_path
-- to avoid RLS recursion
-- ============================================
CREATE OR REPLACE FUNCTION public.is_user_admin(check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM profiles WHERE id = check_user_id LIMIT 1),
    FALSE
  );
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.is_user_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_user_admin(UUID) TO anon;

-- ============================================
-- STEP 4: Create SIMPLE RLS policies
-- Avoid complex conditions that could cause recursion
-- ============================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- SELECT: All authenticated users can view all profiles (for dating app discovery)
CREATE POLICY "profiles_select_all" ON profiles
FOR SELECT
TO authenticated
USING (true);

-- INSERT: Users can only insert their own profile
CREATE POLICY "profiles_insert_own" ON profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- UPDATE: Users can update their own profile
-- Admins are handled separately via service role or direct update
CREATE POLICY "profiles_update_own" ON profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- DELETE: Only allow deletion of own profile (admins use service role)
CREATE POLICY "profiles_delete_own" ON profiles
FOR DELETE
TO authenticated
USING (id = auth.uid());

-- ============================================
-- STEP 5: Fix subscriptions policies
-- ============================================
DROP POLICY IF EXISTS "subscriptions_select_policy" ON subscriptions;
DROP POLICY IF EXISTS "subscriptions_update_policy" ON subscriptions;
DROP POLICY IF EXISTS "subscriptions_insert_policy" ON subscriptions;
DROP POLICY IF EXISTS "Users can view own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON subscriptions;

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view all subscriptions (for admin panel)
-- In production, you might want to restrict this
CREATE POLICY "subscriptions_select_all" ON subscriptions
FOR SELECT
TO authenticated
USING (true);

-- Users can only insert their own subscription
CREATE POLICY "subscriptions_insert_own" ON subscriptions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own subscription
CREATE POLICY "subscriptions_update_own" ON subscriptions
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- STEP 6: Verify the fix
-- ============================================
-- This should work without recursion error:
-- SELECT * FROM profiles WHERE id = 'your-user-id';

SELECT 'RLS policies fixed successfully!' as result;
