import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// App analytics screen with user engagement metrics
class AdminAppAnalyticsScreen extends ConsumerWidget {
  const AdminAppAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(appAnalyticsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (!isMobile) ...[
            Row(
              children: [
                const Text(
                  'App Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => ref.invalidate(appAnalyticsProvider),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Content
          Expanded(
            child: analyticsAsync.when(
              data: (analytics) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active users overview
                    _buildActiveUsersSection(analytics, isMobile),
                    const SizedBox(height: 32),

                    // New users stats
                    const Text(
                      'User Growth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNewUsersCards(analytics, isMobile),
                    const SizedBox(height: 32),

                    // User growth chart
                    const Text(
                      'New Users (30 days)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGrowthChart(analytics.userGrowthHistory, isMobile, 'newUsers', const Color(0xFF50C878)),
                    const SizedBox(height: 32),

                    // Activity chart
                    const Text(
                      'Daily Active Users (30 days)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGrowthChart(analytics.activityHistory, isMobile, 'activeUsers', const Color(0xFF4A90D9)),
                    const SizedBox(height: 32),

                    // Engagement metrics
                    const Text(
                      'Engagement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEngagementMetrics(analytics, isMobile),
                    const SizedBox(height: 32),

                    // Interaction stats
                    const Text(
                      'Interactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractionStats(analytics, isMobile),
                    const SizedBox(height: 32),

                    // Demographics - Age
                    if (analytics.usersByAge.isNotEmpty) ...[
                      const Text(
                        'Users by Age',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAgeDistribution(analytics.usersByAge, isMobile),
                      const SizedBox(height: 32),
                    ],

                    // Demographics - Country
                    if (analytics.usersByCountry.isNotEmpty) ...[
                      const Text(
                        'Users by Country',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCountryDistribution(analytics.usersByCountry, isMobile),
                      const SizedBox(height: 32),
                    ],

                    // Registration sources
                    if (analytics.registrationsBySource.isNotEmpty) ...[
                      const Text(
                        'Registration Sources',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSourceDistribution(analytics.registrationsBySource, isMobile),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFD64557)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(appAnalyticsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersSection(AppAnalytics analytics, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2D4A6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Active Users',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActiveUserCard(
                  label: 'DAU',
                  value: analytics.dau.toString(),
                  subtitle: 'Today',
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActiveUserCard(
                  label: 'WAU',
                  value: analytics.wau.toString(),
                  subtitle: 'This week',
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActiveUserCard(
                  label: 'MAU',
                  value: analytics.mau.toString(),
                  subtitle: 'This month',
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Stickiness (DAU/MAU): ${analytics.dauMauRatio.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewUsersCards(AppAnalytics analytics, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Today',
            value: analytics.newUsersToday.toString(),
            icon: Icons.person_add,
            color: const Color(0xFF50C878),
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(
          child: _MetricCard(
            title: 'This Week',
            value: analytics.newUsersWeek.toString(),
            icon: Icons.group_add,
            color: const Color(0xFF4A90D9),
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(
          child: _MetricCard(
            title: 'This Month',
            value: analytics.newUsersMonth.toString(),
            icon: Icons.trending_up,
            color: const Color(0xFF9B59B6),
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthChart(List<Map<String, dynamic>> history, bool isMobile, String key, Color color) {
    if (history.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final maxValue = history
        .map((d) => (d[key] as num?)?.toDouble() ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartHeight = isMobile ? 120.0 : 150.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.map((day) {
                final value = (day[key] as num?)?.toDouble() ?? 0.0;
                final height = maxValue > 0 ? (value / maxValue * chartHeight * 0.9) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${day['date']}: ${value.toInt()}',
                      child: Container(
                        height: height.clamp(2.0, chartHeight),
                        decoration: BoxDecoration(
                          color: value > 0 ? color : const Color(0xFF333333),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                history.first['date']?.toString().substring(5) ?? '',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
              Text(
                history.last['date']?.toString().substring(5) ?? '',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics(AppAnalytics analytics, bool isMobile) {
    final metrics = [
      {
        'label': 'Match Rate',
        'value': '${analytics.matchRate.toStringAsFixed(1)}%',
        'icon': Icons.favorite,
        'color': const Color(0xFFD64557),
      },
      {
        'label': 'Message Rate',
        'value': '${analytics.messageRate.toStringAsFixed(1)}%',
        'icon': Icons.message,
        'color': const Color(0xFF00CED1),
      },
    ];

    return Row(
      children: metrics.map((metric) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: metric == metrics.last ? 0 : (isMobile ? 8 : 16)),
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (metric['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (metric['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    metric['icon'] as IconData,
                    color: metric['color'] as Color,
                    size: isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric['label'] as String,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric['value'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionStats(AppAnalytics analytics, bool isMobile) {
    final stats = [
      {
        'label': 'Total Likes',
        'value': _formatNumber(analytics.totalLikes),
        'icon': Icons.thumb_up,
        'color': const Color(0xFF50C878),
      },
      {
        'label': 'Super Likes',
        'value': _formatNumber(analytics.totalSuperLikes),
        'icon': Icons.star,
        'color': const Color(0xFFFFD700),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: isMobile ? 8 : 16,
        mainAxisSpacing: isMobile ? 8 : 16,
        childAspectRatio: isMobile ? 1.5 : 2.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: isMobile ? 24 : 32,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat['label'] as String,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgeDistribution(Map<String, int> usersByAge, bool isMobile) {
    final total = usersByAge.values.fold(0, (a, b) => a + b);
    final sortedEntries = usersByAge.entries.toList()
      ..sort((a, b) => _ageGroupOrder(a.key).compareTo(_ageGroupOrder(b.key)));

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: sortedEntries.map((entry) {
          final percentage = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: isMobile ? 20 : 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90D9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${entry.value} (${(percentage * 100).toStringAsFixed(0)}%)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountryDistribution(Map<String, int> usersByCountry, bool isMobile) {
    final total = usersByCountry.values.fold(0, (a, b) => a + b);
    final sortedEntries = usersByCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCountries = sortedEntries.take(10).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: topCountries.map((entry) {
          final percentage = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: isMobile ? 80 : 100,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: isMobile ? 20 : 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59B6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSourceDistribution(Map<String, int> sources, bool isMobile) {
    final colors = {
      'organic': const Color(0xFF50C878),
      'referral': const Color(0xFFFFD700),
      'google': const Color(0xFF4285F4),
      'apple': const Color(0xFFAAAAAA),
      'facebook': const Color(0xFF1877F2),
      'instagram': const Color(0xFFE4405F),
    };

    final total = sources.values.fold(0, (a, b) => a + b);

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: sources.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
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
                _formatSourceName(entry.key),
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
                  fontSize: isMobile ? 18 : 22,
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

  int _ageGroupOrder(String ageGroup) {
    switch (ageGroup) {
      case '18-19':
        return 0;
      case '20-24':
        return 1;
      case '25-29':
        return 2;
      case '30-34':
        return 3;
      case '35-39':
        return 4;
      case '40-49':
        return 5;
      case '50+':
        return 6;
      default:
        return 99;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatSourceName(String source) {
    switch (source) {
      case 'organic':
        return 'Organic';
      case 'referral':
        return 'Referral';
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      default:
        return source;
    }
  }
}

class _ActiveUserCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final bool isMobile;

  const _ActiveUserCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: isMobile ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white54,
              fontSize: isMobile ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
