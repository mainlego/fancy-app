import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Admin statistics model
class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int premiumUsers;
  final int trialUsers;
  final int bannedUsers;
  final int pendingReports;
  final int totalAiProfiles;
  final int totalMatches;
  final int totalMessages;
  final double monthlyRevenue;
  final Map<String, int> usersByGender;
  final Map<String, int> usersByPlan;

  const AdminStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.premiumUsers = 0,
    this.trialUsers = 0,
    this.bannedUsers = 0,
    this.pendingReports = 0,
    this.totalAiProfiles = 0,
    this.totalMatches = 0,
    this.totalMessages = 0,
    this.monthlyRevenue = 0,
    this.usersByGender = const {},
    this.usersByPlan = const {},
  });
}

/// Admin service for backend operations
class AdminService {
  final SupabaseClient _client;

  AdminService(this._client);

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();

      return response?['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get admin dashboard statistics
  Future<AdminStats> getStats() async {
    try {
      // Total users
      final usersResponse = await _client
          .from('profiles')
          .select('id, profile_type, is_premium, is_banned, last_online');

      final users = usersResponse as List;
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      int activeUsers = 0;
      int premiumUsers = 0;
      int bannedUsers = 0;
      Map<String, int> usersByGender = {};

      for (final user in users) {
        // Active users (online in last 30 days)
        final lastOnline = user['last_online'] != null
            ? DateTime.tryParse(user['last_online'] as String)
            : null;
        if (lastOnline != null && lastOnline.isAfter(thirtyDaysAgo)) {
          activeUsers++;
        }

        // Premium users
        if (user['is_premium'] == true) {
          premiumUsers++;
        }

        // Banned users
        if (user['is_banned'] == true) {
          bannedUsers++;
        }

        // Users by gender/type
        final profileType = user['profile_type'] as String? ?? 'unknown';
        usersByGender[profileType] = (usersByGender[profileType] ?? 0) + 1;
      }

      // Subscriptions stats
      final subsResponse = await _client
          .from('subscriptions')
          .select('plan_type, is_active');

      final subs = subsResponse as List;
      int trialUsers = 0;
      Map<String, int> usersByPlan = {};

      for (final sub in subs) {
        if (sub['is_active'] == true) {
          final planType = sub['plan_type'] as String? ?? 'unknown';
          usersByPlan[planType] = (usersByPlan[planType] ?? 0) + 1;
          if (planType == 'trial') {
            trialUsers++;
          }
        }
      }

      // Pending reports
      final reportsResponse = await _client
          .from('user_reports')
          .select('id')
          .eq('status', 'pending');

      final pendingReports = (reportsResponse as List).length;

      // AI profiles count
      final aiResponse = await _client
          .from('ai_profiles')
          .select('id');

      final totalAiProfiles = (aiResponse as List).length;

      // Matches count
      final matchesResponse = await _client
          .from('matches')
          .select('id');

      final totalMatches = (matchesResponse as List).length;

      // Messages count
      final messagesResponse = await _client
          .from('messages')
          .select('id');

      final totalMessages = (messagesResponse as List).length;

      return AdminStats(
        totalUsers: users.length,
        activeUsers: activeUsers,
        premiumUsers: premiumUsers,
        trialUsers: trialUsers,
        bannedUsers: bannedUsers,
        pendingReports: pendingReports,
        totalAiProfiles: totalAiProfiles,
        totalMatches: totalMatches,
        totalMessages: totalMessages,
        usersByGender: usersByGender,
        usersByPlan: usersByPlan,
      );
    } catch (e) {
      print('Error getting admin stats: $e');
      return const AdminStats();
    }
  }

  /// Get all users with pagination
  Future<List<Map<String, dynamic>>> getUsers({
    int limit = 50,
    int offset = 0,
    String? search,
    String? profileType,
    bool? isPremium,
    bool? isBanned,
  }) async {
    try {
      var query = _client
          .from('profiles')
          .select('*, subscriptions(plan_type, is_active, end_date)');

      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,email.ilike.%$search%');
      }

      if (profileType != null) {
        query = query.eq('profile_type', profileType);
      }

      if (isPremium != null) {
        query = query.eq('is_premium', isPremium);
      }

      if (isBanned != null) {
        query = query.eq('is_banned', isBanned);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  /// Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*, subscriptions(*)')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _client
        .from('profiles')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Ban user
  Future<void> banUser(String userId, {String? reason, int? days}) async {
    final now = DateTime.now();
    final expiresAt = days != null ? now.add(Duration(days: days)) : null;

    await _client.from('user_bans').insert({
      'user_id': userId,
      'reason': reason ?? 'Banned by admin',
      'expires_at': expiresAt?.toIso8601String(),
      'is_permanent': days == null,
      'created_at': now.toIso8601String(),
    });

    await _client
        .from('profiles')
        .update({
          'is_banned': true,
          'ban_reason': reason,
          'ban_expires_at': expiresAt?.toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Unban user
  Future<void> unbanUser(String userId) async {
    await _client
        .from('user_bans')
        .delete()
        .eq('user_id', userId);

    await _client
        .from('profiles')
        .update({
          'is_banned': false,
          'ban_reason': null,
          'ban_expires_at': null,
        })
        .eq('id', userId);
  }

  /// Delete user and all their data
  Future<void> deleteUser(String userId) async {
    // Delete in correct order to respect foreign keys
    await _client.from('messages').delete().eq('sender_id', userId);
    await _client.from('chats').delete().or('participant1_id.eq.$userId,participant2_id.eq.$userId');
    await _client.from('matches').delete().or('user1_id.eq.$userId,user2_id.eq.$userId');
    await _client.from('likes').delete().or('from_user_id.eq.$userId,to_user_id.eq.$userId');
    await _client.from('subscriptions').delete().eq('user_id', userId);
    await _client.from('user_bans').delete().eq('user_id', userId);
    await _client.from('user_reports').delete().eq('reported_user_id', userId);
    await _client.from('profiles').delete().eq('id', userId);
  }

  /// Get all reports with pagination
  Future<List<Map<String, dynamic>>> getReports({
    int limit = 50,
    int offset = 0,
    String? status,
  }) async {
    try {
      var query = _client
          .from('user_reports')
          .select('*, reported_user:profiles!reported_user_id(id, name, avatar_url, photos)');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting reports: $e');
      return [];
    }
  }

  /// Update report status
  Future<void> updateReportStatus(String reportId, String status, {String? adminNote}) async {
    await _client
        .from('user_reports')
        .update({
          'status': status,
          'admin_note': adminNote,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  }

  /// Get all subscriptions with pagination
  Future<List<Map<String, dynamic>>> getSubscriptions({
    int limit = 50,
    int offset = 0,
    String? planType,
    bool? isActive,
  }) async {
    try {
      var query = _client
          .from('subscriptions')
          .select('*, profiles!user_id(id, name, avatar_url, email)');

      if (planType != null) {
        query = query.eq('plan_type', planType);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting subscriptions: $e');
      return [];
    }
  }

  /// Update subscription
  Future<void> updateSubscription(String subId, Map<String, dynamic> data) async {
    await _client
        .from('subscriptions')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', subId);
  }

  /// Grant premium to user
  Future<void> grantPremium(String userId, {
    required String planType,
    required int days,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    await _client.from('subscriptions').upsert(
      {
        'user_id': userId,
        'plan_type': planType,
        'start_date': now.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': true,
        'updated_at': now.toIso8601String(),
      },
      onConflict: 'user_id',
    );

    await _client
        .from('profiles')
        .update({'is_premium': true})
        .eq('id', userId);
  }

  /// Revoke premium from user
  Future<void> revokePremium(String userId) async {
    await _client
        .from('subscriptions')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);

    await _client
        .from('profiles')
        .update({'is_premium': false})
        .eq('id', userId);
  }

  /// Get all AI profiles
  Future<List<Map<String, dynamic>>> getAIProfiles() async {
    try {
      final response = await _client
          .from('ai_profiles')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting AI profiles: $e');
      return [];
    }
  }

  /// Create AI profile
  Future<String> createAIProfile(Map<String, dynamic> profile) async {
    final response = await _client
        .from('ai_profiles')
        .insert({
          ...profile,
          'is_ai': true,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Update AI profile
  Future<void> updateAIProfile(String profileId, Map<String, dynamic> data) async {
    await _client
        .from('ai_profiles')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', profileId);
  }

  /// Delete AI profile
  Future<void> deleteAIProfile(String profileId) async {
    await _client
        .from('ai_profiles')
        .delete()
        .eq('id', profileId);
  }

  /// Get verification requests
  Future<List<Map<String, dynamic>>> getVerificationRequests({String? status}) async {
    try {
      var query = _client
          .from('verification_requests')
          .select('*, profiles!user_id(id, name, avatar_url, photos)');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting verification requests: $e');
      return [];
    }
  }

  /// Update verification request
  Future<void> updateVerificationRequest(String requestId, {
    required String status,
    String? rejectionReason,
  }) async {
    final updateData = {
      'status': status,
      'reviewed_at': DateTime.now().toIso8601String(),
    };

    if (rejectionReason != null) {
      updateData['rejection_reason'] = rejectionReason;
    }

    await _client
        .from('verification_requests')
        .update(updateData)
        .eq('id', requestId);

    // If approved, update user profile
    if (status == 'approved') {
      final request = await _client
          .from('verification_requests')
          .select('user_id')
          .eq('id', requestId)
          .single();

      await _client
          .from('profiles')
          .update({'is_verified': true})
          .eq('id', request['user_id']);
    }
  }
}

/// Admin service provider
final adminServiceProvider = Provider<AdminService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminService(client);
});

/// Is admin provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.isAdmin();
});

/// Admin stats provider
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getStats();
});

/// Admin users provider
final adminUsersProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, filters) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getUsers(
    limit: filters['limit'] ?? 50,
    offset: filters['offset'] ?? 0,
    search: filters['search'],
    profileType: filters['profileType'],
    isPremium: filters['isPremium'],
    isBanned: filters['isBanned'],
  );
});

/// Admin reports provider
final adminReportsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getReports(status: status);
});

/// Admin subscriptions provider
final adminSubscriptionsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, filters) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getSubscriptions(
    planType: filters['planType'],
    isActive: filters['isActive'],
  );
});

/// Admin AI profiles provider
final adminAIProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getAIProfiles();
});

/// Admin verification requests provider
final adminVerificationRequestsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getVerificationRequests(status: status);
});
