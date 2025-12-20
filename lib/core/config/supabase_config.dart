/// Supabase configuration
abstract class SupabaseConfig {
  /// Supabase project URL
  static const String url = 'https://relzfthdcshmlyugspij.supabase.co';

  /// Supabase anon/public key
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlbHpmdGhkY3NobWx5dWdzcGlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1NTAxMzQsImV4cCI6MjA4MTEyNjEzNH0.k1BCkHjcpY11DSfl6sb0CVXnDagjFamhih8BtKodk70';

  /// Supabase service role key (for admin operations, keep secret!)
  /// This should NEVER be used in client-side code in production
  static const String serviceRoleKey = '';

  /// Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String photosBucket = 'photos';
  static const String albumsBucket = 'albums';
  static const String chatMediaBucket = 'chat_media';
  static const String verificationsBucket = 'verifications';

  /// Table names
  static const String usersTable = 'users';
  static const String profilesTable = 'profiles';
  static const String matchesTable = 'matches';
  static const String likesTable = 'likes';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String blockedUsersTable = 'blocked_users';
  static const String settingsTable = 'user_settings';
  static const String albumsTable = 'albums';
  static const String photosTable = 'photos';
  static const String albumPhotosTable = 'album_photos';
  static const String albumAccessRequestsTable = 'album_access_requests';
  static const String filtersTable = 'user_filters';
  static const String subscriptionsTable = 'subscriptions';
  static const String aiProfilesTable = 'ai_profiles';
  static const String aiChatsTable = 'ai_chats';
  static const String aiMessagesTable = 'ai_messages';
  static const String userReportsTable = 'user_reports';
  static const String userBansTable = 'user_bans';
  static const String verificationRequestsTable = 'verification_requests';
  static const String hiddenUsersTable = 'hidden_users';
}
