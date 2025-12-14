-- ===========================================
-- AI PROFILES SCHEMA FOR FANCY APP
-- ===========================================
-- Run this script in Supabase SQL Editor to create all required tables

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===========================================
-- AI PROFILES TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS ai_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Basic info (same as regular profiles)
  name VARCHAR(100) NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 18 AND age <= 99),
  city VARCHAR(100) NOT NULL,
  country VARCHAR(100) DEFAULT 'Россия',
  bio TEXT,

  -- Photos
  avatar_url TEXT,
  photos TEXT[] DEFAULT ARRAY[]::TEXT[],

  -- Profile attributes
  dating_goal VARCHAR(50) DEFAULT 'casual',
  relationship_status VARCHAR(50) DEFAULT 'single',
  profile_type VARCHAR(50) DEFAULT 'woman',
  height_cm INTEGER,
  weight_kg INTEGER,
  zodiac_sign VARCHAR(50),
  occupation VARCHAR(100),
  languages TEXT[] DEFAULT ARRAY['Русский']::TEXT[],
  education VARCHAR(100),
  interests TEXT[] DEFAULT ARRAY[]::TEXT[],

  -- Lifestyle
  has_pets BOOLEAN DEFAULT FALSE,
  smokes BOOLEAN DEFAULT FALSE,
  drinks BOOLEAN DEFAULT FALSE,
  has_kids BOOLEAN DEFAULT FALSE,
  wants_kids BOOLEAN DEFAULT FALSE,

  -- AI personality
  personality_trait VARCHAR(100),
  communication_style VARCHAR(100),
  system_prompt TEXT,

  -- Status flags
  is_online BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT TRUE,
  is_premium BOOLEAN DEFAULT FALSE,
  is_ai BOOLEAN DEFAULT TRUE,  -- Always TRUE for AI profiles

  -- Statistics
  message_count INTEGER DEFAULT 0,
  report_count INTEGER DEFAULT 0,
  ban_count INTEGER DEFAULT 0,
  response_rate DECIMAL(3,2) DEFAULT 1.0,
  last_active_user_id UUID,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Index for finding active (non-expired) AI profiles
CREATE INDEX IF NOT EXISTS idx_ai_profiles_expires_at ON ai_profiles(expires_at);
CREATE INDEX IF NOT EXISTS idx_ai_profiles_is_ai ON ai_profiles(is_ai);

-- ===========================================
-- AI CHATS TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS ai_chats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ai_profile_id UUID NOT NULL REFERENCES ai_profiles(id) ON DELETE CASCADE,

  -- Last message preview
  last_message TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE,

  -- Status
  is_blocked BOOLEAN DEFAULT FALSE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Unique constraint - one chat per user-AI pair
  UNIQUE(user_id, ai_profile_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_chats_user_id ON ai_chats(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_chats_ai_profile_id ON ai_chats(ai_profile_id);

-- ===========================================
-- AI MESSAGES TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS ai_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID NOT NULL REFERENCES ai_chats(id) ON DELETE CASCADE,
  ai_profile_id UUID NOT NULL REFERENCES ai_profiles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Message content
  content TEXT NOT NULL,
  is_from_ai BOOLEAN NOT NULL,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_messages_chat_id ON ai_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_created_at ON ai_messages(created_at);

-- ===========================================
-- USER REPORTS TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS user_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Who was reported
  reported_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Who reported (can be user or AI)
  reported_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_by_ai_profile_id UUID REFERENCES ai_profiles(id) ON DELETE SET NULL,

  -- Report details
  reason VARCHAR(255) NOT NULL,
  details TEXT,

  -- Status: pending, reviewed, dismissed, action_taken
  status VARCHAR(50) DEFAULT 'pending',
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES auth.users(id),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user ON user_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_created_at ON user_reports(created_at);

-- ===========================================
-- USER BANS TABLE
-- ===========================================
CREATE TABLE IF NOT EXISTS user_bans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Who was banned
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Ban details
  reason VARCHAR(255) NOT NULL,
  banned_by_ai_profile_id UUID REFERENCES ai_profiles(id) ON DELETE SET NULL,
  banned_by_admin_id UUID REFERENCES auth.users(id),

  -- Duration
  expires_at TIMESTAMP WITH TIME ZONE,
  is_permanent BOOLEAN DEFAULT FALSE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_bans_user_id ON user_bans(user_id);
CREATE INDEX IF NOT EXISTS idx_user_bans_expires_at ON user_bans(expires_at);

-- ===========================================
-- ADD FIELDS TO PROFILES TABLE (if not exists)
-- ===========================================
DO $$
BEGIN
  -- Add is_banned field if not exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'is_banned') THEN
    ALTER TABLE profiles ADD COLUMN is_banned BOOLEAN DEFAULT FALSE;
  END IF;

  -- Add ban_reason field if not exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'ban_reason') THEN
    ALTER TABLE profiles ADD COLUMN ban_reason VARCHAR(255);
  END IF;

  -- Add ban_expires_at field if not exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'ban_expires_at') THEN
    ALTER TABLE profiles ADD COLUMN ban_expires_at TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- ===========================================
