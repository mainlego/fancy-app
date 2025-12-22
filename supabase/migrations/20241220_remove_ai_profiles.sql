-- Remove AI Profiles functionality from database
-- This migration drops all AI-related tables and functions

-- ============================================
-- STEP 1: Drop AI-related tables
-- ============================================

-- Drop AI messages table first (references ai_chats)
DROP TABLE IF EXISTS ai_messages CASCADE;

-- Drop AI chats table (references ai_profiles)
DROP TABLE IF EXISTS ai_chats CASCADE;

-- Drop AI profiles table
DROP TABLE IF EXISTS ai_profiles CASCADE;

-- ============================================
-- STEP 2: Drop AI-related functions
-- ============================================
DROP FUNCTION IF EXISTS increment_ai_message_count(uuid) CASCADE;

-- ============================================
-- STEP 3: Remove AI-related columns from user_reports (if any)
-- ============================================
ALTER TABLE user_reports DROP COLUMN IF EXISTS reported_by_ai_profile_id;

-- ============================================
-- STEP 4: Remove AI-related columns from user_bans (if any)
-- ============================================
ALTER TABLE user_bans DROP COLUMN IF EXISTS banned_by_ai_profile_id;

-- ============================================
-- STEP 5: Verify cleanup
-- ============================================
SELECT 'AI profiles functionality removed successfully!' as result;
