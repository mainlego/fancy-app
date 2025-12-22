import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/debug_logger.dart';

/// Admin statistics model
class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int premiumUsers;
  final int trialUsers;
  final int bannedUsers;
  final int pendingReports;
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
    this.totalMatches = 0,
    this.totalMessages = 0,
    this.monthlyRevenue = 0,
    this.usersByGender = const {},
    this.usersByPlan = const {},
  });
}

/// Financial analytics model
class FinancialAnalytics {
  final double totalRevenue;
  final double monthlyRevenue;
  final double weeklyRevenue;
  final double todayRevenue;
  final double mrr; // Monthly Recurring Revenue
  final double arr; // Annual Recurring Revenue
  final double avgRevenuePerUser;
  final double conversionRate; // Free to paid
  final double churnRate;
  final int totalTransactions;
  final Map<String, double> revenueByPlan;
  final Map<String, int> subscriptionsByPlan;
  final List<Map<String, dynamic>> revenueHistory; // Last 30 days
  final List<Map<String, dynamic>> topPurchases;

  const FinancialAnalytics({
    this.totalRevenue = 0,
    this.monthlyRevenue = 0,
    this.weeklyRevenue = 0,
    this.todayRevenue = 0,
    this.mrr = 0,
    this.arr = 0,
    this.avgRevenuePerUser = 0,
    this.conversionRate = 0,
    this.churnRate = 0,
    this.totalTransactions = 0,
    this.revenueByPlan = const {},
    this.subscriptionsByPlan = const {},
    this.revenueHistory = const [],
    this.topPurchases = const [],
  });
}

/// App analytics model
class AppAnalytics {
  final int dau; // Daily Active Users
  final int wau; // Weekly Active Users
  final int mau; // Monthly Active Users
  final double dauMauRatio; // Stickiness
  final double retentionDay1;
  final double retentionDay7;
  final double retentionDay30;
  final int newUsersToday;
  final int newUsersWeek;
  final int newUsersMonth;
  final double avgSessionDuration; // minutes
  final double avgSwipesPerSession;
  final double matchRate;
  final double messageRate; // % of matches that message
  final int totalLikes;
  final int totalSuperLikes;
  final int totalPasses;
  final Map<String, int> usersByCountry;
  final Map<String, int> usersByAge;
  final List<Map<String, dynamic>> userGrowthHistory; // Last 30 days
  final List<Map<String, dynamic>> activityHistory; // Last 30 days
  final Map<String, int> registrationsBySource;

  const AppAnalytics({
    this.dau = 0,
    this.wau = 0,
    this.mau = 0,
    this.dauMauRatio = 0,
    this.retentionDay1 = 0,
    this.retentionDay7 = 0,
    this.retentionDay30 = 0,
    this.newUsersToday = 0,
    this.newUsersWeek = 0,
    this.newUsersMonth = 0,
    this.avgSessionDuration = 0,
    this.avgSwipesPerSession = 0,
    this.matchRate = 0,
    this.messageRate = 0,
    this.totalLikes = 0,
    this.totalSuperLikes = 0,
    this.totalPasses = 0,
    this.usersByCountry = const {},
    this.usersByAge = const {},
    this.userGrowthHistory = const [],
    this.activityHistory = const [],
    this.registrationsBySource = const {},
  });
}

/// Admin service for backend operations
class AdminService {
  final SupabaseClient _client;

  AdminService(this._client);

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final userId = _client.auth.currentUser?.id;
    print('AdminService.isAdmin: Checking admin status for user $userId');
    if (userId == null) {
      print('AdminService.isAdmin: No user ID, returning false');
      return false;
    }

    try {
      final response = await _client
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();

      final isAdmin = response?['is_admin'] == true;
      print('AdminService.isAdmin: User $userId is_admin = $isAdmin');
      return isAdmin;
    } catch (e) {
      print('AdminService.isAdmin ERROR: $e');
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

      final users = (usersResponse as List?) ?? [];
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

      final subs = (subsResponse as List?) ?? [];
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

      final pendingReports = ((reportsResponse as List?) ?? []).length;

      // Matches count
      final matchesResponse = await _client
          .from('matches')
          .select('id');

      final totalMatches = ((matchesResponse as List?) ?? []).length;

      // Messages count
      final messagesResponse = await _client
          .from('messages')
          .select('id');

      final totalMessages = ((messagesResponse as List?) ?? []).length;

      return AdminStats(
        totalUsers: users.length,
        activeUsers: activeUsers,
        premiumUsers: premiumUsers,
        trialUsers: trialUsers,
        bannedUsers: bannedUsers,
        pendingReports: pendingReports,
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
      logInfo('getUsers: Starting query...', tag: 'Admin');
      logDebug('getUsers: Current user ID = ${_client.auth.currentUser?.id}', tag: 'Admin');
      logDebug('getUsers: Filters - search=$search, profileType=$profileType, isPremium=$isPremium, isBanned=$isBanned', tag: 'Admin');

      var query = _client
          .from('profiles')
          .select('*');

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

      logDebug('getUsers: Executing profiles query...', tag: 'Admin');
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logError('getUsers: Query TIMEOUT after 15 seconds', tag: 'Admin');
              throw Exception('Query timeout - check RLS policies or database connection');
            },
          );