-- FUNCTION: Increment AI message count
-- ===========================================
CREATE OR REPLACE FUNCTION increment_ai_message_count(profile_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE ai_profiles
  SET message_count = message_count + 1,
      updated_at = NOW()
  WHERE id = profile_id;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- FUNCTION: Auto-update updated_at timestamp
-- ===========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to ai_profiles
DROP TRIGGER IF EXISTS update_ai_profiles_updated_at ON ai_profiles;
CREATE TRIGGER update_ai_profiles_updated_at
  BEFORE UPDATE ON ai_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to ai_chats
DROP TRIGGER IF EXISTS update_ai_chats_updated_at ON ai_chats;
CREATE TRIGGER update_ai_chats_updated_at
  BEFORE UPDATE ON ai_chats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- ADD is_admin TO PROFILES FIRST (before RLS policies)
-- ===========================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'is_admin') THEN
    ALTER TABLE profiles ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- ===========================================
-- ROW LEVEL SECURITY (RLS)
-- ===========================================

-- AI Profiles: Anyone can read active profiles, authenticated can insert/update
ALTER TABLE ai_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read active AI profiles" ON ai_profiles;
DROP POLICY IF EXISTS "Admins can manage AI profiles" ON ai_profiles;
DROP POLICY IF EXISTS "Authenticated can insert AI profiles" ON ai_profiles;

CREATE POLICY "Anyone can read active AI profiles" ON ai_profiles
  FOR SELECT USING (is_ai = TRUE AND expires_at > NOW());

-- Allow authenticated users to insert (for profile generation)
CREATE POLICY "Authenticated can insert AI profiles" ON ai_profiles
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Allow updates for authenticated users (simplified - in production use proper admin check)
CREATE POLICY "Authenticated can update AI profiles" ON ai_profiles
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated can delete AI profiles" ON ai_profiles
  FOR DELETE USING (auth.uid() IS NOT NULL);

-- AI Chats: Users can only see their own chats
ALTER TABLE ai_chats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own AI chats" ON ai_chats;
DROP POLICY IF EXISTS "Users can create own AI chats" ON ai_chats;
DROP POLICY IF EXISTS "Users can update own AI chats" ON ai_chats;

CREATE POLICY "Users can read own AI chats" ON ai_chats
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create own AI chats" ON ai_chats
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own AI chats" ON ai_chats
  FOR UPDATE USING (user_id = auth.uid());

-- AI Messages: Users can only see their own messages
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own AI messages" ON ai_messages;
DROP POLICY IF EXISTS "Users can create own AI messages" ON ai_messages;

CREATE POLICY "Users can read own AI messages" ON ai_messages
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create own AI messages" ON ai_messages
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- User Reports: Anyone authenticated can create, read own, admins read all
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can create reports" ON user_reports;
DROP POLICY IF EXISTS "Admins can read all reports" ON user_reports;
DROP POLICY IF EXISTS "Admins can update reports" ON user_reports;
DROP POLICY IF EXISTS "Users can read own reports" ON user_reports;

CREATE POLICY "Anyone can create reports" ON user_reports
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Users can see reports they created
CREATE POLICY "Users can read own reports" ON user_reports
  FOR SELECT USING (reported_by_user_id = auth.uid());

-- User Bans: Users can check own bans
ALTER TABLE user_bans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage bans" ON user_bans;
DROP POLICY IF EXISTS "Users can check own bans" ON user_bans;
DROP POLICY IF EXISTS "Authenticated can insert bans" ON user_bans;

-- Users can check if they are banned
CREATE POLICY "Users can check own bans" ON user_bans
  FOR SELECT USING (user_id = auth.uid());

-- Allow system to create bans (from AI reports)
CREATE POLICY "Authenticated can insert bans" ON user_bans
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ===========================================
-- GRANT PERMISSIONS
-- ===========================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_profiles TO authenticated;
GRANT ALL ON ai_chats TO authenticated;
GRANT ALL ON ai_messages TO authenticated;
GRANT SELECT, INSERT ON user_reports TO authenticated;
GRANT SELECT, INSERT ON user_bans TO authenticated;
