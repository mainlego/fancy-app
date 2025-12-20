import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Admin reports and moderation screen
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminReportsProvider(_selectedStatus));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Reports & Moderation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: () => ref.invalidate(adminReportsProvider(_selectedStatus)),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status tabs
          _buildStatusTabs(),
          const SizedBox(height: 16),

          // Reports list
          Expanded(
            child: reportsAsync.when(
              data: (reports) => _buildReportsList(reports),
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

  Widget _buildStatusTabs() {
    final statuses = [
      ('pending', 'Pending', Icons.hourglass_empty, Colors.orange),
      ('reviewed', 'Reviewed', Icons.check_circle, Colors.blue),
      ('resolved', 'Resolved', Icons.done_all, Colors.green),
      ('dismissed', 'Dismissed', Icons.cancel, Colors.grey),
    ];

    return Row(
      children: statuses.map((status) {
        final isSelected = _selectedStatus == status.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: isSelected ? status.$4.withOpacity(0.2) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = status.$1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: status.$4) : null,
                ),
                child: Row(
                  children: [
                    Icon(status.$3, color: status.$4, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      status.$2,
                      style: TextStyle(
                        color: isSelected ? status.$4 : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportsList(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedStatus == 'pending' ? Icons.check_circle : Icons.inbox,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatus == 'pending'
                  ? 'No pending reports'
                  : 'No ${_selectedStatus} reports',
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _ReportCard(
          report: reports[index],
          onAction: (action, note) => _handleReportAction(reports[index], action, note),
        );
      },
    );
  }

  Future<void> _handleReportAction(Map<String, dynamic> report, String action, String? note) async {
    final adminService = ref.read(adminServiceProvider);
    final reportId = report['id'] as String;

    try {
      await adminService.updateReportStatus(reportId, action, adminNote: note);

      // If action is to ban user
      if (action == 'resolved') {
        final reportedUserId = report['reported_user_id'] as String?;
        if (reportedUserId != null) {
          final shouldBan = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Ban User?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Do you want to ban this user as well?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Ban User'),
                ),
              ],
            ),
          );

          if (shouldBan == true) {
            await adminService.banUser(
              reportedUserId,
              reason: report['reason'] as String? ?? 'Multiple reports',
            );
          }
        }
      }

      ref.invalidate(adminReportsProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report marked as $action'),
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

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final Function(String action, String? note) onAction;

  const _ReportCard({
    required this.report,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final reportedUser = report['reported_user'] as Map<String, dynamic>?;
    final userName = reportedUser?['name'] as String? ?? 'Unknown';
    final avatarUrl = reportedUser?['avatar_url'] as String?;
    final photos = reportedUser?['photos'] as List<dynamic>? ?? [];
    final reason = report['reason'] as String? ?? 'No reason';
    final details = report['details'] as String?;
    final createdAt = report['created_at'] as String?;
    final status = report['status'] as String? ?? 'pending';

    final firstPhoto = avatarUrl ?? (photos.isNotEmpty ? photos.first as String : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: status == 'pending'
            ? Border.all(color: Colors.orange.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2D2D2D),
                backgroundImage: firstPhoto != null ? NetworkImage(firstPhoto) : null,
                child: firstPhoto == null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Reported ${_formatDate(createdAt)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 16),

          // Reason
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (details != null && details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),

          // Actions (only for pending)
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showActionDialog(context, 'dismissed'),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showActionDialog(context, 'reviewed'),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showActionDialog(context, 'resolved'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Resolve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, String action) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Mark as ${action[0].toUpperCase()}${action.substring(1)}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin Note (optional)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD64557)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'resolved'
                  ? Colors.green
                  : action == 'reviewed'
                      ? Colors.blue
                      : Colors.grey,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onAction(action, noteController.text.isEmpty ? null : noteController.text);
    }
    noteController.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': Colors.orange,
      'reviewed': Colors.blue,
      'resolved': Colors.green,
      'dismissed': Colors.grey,
    };

    final icons = {
      'pending': Icons.hourglass_empty,
      'reviewed': Icons.check_circle,
      'resolved': Icons.done_all,
      'dismissed': Icons.cancel,
    };

    final color = colors[status] ?? Colors.grey;
    final icon = icons[status] ?? Icons.help;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
