import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';

/// Admin AI profiles management screen
class AdminAIProfilesScreen extends ConsumerStatefulWidget {
  const AdminAIProfilesScreen({super.key});

  @override
  ConsumerState<AdminAIProfilesScreen> createState() => _AdminAIProfilesScreenState();
}

class _AdminAIProfilesScreenState extends ConsumerState<AdminAIProfilesScreen> {
  @override
  Widget build(BuildContext context) {
    final aiProfilesAsync = ref.watch(adminAIProfilesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'AI Profiles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create AI Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64557),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54),
                onPressed: () => ref.invalidate(adminAIProfilesProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AI Profiles grid
          Expanded(
            child: aiProfilesAsync.when(
              data: (profiles) => _buildProfilesGrid(profiles),
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

  Widget _buildProfilesGrid(List<Map<String, dynamic>> profiles) {
    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No AI profiles created yet',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create First AI Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64557),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        return _AIProfileCard(
          profile: profiles[index],
          onEdit: () => _showEditDialog(profiles[index]),
          onDelete: () => _deleteProfile(profiles[index]),
        );
      },
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _AIProfileDialog(
        onSave: (data) async {
          final adminService = ref.read(adminServiceProvider);
          await adminService.createAIProfile(data);
          ref.invalidate(adminAIProfilesProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI Profile created'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => _AIProfileDialog(
        profile: profile,
        onSave: (data) async {
          final adminService = ref.read(adminServiceProvider);
          await adminService.updateAIProfile(profile['id'] as String, data);
          ref.invalidate(adminAIProfilesProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI Profile updated'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProfile(Map<String, dynamic> profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete AI Profile', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${profile['name']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminService = ref.read(adminServiceProvider);
      await adminService.deleteAIProfile(profile['id'] as String);
      ref.invalidate(adminAIProfilesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Profile deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AIProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AIProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'Unknown';
    final bio = profile['bio'] as String? ?? '';
    final avatarUrl = profile['avatar_url'] as String?;
    final photos = profile['photos'] as List<dynamic>? ?? [];
    final profileType = profile['profile_type'] as String? ?? 'woman';
    final expiresAt = profile['expires_at'] as String?;
    final messageCount = profile['message_count'] as int? ?? 0;

    final firstPhoto = avatarUrl ?? (photos.isNotEmpty ? photos.first as String : null);

    bool isExpired = false;
    if (expiresAt != null) {
      final expiry = DateTime.tryParse(expiresAt);
      isExpired = expiry != null && expiry.isBefore(DateTime.now());
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: isExpired
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: firstPhoto != null
                      ? Image.network(
                          firstPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF2D2D2D),
                            child: const Icon(Icons.smart_toy, color: Colors.white38, size: 48),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2D2D2D),
                          child: const Icon(Icons.smart_toy, color: Colors.white38, size: 48),
                        ),
                ),
                // AI badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('AI', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                // Expired badge
                if (isExpired)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EXPIRED',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // Profile type badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _ProfileTypeBadge(profileType: profileType),
                ),
              ],
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bio.isEmpty ? 'No bio' : bio,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.message, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$messageCount messages',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  final String profileType;

  const _ProfileTypeBadge({required this.profileType});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'woman': const Color(0xFFFF69B4),
      'man': const Color(0xFF4169E1),
      'manAndWoman': const Color(0xFF9B59B6),
      'manPair': const Color(0xFF3498DB),
      'womanPair': const Color(0xFFE91E63),
    };

    final labels = {
      'woman': 'Woman',
      'man': 'Man',
      'manAndWoman': 'Couple',
      'manPair': 'Men',
      'womanPair': 'Women',
    };

    final color = colors[profileType] ?? Colors.grey;
    final label = labels[profileType] ?? profileType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _AIProfileDialog extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final Function(Map<String, dynamic>) onSave;

  const _AIProfileDialog({
    this.profile,
    required this.onSave,
  });

  @override
  State<_AIProfileDialog> createState() => _AIProfileDialogState();
}

class _AIProfileDialogState extends State<_AIProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _systemPromptController;
  late String _profileType;
  late int _expiryDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?['name'] as String? ?? '');
    _bioController = TextEditingController(text: widget.profile?['bio'] as String? ?? '');
    _avatarUrlController = TextEditingController(text: widget.profile?['avatar_url'] as String? ?? '');
    _systemPromptController = TextEditingController(text: widget.profile?['system_prompt'] as String? ?? _defaultSystemPrompt);
    _profileType = widget.profile?['profile_type'] as String? ?? 'woman';
    _expiryDays = 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  static const _defaultSystemPrompt = '''You are a friendly, flirty AI companion on a dating app. You should:
- Be warm, engaging, and playful
- Show genuine interest in the user
- Keep conversations light and fun
- Be supportive and positive
- Respect boundaries
- Report any inappropriate behavior to moderators

Never:
- Share personal information
- Encourage meeting in person
- Discuss explicit content
- Pretend to be a real human''';

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null;

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
                  const Icon(Icons.smart_toy, color: Color(0xFF9B59B6)),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit AI Profile' : 'Create AI Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'e.g., Sophie',
                    ),
                    const SizedBox(height: 16),

                    // Profile type
                    const Text(
                      'Profile Type',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['woman', 'man', 'manAndWoman', 'manPair', 'womanPair'].map((type) {
                        final isSelected = _profileType == type;
                        final labels = {
                          'woman': 'Woman',
                          'man': 'Man',
                          'manAndWoman': 'Couple',
                          'manPair': 'Men Pair',
                          'womanPair': 'Women Pair',
                        };
                        return ChoiceChip(
                          label: Text(labels[type]!),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD64557),
                          backgroundColor: const Color(0xFF2D2D2D),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _profileType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'A short bio for this AI profile...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Avatar URL
                    _buildTextField(
                      controller: _avatarUrlController,
                      label: 'Avatar URL',
                      hint: 'https://example.com/avatar.jpg',
                    ),
                    const SizedBox(height: 16),

                    // Expiry (only for new profiles)
                    if (!isEditing) ...[
                      const Text(
                        'Expires After',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [7, 14, 30, 90, 180, 365].map((days) {
                          final isSelected = _expiryDays == days;
                          return ChoiceChip(
                            label: Text(days < 30 ? '$days days' : days < 365 ? '${days ~/ 30} months' : '1 year'),
                            selected: isSelected,
                            selectedColor: const Color(0xFFD64557),
                            backgroundColor: const Color(0xFF2D2D2D),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _expiryDays = days);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // System prompt
                    _buildTextField(
                      controller: _systemPromptController,
                      label: 'System Prompt (AI Behavior)',
                      hint: 'Instructions for how this AI should behave...',
                      maxLines: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2D2D2D))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64557),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD64557)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text,
        'profile_type': _profileType,
        'bio': _bioController.text,
        'avatar_url': _avatarUrlController.text.isEmpty ? null : _avatarUrlController.text,
        'system_prompt': _systemPromptController.text,
        if (widget.profile == null)
          'expires_at': DateTime.now().add(Duration(days: _expiryDays)).toIso8601String(),
      };

      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