      final responseList = (response as List?) ?? [];
      logInfo('getUsers: Got ${responseList.length} profiles', tag: 'Admin');
      final users = List<Map<String, dynamic>>.from(responseList);

      // Fetch subscriptions separately for each user
      if (users.isNotEmpty) {
        final userIds = users.map((u) => u['id'] as String).toList();
        logDebug('getUsers: Fetching subscriptions for ${userIds.length} users...', tag: 'Admin');
        final subsResponse = await _client
            .from('subscriptions')
            .select('user_id, plan_type, is_active, end_date')
            .inFilter('user_id', userIds);

        final subsList = (subsResponse as List?) ?? [];
        logDebug('getUsers: Got ${subsList.length} subscriptions', tag: 'Admin');
        final subsMap = <String, Map<String, dynamic>>{};
        for (final sub in subsList) {
          subsMap[sub['user_id'] as String] = sub;
        }

        // Merge subscription data into users
        for (final user in users) {
          final userId = user['id'] as String;
          user['subscription'] = subsMap[userId];
        }
      }

      logInfo('getUsers: Completed successfully with ${users.length} users', tag: 'Admin');
      return users;
    } catch (e, stackTrace) {
      logError('getUsers ERROR', tag: 'Admin', error: e, stackTrace: stackTrace);
      rethrow; // Re-throw to show error in UI instead of silent empty list
    }
  }

  /// Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      // Fetch subscription separately
      final subResponse = await _client
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      response['subscription'] = subResponse;

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
      print('AdminService.getReports: Starting query...');

      // First, get reports without join to avoid RLS issues
      var query = _client
          .from('user_reports')
          .select('*');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('AdminService.getReports: Query TIMEOUT');
              throw Exception('Query timeout');
            },
          );

      final reportsList = (response as List?) ?? [];
      print('AdminService.getReports: Got ${reportsList.length} reports');
      final reports = List<Map<String, dynamic>>.from(reportsList);

      // Then fetch reported users' profiles separately
      if (reports.isNotEmpty) {
        final reportedUserIds = reports
            .map((r) => r['reported_user_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();

        if (reportedUserIds.isNotEmpty) {
          print('AdminService.getReports: Fetching profiles for ${reportedUserIds.length} reported users...');

          final profilesResponse = await _client
              .from('profiles')
              .select('id, name, avatar_url, photos')
              .inFilter('id', reportedUserIds);

          final profilesList = (profilesResponse as List?) ?? [];
          print('AdminService.getReports: Got ${profilesList.length} profiles');
          final profilesMap = <String, Map<String, dynamic>>{};
          for (final profile in profilesList) {
            profilesMap[profile['id'] as String] = Map<String, dynamic>.from(profile);
          }

          // Merge profile data into reports
          for (final report in reports) {
            final reportedUserId = report['reported_user_id'] as String?;
            if (reportedUserId != null) {
              report['reported_user'] = profilesMap[reportedUserId];
            }
          }
        }
      }

      print('AdminService.getReports: Completed successfully');
      return reports;
    } catch (e, stackTrace) {
      print('AdminService.getReports ERROR: $e');
      print('AdminService.getReports STACK: $stackTrace');
      rethrow;
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
      logInfo('getSubscriptions: Starting query...', tag: 'Admin');
      logDebug('getSubscriptions: Current user ID = ${_client.auth.currentUser?.id}', tag: 'Admin');
      logDebug('getSubscriptions: Filters - planType=$planType, isActive=$isActive', tag: 'Admin');

      // First, get subscriptions without join to avoid RLS issues
      var query = _client
          .from('subscriptions')
          .select('*');

      if (planType != null) {
        query = query.eq('plan_type', planType);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      logDebug('getSubscriptions: Executing subscriptions query...', tag: 'Admin');
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logError('getSubscriptions: Query TIMEOUT after 15 seconds', tag: 'Admin');
              throw Exception('Query timeout - check RLS policies or database connection');
            },
          );

      final subscriptionsList = (response as List?) ?? [];
      logInfo('getSubscriptions: Got ${subscriptionsList.length} subscriptions', tag: 'Admin');
      final subscriptions = List<Map<String, dynamic>>.from(subscriptionsList);

      // Then fetch profiles separately for each subscription
      if (subscriptions.isNotEmpty) {
        final userIds = subscriptions.map((s) => s['user_id'] as String).toSet().toList();
        logDebug('getSubscriptions: Fetching profiles for ${userIds.length} users...', tag: 'Admin');

        final profilesResponse = await _client
            .from('profiles')
            .select('id, name, avatar_url, email')
            .inFilter('id', userIds);

        final profilesList = (profilesResponse as List?) ?? [];
        logDebug('getSubscriptions: Got ${profilesList.length} profiles', tag: 'Admin');
        final profilesMap = <String, Map<String, dynamic>>{};
        for (final profile in profilesList) {
          profilesMap[profile['id'] as String] = Map<String, dynamic>.from(profile);
        }

        // Merge profile data into subscriptions
        for (final sub in subscriptions) {
          final userId = sub['user_id'] as String;
          sub['profiles'] = profilesMap[userId];
        }
      }

      logInfo('getSubscriptions: Completed successfully with ${subscriptions.length} subscriptions', tag: 'Admin');
      return subscriptions;
    } catch (e, stackTrace) {
      logError('getSubscriptions ERROR', tag: 'Admin', error: e, stackTrace: stackTrace);
      rethrow; // Re-throw to show error in UI instead of silent empty list
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

  /// Get verification requests
  Future<List<Map<String, dynamic>>> getVerificationRequests({String? status}) async {
    try {
      print('AdminService.getVerificationRequests: Starting query...');

      // First, get verification requests without join
      var query = _client
          .from('verification_requests')
          .select('*');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('AdminService.getVerificationRequests: Query TIMEOUT');
              throw Exception('Query timeout');
            },
          );

      final requestsList = (response as List?) ?? [];
      print('AdminService.getVerificationRequests: Got ${requestsList.length} requests');
      final requests = List<Map<String, dynamic>>.from(requestsList);

      // Then fetch profiles separately
      if (requests.isNotEmpty) {
        final userIds = requests
            .map((r) => r['user_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();

        if (userIds.isNotEmpty) {
          print('AdminService.getVerificationRequests: Fetching profiles for ${userIds.length} users...');

          final profilesResponse = await _client
              .from('profiles')
              .select('id, name, avatar_url, photos')
              .inFilter('id', userIds);

          final verProfilesList = (profilesResponse as List?) ?? [];
          print('AdminService.getVerificationRequests: Got ${verProfilesList.length} profiles');
          final profilesMap = <String, Map<String, dynamic>>{};
          for (final profile in verProfilesList) {
            profilesMap[profile['id'] as String] = Map<String, dynamic>.from(profile);
          }

          // Merge profile data into requests
          for (final request in requests) {
            final userId = request['user_id'] as String?;
            if (userId != null) {
              request['profiles'] = profilesMap[userId];
            }
          }
        }
      }

      print('AdminService.getVerificationRequests: Completed successfully');
      return requests;
    } catch (e, stackTrace) {
      print('AdminService.getVerificationRequests ERROR: $e');
      print('AdminService.getVerificationRequests STACK: $stackTrace');
      rethrow;
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

  /// Get financial analytics
  Future<FinancialAnalytics> getFinancialAnalytics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));
      final monthStart = todayStart.subtract(const Duration(days: 30));

      // Get all transactions/purchases
      List<dynamic> purchases = [];
      try {
        final purchasesResponse = await _client
            .from('purchases')
            .select('*')
            .order('created_at', ascending: false);
        purchases = (purchasesResponse as List?) ?? [];
      } catch (e) {
        // Table might not exist, continue with empty
      }

      // Calculate revenue metrics
      double totalRevenue = 0;
      double todayRevenue = 0;
      double weeklyRevenue = 0;
      double monthlyRevenue = 0;
      Map<String, double> revenueByPlan = {};
      Map<String, dynamic> dailyRevenue = {};

      for (final purchase in purchases) {
        final amount = (purchase['amount'] as num?)?.toDouble() ?? 0;
        final createdAt = DateTime.tryParse(purchase['created_at'] as String? ?? '');
        final productType = purchase['product_type'] as String? ?? 'other';

        totalRevenue += amount;
        revenueByPlan[productType] = (revenueByPlan[productType] ?? 0) + amount;

        if (createdAt != null) {
          if (createdAt.isAfter(todayStart)) {
            todayRevenue += amount;
          }
          if (createdAt.isAfter(weekStart)) {
            weeklyRevenue += amount;
          }
          if (createdAt.isAfter(monthStart)) {
            monthlyRevenue += amount;
          }

          // Track daily for history
          final dayKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
        }
      }

      // Get subscriptions data
      final subsResponse = await _client
          .from('subscriptions')
          .select('*');
      final subs = (subsResponse as List?) ?? [];

      Map<String, int> subscriptionsByPlan = {};
      int activeSubscriptions = 0;
      double mrr = 0;

      final planPrices = {
        'weekly': 5.0,
        'monthly': 10.0,
        'yearly': 25.0,
        'trial': 0.0,
      };

      for (final sub in subs) {
        final planType = sub['plan_type'] as String? ?? 'unknown';
        final isActive = sub['is_active'] == true;

        if (isActive) {
          subscriptionsByPlan[planType] = (subscriptionsByPlan[planType] ?? 0) + 1;
          activeSubscriptions++;

          // Calculate MRR
          if (planType == 'weekly') {
            mrr += (planPrices['weekly'] ?? 0) * 4.33; // ~4.33 weeks per month
          } else if (planType == 'monthly') {
            mrr += planPrices['monthly'] ?? 0;
          } else if (planType == 'yearly') {
            mrr += (planPrices['yearly'] ?? 0) / 12;
          }
        }
      }

      // Get total users for conversion rate
      final usersResponse = await _client
          .from('profiles')
          .select('id');
      final totalUsers = ((usersResponse as List?) ?? []).length;

      final paidUsers = subscriptionsByPlan.entries
          .where((e) => e.key != 'trial' && e.key != 'free')
          .fold(0, (sum, e) => sum + e.value);

      final conversionRate = totalUsers > 0 ? (paidUsers / totalUsers * 100) : 0.0;

      // Build revenue history
      List<Map<String, dynamic>> revenueHistory = [];
      for (int i = 29; i >= 0; i--) {
        final date = todayStart.subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        revenueHistory.add({
          'date': dayKey,
          'revenue': dailyRevenue[dayKey] ?? 0.0,
        });
      }

      return FinancialAnalytics(
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        weeklyRevenue: weeklyRevenue,
        todayRevenue: todayRevenue,
        mrr: mrr,
        arr: mrr * 12,
        avgRevenuePerUser: totalUsers > 0 ? totalRevenue / totalUsers : 0,
        conversionRate: conversionRate,
        churnRate: 0, // Would need historical data to calculate
        totalTransactions: purchases.length,
        revenueByPlan: revenueByPlan,
        subscriptionsByPlan: subscriptionsByPlan,
        revenueHistory: revenueHistory,
        topPurchases: purchases.take(10).map((p) => Map<String, dynamic>.from(p)).toList(),
      );
    } catch (e) {
      print('Error getting financial analytics: $e');
      return const FinancialAnalytics();
    }
  }

  /// Get app analytics
  Future<AppAnalytics> getAppAnalytics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));
      final monthStart = todayStart.subtract(const Duration(days: 30));

      // Get all users with activity data
      final usersResponse = await _client
          .from('profiles')
          .select('id, created_at, last_online, birth_date, country, registration_source');
      final users = (usersResponse as List?) ?? [];

      int dau = 0;
      int wau = 0;
      int mau = 0;
      int newUsersToday = 0;
      int newUsersWeek = 0;
      int newUsersMonth = 0;
      Map<String, int> usersByCountry = {};
      Map<String, int> usersByAge = {};
      Map<String, int> registrationsBySource = {};
      Map<String, int> dailyNewUsers = {};
      Map<String, int> dailyActiveUsers = {};

      for (final user in users) {
        final lastOnline = DateTime.tryParse(user['last_online'] as String? ?? '');
        final createdAt = DateTime.tryParse(user['created_at'] as String? ?? '');
        final birthDate = DateTime.tryParse(user['birth_date'] as String? ?? '');
        final country = user['country'] as String? ?? 'Unknown';
        final source = user['registration_source'] as String? ?? 'organic';

        // Activity tracking
        if (lastOnline != null) {
          if (lastOnline.isAfter(todayStart)) dau++;
          if (lastOnline.isAfter(weekStart)) wau++;
          if (lastOnline.isAfter(monthStart)) mau++;

          // Daily active history
          final dayKey = '${lastOnline.year}-${lastOnline.month.toString().padLeft(2, '0')}-${lastOnline.day.toString().padLeft(2, '0')}';
          dailyActiveUsers[dayKey] = (dailyActiveUsers[dayKey] ?? 0) + 1;
        }

        // New user tracking
        if (createdAt != null) {
          if (createdAt.isAfter(todayStart)) newUsersToday++;
          if (createdAt.isAfter(weekStart)) newUsersWeek++;
          if (createdAt.isAfter(monthStart)) newUsersMonth++;

          // Daily new users history
          final dayKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          dailyNewUsers[dayKey] = (dailyNewUsers[dayKey] ?? 0) + 1;
        }

        // Demographics
        usersByCountry[country] = (usersByCountry[country] ?? 0) + 1;
        registrationsBySource[source] = (registrationsBySource[source] ?? 0) + 1;

        if (birthDate != null) {
          final age = now.year - birthDate.year;
          String ageGroup;
          if (age < 20) {
            ageGroup = '18-19';
          } else if (age < 25) {
            ageGroup = '20-24';
          } else if (age < 30) {
            ageGroup = '25-29';
          } else if (age < 35) {
            ageGroup = '30-34';
          } else if (age < 40) {
            ageGroup = '35-39';
          } else if (age < 50) {
            ageGroup = '40-49';
          } else {
            ageGroup = '50+';
          }
          usersByAge[ageGroup] = (usersByAge[ageGroup] ?? 0) + 1;
        }
      }

      // Get likes data
      final likesResponse = await _client
          .from('likes')
          .select('id, is_super_like');
      final likes = (likesResponse as List?) ?? [];

      int totalLikes = 0;
      int totalSuperLikes = 0;
      for (final like in likes) {
        if (like['is_super_like'] == true) {
          totalSuperLikes++;
        } else {
          totalLikes++;
        }
      }

      // Get matches data
      final matchesResponse = await _client
          .from('matches')
          .select('id');
      final totalMatches = ((matchesResponse as List?) ?? []).length;

      // Get messages data
      final messagesResponse = await _client
          .from('messages')
          .select('id, match_id');
      final messages = (messagesResponse as List?) ?? [];

      // Calculate match rate (matches / total likes)
      final totalSwipes = totalLikes + totalSuperLikes;
      final matchRate = totalSwipes > 0 ? (totalMatches / totalSwipes * 100) : 0.0;

      // Calculate message rate (matches with messages / total matches)
      final matchesWithMessages = messages.map((m) => m['match_id']).toSet().length;
      final messageRate = totalMatches > 0 ? (matchesWithMessages / totalMatches * 100) : 0.0;

      // DAU/MAU ratio (stickiness)
      final dauMauRatio = mau > 0 ? (dau / mau * 100) : 0.0;

      // Build growth and activity history
      List<Map<String, dynamic>> userGrowthHistory = [];
      List<Map<String, dynamic>> activityHistory = [];
      for (int i = 29; i >= 0; i--) {
        final date = todayStart.subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        userGrowthHistory.add({
          'date': dayKey,
          'newUsers': dailyNewUsers[dayKey] ?? 0,
        });
        activityHistory.add({
          'date': dayKey,
          'activeUsers': dailyActiveUsers[dayKey] ?? 0,
        });
      }

      return AppAnalytics(
        dau: dau,
        wau: wau,
        mau: mau,
        dauMauRatio: dauMauRatio,
        retentionDay1: 0, // Would need cohort data
        retentionDay7: 0,
        retentionDay30: 0,
        newUsersToday: newUsersToday,
        newUsersWeek: newUsersWeek,
        newUsersMonth: newUsersMonth,
        avgSessionDuration: 0, // Would need session tracking
        avgSwipesPerSession: 0,
        matchRate: matchRate,
        messageRate: messageRate,
        totalLikes: totalLikes,
        totalSuperLikes: totalSuperLikes,
        totalPasses: 0, // Would need to track passes
        usersByCountry: usersByCountry,
        usersByAge: usersByAge,
        userGrowthHistory: userGrowthHistory,
        activityHistory: activityHistory,
        registrationsBySource: registrationsBySource,
      );
    } catch (e) {
      print('Error getting app analytics: $e');
      return const AppAnalytics();
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

/// Admin verification requests provider
final adminVerificationRequestsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getVerificationRequests(status: status);
});

/// Financial analytics provider
final financialAnalyticsProvider = FutureProvider<FinancialAnalytics>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getFinancialAnalytics();
});

/// App analytics provider
final appAnalyticsProvider = FutureProvider<AppAnalytics>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getAppAnalytics();
});
