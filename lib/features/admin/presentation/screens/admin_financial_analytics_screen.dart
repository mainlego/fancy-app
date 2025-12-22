import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Financial analytics screen with revenue metrics and charts
class AdminFinancialAnalyticsScreen extends ConsumerWidget {
  const AdminFinancialAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(financialAnalyticsProvider);
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
                  'Financial Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => ref.invalidate(financialAnalyticsProvider),
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
                    // Revenue overview cards
                    _buildRevenueCards(context, analytics, isMobile),
                    const SizedBox(height: 32),

                    // MRR/ARR Section
                    _buildMrrArrSection(analytics, isMobile),
                    const SizedBox(height: 32),

                    // Revenue by Plan
                    const Text(
                      'Revenue by Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRevenueByPlan(analytics.revenueByPlan, isMobile),
                    const SizedBox(height: 32),

                    // Subscriptions breakdown
                    const Text(
                      'Active Subscriptions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSubscriptionsBreakdown(analytics.subscriptionsByPlan, isMobile),
                    const SizedBox(height: 32),

                    // Revenue History Chart
                    const Text(
                      'Revenue History (30 days)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRevenueChart(analytics.revenueHistory, isMobile),
                    const SizedBox(height: 32),

                    // Key Metrics
                    const Text(
                      'Key Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildKeyMetrics(analytics, isMobile),
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
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(financialAnalyticsProvider),
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

  Widget _buildRevenueCards(BuildContext context, FinancialAnalytics analytics, bool isMobile) {
    final cards = [
      _RevenueCardData(
        title: 'Today',
        value: '\$${analytics.todayRevenue.toStringAsFixed(2)}',
        icon: Icons.today,
        color: const Color(0xFF50C878),
      ),
      _RevenueCardData(
        title: 'This Week',
        value: '\$${analytics.weeklyRevenue.toStringAsFixed(2)}',
        icon: Icons.date_range,
        color: const Color(0xFF4A90D9),
      ),
      _RevenueCardData(
        title: 'This Month',
        value: '\$${analytics.monthlyRevenue.toStringAsFixed(2)}',
        icon: Icons.calendar_month,
        color: const Color(0xFF9B59B6),
      ),
      _RevenueCardData(
        title: 'Total Revenue',
        value: '\$${_formatCurrency(analytics.totalRevenue)}',
        icon: Icons.attach_money,
        color: const Color(0xFFFFD700),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: isMobile ? 12 : 16,
        mainAxisSpacing: isMobile ? 12 : 16,
        childAspectRatio: isMobile ? 1.2 : 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _RevenueCard(
          title: card.title,
          value: card.value,
          icon: card.icon,
          color: card.color,
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildMrrArrSection(FinancialAnalytics analytics, bool isMobile) {
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
          const Text(
            'Recurring Revenue',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MRR',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_formatCurrency(analytics.mrr)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monthly Recurring',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white24,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_formatCurrency(analytics.arr)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Annual Recurring',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByPlan(Map<String, double> revenueByPlan, bool isMobile) {
    if (revenueByPlan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No revenue data yet',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final colors = {
      'weekly': const Color(0xFFFF9500),
      'monthly': const Color(0xFF4A90D9),
      'yearly': const Color(0xFF50C878),
      'super_likes': const Color(0xFFFF69B4),
      'invisible_mode': const Color(0xFF9B59B6),
    };

    final total = revenueByPlan.values.fold(0.0, (a, b) => a + b);

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: revenueByPlan.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors[entry.key] ?? Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                _formatPlanName(entry.key),
                style: TextStyle(
                  color: colors[entry.key] ?? Colors.grey,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${entry.value.toStringAsFixed(2)}',
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

  Widget _buildSubscriptionsBreakdown(Map<String, int> subscriptionsByPlan, bool isMobile) {
    if (subscriptionsByPlan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No active subscriptions',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final colors = {
      'trial': const Color(0xFF808080),
      'weekly': const Color(0xFFFF9500),
      'monthly': const Color(0xFF4A90D9),
      'yearly': const Color(0xFF50C878),
    };

    final total = subscriptionsByPlan.values.fold(0, (a, b) => a + b);

    return Column(
      children: [
        // Progress bar
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF1A1A1A),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: subscriptionsByPlan.entries.map((entry) {
              final percentage = total > 0 ? entry.value / total : 0.0;
              return Expanded(
                flex: (percentage * 100).round().clamp(1, 100),
                child: Container(
                  color: colors[entry.key] ?? Colors.grey,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: isMobile ? 12 : 24,
          runSpacing: 8,
          children: subscriptionsByPlan.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[entry.key] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatPlanName(entry.key)}: ${entry.value}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> history, bool isMobile) {
    if (history.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No revenue history',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final maxRevenue = history.map((d) => (d['revenue'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b);
    final chartHeight = isMobile ? 150.0 : 200.0;

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
                final revenue = (day['revenue'] as num?)?.toDouble() ?? 0.0;
                final height = maxRevenue > 0 ? (revenue / maxRevenue * chartHeight * 0.9) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${day['date']}: \$${revenue.toStringAsFixed(2)}',
                      child: Container(
                        height: height.clamp(2.0, chartHeight),
                        decoration: BoxDecoration(
                          color: revenue > 0 ? const Color(0xFF50C878) : const Color(0xFF333333),
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

  Widget _buildKeyMetrics(FinancialAnalytics analytics, bool isMobile) {
    final metrics = [
      {
        'label': 'Conversion Rate',
        'value': '${analytics.conversionRate.toStringAsFixed(1)}%',
        'description': 'Free to paid',
        'color': const Color(0xFF4A90D9),
      },
      {
        'label': 'Avg Revenue/User',
        'value': '\$${analytics.avgRevenuePerUser.toStringAsFixed(2)}',
        'description': 'ARPU',
        'color': const Color(0xFF50C878),
      },
      {
        'label': 'Total Transactions',
        'value': analytics.totalTransactions.toString(),
        'description': 'All time',
        'color': const Color(0xFF9B59B6),
      },
      {
        'label': 'Churn Rate',
        'value': '${analytics.churnRate.toStringAsFixed(1)}%',
        'description': 'Monthly',
        'color': const Color(0xFFFF6B6B),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: isMobile ? 12 : 16,
        mainAxisSpacing: isMobile ? 12 : 16,
        childAspectRatio: isMobile ? 1.4 : 1.8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (metric['color'] as Color).withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric['label'] as String,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['value'] as String,
                style: TextStyle(
                  color: metric['color'] as Color,
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                metric['description'] as String,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: isMobile ? 10 : 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }

  String _formatPlanName(String plan) {
    switch (plan) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'trial':
        return 'Trial';
      case 'super_likes':
        return 'Super Likes';
      case 'invisible_mode':
        return 'Invisible';
      default:
        return plan;
    }
  }
}

class _RevenueCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _RevenueCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _RevenueCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  const _RevenueCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isMobile = false,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 28),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
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
