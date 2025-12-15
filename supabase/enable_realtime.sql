-- Enable Realtime for messages table
-- Run this SQL in your Supabase SQL Editor

-- First, check if the publication exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

-- Add messages table to the realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Also add chats table for chat updates
ALTER PUBLICATION supabase_realtime ADD TABLE chats;

-- Enable Row Level Security (RLS) policies for realtime
-- Make sure users can only subscribe to their own chats

-- Check current replication status
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';

-- Alternative: If the above doesn't work, try:
-- DROP PUBLICATION IF EXISTS supabase_realtime;
-- CREATE PUBLICATION supabase_realtime FOR TABLE messages, chats;
