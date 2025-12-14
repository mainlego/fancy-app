-- FANCY Dating App - Test Profiles
-- Run this in Supabase SQL Editor to add test users for development
-- These profiles don't require auth accounts (they're just for testing discovery)

-- First, create test user IDs in auth.users (required for foreign key)
-- Note: In production, these would be real auth users

-- Insert test profiles directly (bypassing auth)
-- You may need to temporarily disable RLS or use service role key

-- Delete existing test profiles first (optional)
DELETE FROM profiles WHERE id IN (
    'aaaaaaaa-0001-0001-0001-000000000001',
    'aaaaaaaa-0001-0001-0001-000000000002',
    'aaaaaaaa-0001-0001-0001-000000000003',
    'aaaaaaaa-0001-0001-0001-000000000004',
    'aaaaaaaa-0001-0001-0001-000000000005',
    'aaaaaaaa-0001-0001-0001-000000000006',
    'aaaaaaaa-0001-0001-0001-000000000007',
    'aaaaaaaa-0001-0001-0001-000000000008'
);

-- Create test users in auth.users first (if not exists)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, instance_id, aud, role)
VALUES
    ('aaaaaaaa-0001-0001-0001-000000000001', 'test1@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000002', 'test2@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000003', 'test3@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000004', 'test4@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000005', 'test5@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000006', 'test6@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000007', 'test7@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    ('aaaaaaaa-0001-0001-0001-000000000008', 'test8@fancy.test', '$2a$10$PznXBRYT8RWy/cTQC4L6WOSG9.5gvJ2Fqx0xMy1hZ8vKXxVJcvIm2', NOW(), NOW(), NOW(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- Insert test profiles
INSERT INTO profiles (id, name, email, birth_date, bio, city, country, dating_goal, relationship_status, profile_type, photos, is_verified, is_online, is_premium, interests, languages, occupation, height_cm, last_online, created_at)
VALUES
    -- Women profiles
    ('aaaaaaaa-0001-0001-0001-000000000001', 'Emma', 'test1@fancy.test', '1998-05-15', 'Love hiking, coffee, and good conversations! Looking for someone who enjoys outdoor adventures.', 'Moscow', 'Russia', 'longTerm', 'single', 'woman',
     ARRAY['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=600&fit=crop', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=600&fit=crop'],
     true, true, false, ARRAY['Travel', 'Photography', 'Yoga', 'Books'], ARRAY['English', 'Russian'], 'Marketing Manager', 168, NOW(), NOW()),

    ('aaaaaaaa-0001-0001-0001-000000000002', 'Sofia', 'test2@fancy.test', '2000-01-10', 'Just here to meet new people and have fun! Music is my passion.', 'Moscow', 'Russia', 'casual', 'single', 'woman',
     ARRAY['https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=600&fit=crop'],
     true, true, true, ARRAY['Music', 'Dancing', 'Fashion', 'Art'], ARRAY['Russian', 'English'], 'DJ / Artist', 165, NOW() - interval '30 minutes', NOW()),

    ('aaaaaaaa-0001-0001-0001-000000000003', 'Anna', 'test3@fancy.test', '1996-08-22', 'Fitness enthusiast and food lover. Balance is key!', 'Saint Petersburg', 'Russia', 'anything', 'single', 'woman',
     ARRAY['https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=600&fit=crop'],
     false, false, false, ARRAY['Fitness', 'Cooking', 'Travel', 'Movies'], ARRAY['Russian'], 'Personal Trainer', 172, NOW() - interval '2 hours', NOW()),

    ('aaaaaaaa-0001-0001-0001-000000000004', 'Maria', 'test4@fancy.test', '1999-03-30', 'Tech geek by day, gamer by night. Looking for player 2!', 'Moscow', 'Russia', 'friendship', 'single', 'woman',
     ARRAY['https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=600&fit=crop', 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=600&fit=crop'],
     true, true, false, ARRAY['Gaming', 'Technology', 'Movies', 'Books'], ARRAY['English', 'Russian', 'Japanese'], 'Software Developer', 160, NOW() - interval '1 hour', NOW()),

    -- Men profiles
    ('aaaaaaaa-0001-0001-0001-000000000005', 'Alex', 'test5@fancy.test', '1995-08-22', 'Music lover and dog person. Let''s grab coffee and talk about life!', 'Saint Petersburg', 'Russia', 'longTerm', 'single', 'man',
     ARRAY['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop'],
     false, true, false, ARRAY['Music', 'Sports', 'Travel', 'Nature'], ARRAY['Russian', 'English'], 'Musician', 182, NOW(), NOW()),

    ('aaaaaaaa-0001-0001-0001-000000000006', 'Dmitry', 'test6@fancy.test', '1993-11-05', 'Entrepreneur and fitness enthusiast. Life is about growth!', 'Moscow', 'Russia', 'casual', 'single', 'man',
     ARRAY['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=600&fit=crop', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=600&fit=crop'],
     true, true, true, ARRAY['Fitness', 'Technology', 'Travel', 'Books'], ARRAY['Russian', 'English', 'German'], 'CEO / Founder', 185, NOW() - interval '15 minutes', NOW()),

    ('aaaaaaaa-0001-0001-0001-000000000007', 'Ivan', 'test7@fancy.test', '1997-07-14', 'Photographer exploring the world one shot at a time.', 'Moscow', 'Russia', 'anything', 'complicated', 'man',
     ARRAY['https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=600&fit=crop'],
     true, false, false, ARRAY['Photography', 'Art', 'Travel', 'Nature'], ARRAY['Russian', 'English'], 'Photographer', 178, NOW() - interval '5 hours', NOW()),

    ('aaaaaaaa-0001-0001-0001-000000000008', 'Mikhail', 'test8@fancy.test', '1994-02-28', 'Chef who believes food brings people together. Let me cook for you!', 'Saint Petersburg', 'Russia', 'longTerm', 'single', 'man',
     ARRAY['https://images.unsplash.com/photo-1463453091185-61582044d556?w=400&h=600&fit=crop', 'https://images.unsplash.com/photo-1507591064344-4c6ce005b128?w=400&h=600&fit=crop'],
     false, true, false, ARRAY['Cooking', 'Music', 'Movies', 'Travel'], ARRAY['Russian', 'Italian', 'French'], 'Chef', 180, NOW() - interval '45 minutes', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    bio = EXCLUDED.bio,
    photos = EXCLUDED.photos,
    is_online = EXCLUDED.is_online,
    last_online = EXCLUDED.last_online;

-- Verify inserted profiles
SELECT id, name, profile_type, dating_goal, is_online, city FROM profiles WHERE id LIKE 'aaaaaaaa%';
