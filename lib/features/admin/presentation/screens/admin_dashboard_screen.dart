import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Admin dashboard with statistics - responsive design
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (only on desktop, mobile has AppBar)
          if (!isMobile) ...[
            Row(
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => ref.invalidate(adminStatsProvider),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Stats grid
          Expanded(
            child: statsAsync.when(
              data: (stats) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main stats - responsive grid
                    _buildStatsGrid(context, stats, isMobile),
                    const SizedBox(height: 32),

                    // Users by type
                    const Text(
                      'Users by Profile Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUsersByType(stats.usersByGender, isMobile),
                    const SizedBox(height: 32),

                    // Subscriptions by plan
                    const Text(
                      'Subscriptions by Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSubscriptionsByPlan(stats.usersByPlan, isMobile),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFD64557)),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminStats stats, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate card width based on screen size
    int crossAxisCount;
    if (screenWidth < 400) {
      crossAxisCount = 2;
    } else if (screenWidth < 768) {
      crossAxisCount = 3;
    } else if (screenWidth < 1200) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    final statCards = [
      _StatCardData(
        title: 'Total Users',
        value: stats.totalUsers.toString(),
        icon: Icons.people,
        color: const Color(0xFF4A90D9),
      ),
      _StatCardData(
        title: 'Active (30d)',
        value: stats.activeUsers.toString(),
        icon: Icons.trending_up,
        color: const Color(0xFF50C878),
      ),
      _StatCardData(
        title: 'Premium',
        value: stats.premiumUsers.toString(),
        icon: Icons.star,
        color: const Color(0xFFFFD700),
      ),
      _StatCardData(
        title: 'Trial',
        value: stats.trialUsers.toString(),
        icon: Icons.access_time,
        color: const Color(0xFFFF9500),
      ),
      _StatCardData(
        title: 'Banned',
        value: stats.bannedUsers.toString(),
        icon: Icons.block,
        color: const Color(0xFFFF3B30),
      ),
      _StatCardData(
        title: 'Reports',
        value: stats.pendingReports.toString(),
        icon: Icons.warning,
        color: const Color(0xFFFF6B6B),
        highlight: stats.pendingReports > 0,
      ),
      _StatCardData(
        title: 'AI Profiles',
        value: stats.totalAiProfiles.toString(),
        icon: Icons.smart_toy,
        color: const Color(0xFF9B59B6),
      ),
      _StatCardData(
        title: 'Matches',
        value: stats.totalMatches.toString(),
        icon: Icons.favorite,
        color: const Color(0xFFD64557),
      ),
      _StatCardData(
        title: 'Messages',
        value: _formatNumber(stats.totalMessages),
        icon: Icons.message,
        color: const Color(0xFF00CED1),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isMobile ? 8 : 16,
        mainAxisSpacing: isMobile ? 8 : 16,
        childAspectRatio: isMobile ? 1.1 : 1.3,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) {
        final card = statCards[index];
        return _StatCard(
          title: card.title,
          value: card.value,
          icon: card.icon,
          color: card.color,
          highlight: card.highlight,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildUsersByType(Map<String, int> usersByGender, bool isMobile) {
    if (usersByGender.isEmpty) {
      return const Text(
        'No data available',
        style: TextStyle(color: Colors.white54),
      );
    }

    final colors = {
      'woman': const Color(0xFFFF69B4),
      'man': const Color(0xFF4169E1),
      'manAndWoman': const Color(0xFF9B59B6),
      'manPair': const Color(0xFF3498DB),
      'womanPair': const Color(0xFFE91E63),
    };

    final labels = {
      'woman': 'Women',
      'man': 'Men',
      'manAndWoman': 'M & W',
      'manPair': 'M Pair',
      'womanPair': 'W Pair',
    };

    final total = usersByGender.values.fold(0, (a, b) => a + b);

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: usersByGender.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors[entry.key] ?? Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                labels[entry.key] ?? entry.key,
                style: TextStyle(
                  color: colors[entry.key] ?? Colors.grey,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.value}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionsByPlan(Map<String, int> usersByPlan, bool isMobile) {
    if (usersByPlan.isEmpty) {
      return const Text(
        'No subscription data available',
        style: TextStyle(color: Colors.white54),
      );
    }

    final colors = {
      'trial': const Color(0xFF808080),
      'weekly': const Color(0xFFFF9500),
      'monthly': const Color(0xFF4A90D9),
      'yearly': const Color(0xFF50C878),
    };

    final labels = {
      'trial': 'Trial',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
    };

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: usersByPlan.entries.map((entry) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors[entry.key] ?? Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                labels[entry.key] ?? entry.key,
                style: TextStyle(
                  color: colors[entry.key] ?? Colors.grey,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.value}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;
  final bool isMobile;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.2) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isMobile ? 20 : 24),
              const Spacer(),
              if (highlight)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white54,
              fontSize: isMobile ? 11 : 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
