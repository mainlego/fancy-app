import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Admin verification requests screen
class AdminVerificationsScreen extends ConsumerStatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  ConsumerState<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends ConsumerState<AdminVerificationsScreen> {
  String _selectedStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    final verificationsAsync = ref.watch(adminVerificationRequestsProvider(_selectedStatus));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Verification Requests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: () => ref.invalidate(adminVerificationRequestsProvider(_selectedStatus)),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status tabs
          _buildStatusTabs(),
          const SizedBox(height: 16),

          // Verifications list
          Expanded(
            child: verificationsAsync.when(
              data: (verifications) => _buildVerificationsList(verifications),
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
      ('approved', 'Approved', Icons.check_circle, Colors.green),
      ('rejected', 'Rejected', Icons.cancel, Colors.red),
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

  Widget _buildVerificationsList(List<Map<String, dynamic>> verifications) {
    if (verifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedStatus == 'pending' ? Icons.verified_user : Icons.inbox,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatus == 'pending'
                  ? 'No pending verifications'
                  : 'No ${_selectedStatus} verifications',
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 0.85,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: verifications.length,
      itemBuilder: (context, index) {
        return _VerificationCard(
          verification: verifications[index],
          onAction: (approved, reason) => _handleAction(verifications[index], approved, reason),
        );
      },
    );
  }

  Future<void> _handleAction(Map<String, dynamic> verification, bool approved, String? reason) async {
    final adminService = ref.read(adminServiceProvider);
    final requestId = verification['id'] as String;

    try {
      await adminService.updateVerificationRequest(
        requestId,
        status: approved ? 'approved' : 'rejected',
        rejectionReason: reason,
      );
      ref.invalidate(adminVerificationRequestsProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Verification approved' : 'Verification rejected'),
            backgroundColor: approved ? Colors.green : Colors.red,
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

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> verification;
  final Function(bool approved, String? reason) onAction;

  const _VerificationCard({
    required this.verification,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final profile = verification['profiles'] as Map<String, dynamic>?;
    final userName = profile?['name'] as String? ?? 'Unknown';
    final avatarUrl = profile?['avatar_url'] as String?;
    final photos = profile?['photos'] as List<dynamic>? ?? [];
    final photoThumbsUp = verification['photo_thumbs_up'] as String?;
    final photoWave = verification['photo_wave'] as String?;
    final createdAt = verification['created_at'] as String?;
    final status = verification['status'] as String? ?? 'pending';
    final rejectionReason = verification['rejection_reason'] as String?;

    final firstPhoto = avatarUrl ?? (photos.isNotEmpty ? photos.first as String : null);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: status == 'pending'
            ? Border.all(color: Colors.orange.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3D3D3D),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Submitted ${_formatDate(createdAt)}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // Verification photos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbs up photo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thumbs Up',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(8),
                              image: photoThumbsUp != null
                                  ? DecorationImage(
                                      image: NetworkImage(photoThumbsUp),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: photoThumbsUp == null
                                ? const Center(
                                    child: Icon(Icons.image_not_supported, color: Colors.white24),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Wave photo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wave',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(8),
                              image: photoWave != null
                                  ? DecorationImage(
                                      image: NetworkImage(photoWave),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: photoWave == null
                                ? const Center(
                                    child: Icon(Icons.image_not_supported, color: Colors.white24),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rejection reason
          if (status == 'rejected' && rejectionReason != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rejectionReason,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Actions (only for pending)
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onAction(true, null),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    String selectedReason = 'Photos do not match';

    final reasons = [
      'Photos do not match',
      'Face not clearly visible',
      'Wrong pose',
      'Photo appears edited',
      'Suspicious activity',
      'Other',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Reject Verification', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select rejection reason:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...reasons.map((reason) {
                return RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() => selectedReason = value!);
                  },
                  title: Text(reason, style: const TextStyle(color: Colors.white)),
                  activeColor: const Color(0xFFD64557),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter custom reason...',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD64557)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final reason = selectedReason == 'Other' && reasonController.text.isNotEmpty
          ? reasonController.text
          : selectedReason;
      onAction(false, reason);
    }
    reasonController.dispose();
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
      'approved': Colors.green,
      'rejected': Colors.red,
    };

    final icons = {
      'pending': Icons.hourglass_empty,
      'approved': Icons.check_circle,
      'rejected': Icons.cancel,
    };

    final color = colors[status] ?? Colors.grey;
    final icon = icons[status] ?? Icons.help;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
