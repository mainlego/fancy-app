import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Admin dashboard with statistics
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Stats grid
          Expanded(
            child: statsAsync.when(
              data: (stats) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main stats
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          title: 'Total Users',
                          value: stats.totalUsers.toString(),
                          icon: Icons.people,
                          color: const Color(0xFF4A90D9),
                        ),
                        _StatCard(
                          title: 'Active Users (30d)',
                          value: stats.activeUsers.toString(),
                          icon: Icons.trending_up,
                          color: const Color(0xFF50C878),
                        ),
                        _StatCard(
                          title: 'Premium Users',
                          value: stats.premiumUsers.toString(),
                          icon: Icons.star,
                          color: const Color(0xFFFFD700),
                        ),
                        _StatCard(
                          title: 'Trial Users',
                          value: stats.trialUsers.toString(),
                          icon: Icons.access_time,
                          color: const Color(0xFFFF9500),
                        ),
                        _StatCard(
                          title: 'Banned Users',
                          value: stats.bannedUsers.toString(),
                          icon: Icons.block,
                          color: const Color(0xFFFF3B30),
                        ),
                        _StatCard(
                          title: 'Pending Reports',
                          value: stats.pendingReports.toString(),
                          icon: Icons.warning,
                          color: const Color(0xFFFF6B6B),
                          highlight: stats.pendingReports > 0,
                        ),
                        _StatCard(
                          title: 'AI Profiles',
                          value: stats.totalAiProfiles.toString(),
                          icon: Icons.smart_toy,
                          color: const Color(0xFF9B59B6),
                        ),
                        _StatCard(
                          title: 'Total Matches',
                          value: stats.totalMatches.toString(),
                          icon: Icons.favorite,
                          color: const Color(0xFFD64557),
                        ),
                        _StatCard(
                          title: 'Total Messages',
                          value: _formatNumber(stats.totalMessages),
                          icon: Icons.message,
                          color: const Color(0xFF00CED1),
                        ),
                      ],
                    ),
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
                    _buildUsersByType(stats.usersByGender),
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
                    _buildSubscriptionsByPlan(stats.usersByPlan),
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

  Widget _buildUsersByType(Map<String, int> usersByGender) {
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
      'manAndWoman': 'Man & Woman',
      'manPair': 'Man Pair',
      'womanPair': 'Woman Pair',
    };

    final total = usersByGender.values.fold(0, (a, b) => a + b);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: usersByGender.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionsByPlan(Map<String, int> usersByPlan) {
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
      'trial': 'Trial (7 days)',
      'weekly': 'Weekly (\$5)',
      'monthly': 'Monthly (\$10)',
      'yearly': 'Yearly (\$25)',
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: usersByPlan.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.2) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
