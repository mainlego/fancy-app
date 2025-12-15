-- Albums feature migration
-- Run this in Supabase SQL Editor

-- Create albums table
CREATE TABLE IF NOT EXISTS albums (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  privacy TEXT NOT NULL DEFAULT 'public' CHECK (privacy IN ('public', 'private')),
  cover_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create album_photos table
CREATE TABLE IF NOT EXISTS album_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  type TEXT NOT NULL DEFAULT 'photo' CHECK (type IN ('photo', 'video')),
  width INTEGER,
  height INTEGER,
  duration_ms INTEGER,
  is_private BOOLEAN DEFAULT false,
  view_duration_sec INTEGER,
  one_time_view BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create album_access_requests table
CREATE TABLE IF NOT EXISTS album_access_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
  created_at TIMESTAMPTZ DEFAULT now(),
  responded_at TIMESTAMPTZ,
  UNIQUE(album_id, requester_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_albums_user_id ON albums(user_id);
CREATE INDEX IF NOT EXISTS idx_album_photos_album_id ON album_photos(album_id);
CREATE INDEX IF NOT EXISTS idx_album_access_requests_owner_id ON album_access_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_album_access_requests_requester_id ON album_access_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_album_access_requests_album_id ON album_access_requests(album_id);
CREATE INDEX IF NOT EXISTS idx_album_access_requests_status ON album_access_requests(status);

-- Enable RLS
ALTER TABLE albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE album_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE album_access_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for albums

-- Users can view their own albums
CREATE POLICY "Users can view own albums"
  ON albums FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can view public albums of others
CREATE POLICY "Users can view public albums"
  ON albums FOR SELECT
  TO authenticated
  USING (privacy = 'public');

-- Users can view private albums they have access to
CREATE POLICY "Users can view private albums with access"
  ON albums FOR SELECT
  TO authenticated
  USING (
    privacy = 'private' AND
    EXISTS (
      SELECT 1 FROM album_access_requests
      WHERE album_id = albums.id
      AND requester_id = auth.uid()
      AND status = 'approved'
    )
  );

-- Users can create their own albums
CREATE POLICY "Users can create own albums"
  ON albums FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own albums
CREATE POLICY "Users can update own albums"
  ON albums FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can delete their own albums
CREATE POLICY "Users can delete own albums"
  ON albums FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for album_photos

-- Users can view photos from their own albums
CREATE POLICY "Users can view own album photos"
  ON album_photos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM albums
      WHERE albums.id = album_photos.album_id
      AND albums.user_id = auth.uid()
    )
  );

-- Users can view photos from public albums
CREATE POLICY "Users can view public album photos"
  ON album_photos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM albums
      WHERE albums.id = album_photos.album_id
      AND albums.privacy = 'public'
    )
  );

-- Users can view photos from private albums they have access to
CREATE POLICY "Users can view private album photos with access"
  ON album_photos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM albums a
      JOIN album_access_requests ar ON ar.album_id = a.id
      WHERE a.id = album_photos.album_id
      AND a.privacy = 'private'
      AND ar.requester_id = auth.uid()
      AND ar.status = 'approved'
    )
  );

-- Users can add photos to their own albums
CREATE POLICY "Users can add photos to own albums"
  ON album_photos FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM albums
      WHERE albums.id = album_photos.album_id
      AND albums.user_id = auth.uid()
    )
  );

-- Users can delete photos from their own albums
CREATE POLICY "Users can delete own album photos"
  ON album_photos FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM albums
      WHERE albums.id = album_photos.album_id
      AND albums.user_id = auth.uid()
    )
  );

-- RLS Policies for album_access_requests

-- Users can view access requests where they are the owner
CREATE POLICY "Owners can view access requests"
  ON album_access_requests FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

-- Users can view their own access requests
CREATE POLICY "Requesters can view own requests"
  ON album_access_requests FOR SELECT
  TO authenticated
  USING (requester_id = auth.uid());

-- Users can create access requests
CREATE POLICY "Users can create access requests"
  ON album_access_requests FOR INSERT
  TO authenticated
  WITH CHECK (requester_id = auth.uid());

-- Owners can update (approve/deny) access requests
CREATE POLICY "Owners can update access requests"
  ON album_access_requests FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid());

-- Owners can delete access requests (revoke access)
CREATE POLICY "Owners can delete access requests"
  ON album_access_requests FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- Create storage bucket for albums (if not exists)
-- Note: Run this separately in Supabase Dashboard > Storage
-- INSERT INTO storage.buckets (id, name, public) VALUES ('albums', 'albums', true)
-- ON CONFLICT (id) DO NOTHING;

-- Storage policies for albums bucket (run in SQL editor)
-- CREATE POLICY "Users can upload album photos"
--   ON storage.objects FOR INSERT
--   TO authenticated
--   WITH CHECK (bucket_id = 'albums' AND (storage.foldername(name))[1] = auth.uid()::text);

-- CREATE POLICY "Users can view album photos"
--   ON storage.objects FOR SELECT
--   TO authenticated
--   USING (bucket_id = 'albums');

-- CREATE POLICY "Users can delete own album photos"
--   ON storage.objects FOR DELETE
--   TO authenticated
--   USING (bucket_id = 'albums' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for albums updated_at
DROP TRIGGER IF EXISTS update_albums_updated_at ON albums;
CREATE TRIGGER update_albums_updated_at
    BEFORE UPDATE ON albums
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
