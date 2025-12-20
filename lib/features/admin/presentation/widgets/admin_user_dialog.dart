import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Dialog for viewing and editing user details
class AdminUserDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUpdate;

  const AdminUserDialog({
    super.key,
    required this.user,
    required this.onUpdate,
  });

  @override
  ConsumerState<AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends ConsumerState<AdminUserDialog> {
  late Map<String, dynamic> _user;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final name = _user['name'] as String? ?? 'Unknown';
    final email = _user['email'] as String? ?? '';
    final bio = _user['bio'] as String? ?? '';
    final avatarUrl = _user['avatar_url'] as String?;
    final photos = _user['photos'] as List<dynamic>? ?? [];
    final profileType = _user['profile_type'] as String? ?? 'unknown';
    final isBanned = _user['is_banned'] == true;
    final isPremium = _user['is_premium'] == true;
    final isVerified = _user['is_verified'] == true;
    final createdAt = _user['created_at'] as String?;
    final lastOnline = _user['last_online'] as String?;
    final subscription = _user['subscription'] as Map<String, dynamic>?;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF3D3D3D),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white54, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Color(0xFF4A90D9), size: 20),
                            ],
                          ],
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    tooltip: _isEditing ? 'Cancel' : 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusBadge(
                          label: profileType,
                          color: _getProfileTypeColor(profileType),
                        ),
                        _StatusBadge(
                          label: isBanned ? 'Banned' : 'Active',
                          color: isBanned ? Colors.red : Colors.green,
                        ),
                        _StatusBadge(
                          label: isPremium ? 'Premium' : 'Free',
                          color: isPremium ? Colors.amber : Colors.grey,
                        ),
                        if (isVerified)
                          const _StatusBadge(
                            label: 'Verified',
                            color: Color(0xFF4A90D9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bio
                    const Text(
                      'Bio',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio.isEmpty ? 'No bio' : bio,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 20),

                    // Photos
                    const Text(
                      'Photos',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (photos.isEmpty)
                      const Text('No photos', style: TextStyle(color: Colors.white38))
                    else
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(photos[index] as String),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Subscription details
                    const Text(
                      'Subscription',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (subscription == null)
                      const Text('No subscription', style: TextStyle(color: Colors.white38))
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow('Plan', subscription['plan_type'] ?? 'Unknown'),
                            _DetailRow('Active', subscription['is_active'] == true ? 'Yes' : 'No'),
                            _DetailRow('End Date', _formatDate(subscription['end_date'])),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Dates
                    const Text(
                      'Activity',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _DetailRow('Joined', _formatDate(createdAt)),
                          _DetailRow('Last Online', _formatDate(lastOnline)),
                        ],
                      ),
                    ),

                    // Admin actions
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFF3D3D3D)),
                      const SizedBox(height: 16),
                      const Text(
                        'Admin Actions',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Toggle verification
                      _ActionButton(
                        icon: isVerified ? Icons.verified_user : Icons.verified_user_outlined,
                        label: isVerified ? 'Remove Verification' : 'Verify User',
                        color: const Color(0xFF4A90D9),
                        onPressed: () => _toggleVerification(),
                      ),

                      const SizedBox(height: 8),

                      // Toggle premium
                      _ActionButton(
                        icon: isPremium ? Icons.star : Icons.star_border,
                        label: isPremium ? 'Revoke Premium' : 'Grant Premium',
                        color: Colors.amber,
                        onPressed: () => _togglePremium(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            if (_isEditing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF2D2D2D))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD64557),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getProfileTypeColor(String profileType) {
    return switch (profileType) {
      'woman' => const Color(0xFFFF69B4),
      'man' => const Color(0xFF4169E1),
      'manAndWoman' => const Color(0xFF9B59B6),
      'manPair' => const Color(0xFF3498DB),
      'womanPair' => const Color(0xFFE91E63),
      _ => Colors.grey,
    };
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Invalid';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleVerification() async {
    final adminService = ref.read(adminServiceProvider);
    final userId = _user['id'] as String;
    final isVerified = _user['is_verified'] == true;

    setState(() => _isSaving = true);
    try {
      await adminService.updateUser(userId, {'is_verified': !isVerified});
      setState(() {
        _user['is_verified'] = !isVerified;
        _isSaving = false;
      });
      widget.onUpdate();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _togglePremium() async {
    final adminService = ref.read(adminServiceProvider);
    final userId = _user['id'] as String;
    final isPremium = _user['is_premium'] == true;

    setState(() => _isSaving = true);
    try {
      if (isPremium) {
        await adminService.revokePremium(userId);
      } else {
        // Grant 30 days of monthly plan
        await adminService.grantPremium(userId, planType: 'monthly', days: 30);
      }
      setState(() {
        _user['is_premium'] = !isPremium;
        _isSaving = false;
      });
      widget.onUpdate();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    // Add any additional save logic here
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    widget.onUpdate();
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
