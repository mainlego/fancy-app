-- Fix album_photos INSERT policy
-- Run each statement separately if needed

-- Step 1: Drop existing policy (run this first)
DROP POLICY IF EXISTS "Users can add photos to own albums" ON album_photos;

-- Step 2: Create helper function
CREATE OR REPLACE FUNCTION check_album_ownership(album_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM albums
    WHERE id = album_uuid
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Grant execute on the function
GRANT EXECUTE ON FUNCTION check_album_ownership(UUID) TO authenticated;

-- Step 4: Create new policy
CREATE POLICY "Users can add photos to own albums"
  ON album_photos FOR INSERT
  TO authenticated
  WITH CHECK (check_album_ownership(album_id));

-- Step 5: Ensure SELECT policy exists for albums
DROP POLICY IF EXISTS "Users can view own albums" ON albums;
CREATE POLICY "Users can view own albums"
  ON albums FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
