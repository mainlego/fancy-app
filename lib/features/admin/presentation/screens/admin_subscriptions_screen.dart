import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Admin subscriptions management screen - responsive design
class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends ConsumerState<AdminSubscriptionsScreen> {
  String? _selectedPlan;
  bool? _isActive;

  Map<String, dynamic> get _filters => {
    'planType': _selectedPlan,
    'isActive': _isActive,
  };

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(adminSubscriptionsProvider(_filters));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final padding = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (only on desktop)
          if (!isMobile) ...[
            Row(
              children: [
                const Text(
                  'Subscriptions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => ref.invalidate(adminSubscriptionsProvider(_filters)),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Filters
          _buildFilters(isMobile),
          const SizedBox(height: 16),

          // Subscriptions list/table
          Expanded(
            child: subscriptionsAsync.when(
              data: (subscriptions) => isMobile
                  ? _buildSubscriptionsList(subscriptions)
                  : _buildSubscriptionsTable(subscriptions),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFD64557)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    return Wrap(
      spacing: isMobile ? 8 : 16,
      runSpacing: isMobile ? 8 : 12,
      children: [
        _FilterDropdown<String?>(
          value: _selectedPlan,
          hint: 'Plan',
          items: const {
            null: 'All',
            'trial': 'Trial',
            'weekly': 'Weekly',
            'monthly': 'Monthly',
            'yearly': 'Yearly',
          },
          onChanged: (value) => setState(() => _selectedPlan = value),
          compact: isMobile,
        ),
        _FilterDropdown<bool?>(
          value: _isActive,
          hint: 'Status',
          items: const {null: 'All', true: 'Active', false: 'Inactive'},
          onChanged: (value) => setState(() => _isActive = value),
          compact: isMobile,
        ),
        if (_selectedPlan != null || _isActive != null)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPlan = null;
                _isActive = null;
              });
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: Colors.white54,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
      ],
    );
  }

  // Mobile: Card list
  Widget _buildSubscriptionsList(List<Map<String, dynamic>> subscriptions) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Text(
          'No subscriptions found',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: subscriptions.length,
      itemBuilder: (context, index) => _SubscriptionCard(
        sub: subscriptions[index],
        onToggle: () => _toggleSubscription(subscriptions[index]),
        onExtend: () => _extendSubscription(subscriptions[index]),
      ),
    );
  }

  // Desktop: Data table
  Widget _buildSubscriptionsTable(List<Map<String, dynamic>> subscriptions) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Text(
          'No subscriptions found',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF2D2D2D)),
          columns: const [
            DataColumn(label: Text('User', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Plan', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Start', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('End', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Days Left', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
          ],
          rows: subscriptions.map((sub) => _buildSubscriptionRow(sub)).toList(),
        ),
      ),
    );
  }

  DataRow _buildSubscriptionRow(Map<String, dynamic> sub) {
    final profile = sub['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'Unknown';
    final email = profile?['email'] as String? ?? '';
    final avatarUrl = profile?['avatar_url'] as String?;
    final planType = sub['plan_type'] as String? ?? 'unknown';
    final isActive = sub['is_active'] == true;
    final startDate = sub['start_date'] as String?;
    final endDate = sub['end_date'] as String?;

    int daysLeft = 0;
    if (endDate != null) {
      final end = DateTime.tryParse(endDate);
      if (end != null) {
        daysLeft = end.difference(DateTime.now()).inDays;
        if (daysLeft < 0) daysLeft = 0;
      }
    }

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2D2D2D),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white54, size: 18) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        DataCell(_PlanBadge(planType: planType)),
        DataCell(_buildStatusBadge(isActive)),
        DataCell(Text(_formatDate(startDate), style: const TextStyle(color: Colors.white54, fontSize: 12))),
        DataCell(Text(_formatDate(endDate), style: const TextStyle(color: Colors.white54, fontSize: 12))),
        DataCell(_buildDaysLeftBadge(daysLeft, isActive)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isActive ? Icons.cancel : Icons.play_circle,
                  color: isActive ? Colors.orange : Colors.green,
                  size: 20,
                ),
                onPressed: () => _toggleSubscription(sub),
                tooltip: isActive ? 'Deactivate' : 'Activate',
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF4A90D9), size: 20),
                onPressed: () => _extendSubscription(sub),
                tooltip: 'Extend',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12),
      ),
    );
  }

  Widget _buildDaysLeftBadge(int daysLeft, bool isActive) {
    if (!isActive) {
      return const Text('-', style: TextStyle(color: Colors.white38));
    }

    Color color;
    if (daysLeft <= 3) {
      color = Colors.red;
    } else if (daysLeft <= 7) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$daysLeft days',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleSubscription(Map<String, dynamic> sub) async {
    final adminService = ref.read(adminServiceProvider);
    final subId = sub['id'] as String;
    final isActive = sub['is_active'] == true;

    try {
      await adminService.updateSubscription(subId, {'is_active': !isActive});
      ref.invalidate(adminSubscriptionsProvider(_filters));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Subscription deactivated' : 'Subscription activated'),
            backgroundColor: isActive ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _extendSubscription(Map<String, dynamic> sub) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const _ExtendDialog(),
    );

    if (result == null) return;

    final subId = sub['id'] as String;
    final currentEnd = sub['end_date'] as String?;
    DateTime baseDate = DateTime.now();

    if (currentEnd != null) {
      final parsed = DateTime.tryParse(currentEnd);
      if (parsed != null && parsed.isAfter(baseDate)) {
        baseDate = parsed;
      }
    }

    final newEndDate = baseDate.add(Duration(days: result));
    final adminService = ref.read(adminServiceProvider);

    try {
      await adminService.updateSubscription(subId, {
        'end_date': newEndDate.toIso8601String(),
        'is_active': true,
      });
      ref.invalidate(adminSubscriptionsProvider(_filters));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extended by $result days'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Mobile subscription card
class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final VoidCallback onToggle;
  final VoidCallback onExtend;

  const _SubscriptionCard({
    required this.sub,
    required this.onToggle,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final profile = sub['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'Unknown';
    final email = profile?['email'] as String? ?? '';
    final avatarUrl = profile?['avatar_url'] as String?;
    final planType = sub['plan_type'] as String? ?? 'unknown';
    final isActive = sub['is_active'] == true;
    final endDate = sub['end_date'] as String?;

    int daysLeft = 0;
    if (endDate != null && isActive) {
      final end = DateTime.tryParse(endDate);
      if (end != null) {
        daysLeft = end.difference(DateTime.now()).inDays;
        if (daysLeft < 0) daysLeft = 0;
      }
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: !isActive
            ? BorderSide(color: Colors.red.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2D2D2D),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white54, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _PlanBadge(planType: planType, small: true),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: daysLeft <= 3
                                ? Colors.red.withOpacity(0.2)
                                : daysLeft <= 7
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$daysLeft days',
                            style: TextStyle(
                              color: daysLeft <= 3
                                  ? Colors.red
                                  : daysLeft <= 7
                                      ? Colors.orange
                                      : Colors.green,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    isActive ? Icons.cancel : Icons.play_circle,
                    color: isActive ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF4A90D9), size: 24),
                  onPressed: onExtend,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final bool compact;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white38, fontSize: compact ? 13 : 14)),
          dropdownColor: const Color(0xFF2D2D2D),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          isDense: compact,
          items: items.entries.map((entry) {
            return DropdownMenuItem<T>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(color: Colors.white, fontSize: compact ? 13 : 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String planType;
  final bool small;

  const _PlanBadge({required this.planType, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'trial': Colors.grey,
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

    final color = colors[planType] ?? Colors.grey;
    final label = labels[planType] ?? planType;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ExtendDialog extends StatefulWidget {
  const _ExtendDialog();

  @override
  State<_ExtendDialog> createState() => _ExtendDialogState();
}

class _ExtendDialogState extends State<_ExtendDialog> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Extend Subscription', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select duration:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [7, 14, 30, 90, 180, 365].map((days) {
              final isSelected = _days == days;
              return ChoiceChip(
                label: Text(
                  days < 30 ? '$days d' : days < 365 ? '${days ~/ 30} mo' : '1 yr',
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFD64557),
                backgroundColor: const Color(0xFF2D2D2D),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                onSelected: (selected) {
                  if (selected) setState(() => _days = days);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _days),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD64557)),
          child: Text('Extend $_days days'),
        ),
      ],
    );
  }
}
