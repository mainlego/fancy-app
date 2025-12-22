import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/admin_provider.dart';
import '../widgets/admin_user_dialog.dart';
import '../../../../shared/widgets/debug_panel.dart';

/// Admin users management screen - responsive design
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedProfileType;
  bool? _isPremium;
  bool? _isBanned;
  bool _showFilters = false;

  // Cache filters to prevent infinite rebuilds
  Map<String, dynamic> _cachedFilters = {};

  @override
  void initState() {
    super.initState();
    _updateFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    _cachedFilters = {
      'search': _searchController.text.isEmpty ? null : _searchController.text,
      'profileType': _selectedProfileType,
      'isPremium': _isPremium,
      'isBanned': _isBanned,
      'limit': 100,
      'offset': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_cachedFilters));
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
            const Text(
              'Users Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Filters
          _buildFilters(isMobile),
          const SizedBox(height: 16),

          // Users list/table
          Expanded(
            child: usersAsync.when(
              data: (users) => isMobile
                  ? _buildUsersList(users)
                  : _buildUsersTable(users),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFD64557)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $e', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(adminUsersProvider(_cachedFilters)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD64557)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => DebugPanel.show(context),
                      icon: const Icon(Icons.bug_report, color: Colors.orange),
                      label: const Text('View Debug Logs', style: TextStyle(color: Colors.orange)),
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

  Widget _buildFilters(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          // Search row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => setState(() => _updateFilters()),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                      color: _hasActiveFilters ? const Color(0xFFD64557) : Colors.white54,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() => _updateFilters()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64557),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                ),
                child: const Icon(Icons.search, size: 20),
              ),
            ],
          ),
          // Expandable filters
          if (_showFilters) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMobileFilterChip(
                  label: 'Type',
                  value: _selectedProfileType,
                  items: {
                    null: 'All',
                    'woman': 'Women',
                    'man': 'Men',
                    'manAndWoman': 'M&W',
                  },
                  onChanged: (v) => setState(() { _selectedProfileType = v; _updateFilters(); }),
                ),
                _buildMobileFilterChip<bool?>(
                  label: 'Premium',
                  value: _isPremium,
                  items: {null: 'All', true: 'Yes', false: 'No'},
                  onChanged: (v) => setState(() { _isPremium = v; _updateFilters(); }),
                ),
                _buildMobileFilterChip<bool?>(
                  label: 'Status',
                  value: _isBanned,
                  items: {null: 'All', true: 'Banned', false: 'Active'},
                  onChanged: (v) => setState(() { _isBanned = v; _updateFilters(); }),
                ),
                if (_hasActiveFilters)
                  ActionChip(
                    label: const Text('Clear'),
                    avatar: const Icon(Icons.clear, size: 16),
                    onPressed: _clearFilters,
                    backgroundColor: const Color(0xFF2D2D2D),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ],
        ],
      );
    }

    // Desktop filters
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => setState(() => _updateFilters()),
          ),
        ),
        _FilterDropdown(
          value: _selectedProfileType,
          hint: 'Profile Type',
          items: const {
            null: 'All Types',
            'woman': 'Women',
            'man': 'Men',
            'manAndWoman': 'Man & Woman',
            'manPair': 'Man Pair',
            'womanPair': 'Woman Pair',
          },
          onChanged: (value) => setState(() { _selectedProfileType = value; _updateFilters(); }),
        ),
        _FilterDropdown<bool?>(
          value: _isPremium,
          hint: 'Premium',
          items: const {null: 'All', true: 'Premium', false: 'Free'},
          onChanged: (value) => setState(() { _isPremium = value; _updateFilters(); }),
        ),
        _FilterDropdown<bool?>(
          value: _isBanned,
          hint: 'Status',
          items: const {null: 'All', true: 'Banned', false: 'Active'},
          onChanged: (value) => setState(() { _isBanned = value; _updateFilters(); }),
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() => _updateFilters()),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD64557),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear Filters', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildMobileFilterChip<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      color: const Color(0xFF2D2D2D),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: value != null
              ? Border.all(color: const Color(0xFFD64557))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null ? items[value] ?? label : label,
              style: TextStyle(
                color: value != null ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: value != null ? Colors.white : Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => items.entries.map((entry) {
        return PopupMenuItem<T>(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  bool get _hasActiveFilters =>
      _selectedProfileType != null || _isPremium != null || _isBanned != null;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedProfileType = null;
      _isPremium = null;
      _isBanned = null;
      _updateFilters();
    });
  }

  // Mobile: Card list
  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) => _UserCard(
        user: users[index],
        onTap: () => _showUserDialog(users[index]),
        onBan: () => _toggleBan(users[index]),
        onDelete: () => _confirmDelete(users[index]),
      ),
    );
  }

  // Desktop: Data table
  Widget _buildUsersTable(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
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
            DataColumn(label: Text('Type', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Premium', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Last Online', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) => _buildUserRow(user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildUserRow(Map<String, dynamic> user) {
    final name = user['name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final avatarUrl = user['avatar_url'] as String?;
    final photos = user['photos'] as List<dynamic>? ?? [];
    final profileType = user['profile_type'] as String? ?? 'unknown';
    final isBanned = user['is_banned'] == true;
    final isPremium = user['is_premium'] == true;
    final isVerified = user['is_verified'] == true;
    final lastOnline = user['last_online'] as String?;

    final firstPhoto = avatarUrl ?? (photos.isNotEmpty ? photos.first as String : null);

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2D2D2D),
                backgroundImage: firstPhoto != null ? NetworkImage(firstPhoto) : null,
                child: firstPhoto == null ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFF4A90D9), size: 16),
                      ],
                    ],
                  ),
                  Text(email, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        DataCell(_ProfileTypeBadge(profileType: profileType)),
        DataCell(_buildStatusBadge(isBanned)),
        DataCell(_buildPremiumBadge(isPremium)),
        DataCell(Text(
          _formatLastOnline(lastOnline),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white54, size: 20),
                onPressed: () => _showUserDialog(user),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: Icon(
                  isBanned ? Icons.lock_open : Icons.block,
                  color: isBanned ? Colors.green : Colors.orange,
                  size: 20,
                ),
                onPressed: () => _toggleBan(user),
                tooltip: isBanned ? 'Unban' : 'Ban',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(user),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isBanned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isBanned ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isBanned ? 'Banned' : 'Active',
        style: TextStyle(color: isBanned ? Colors.red : Colors.green, fontSize: 12),
      ),
    );
  }

  Widget _buildPremiumBadge(bool isPremium) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPremium ? 'Premium' : 'Free',
        style: TextStyle(color: isPremium ? Colors.amber : Colors.grey, fontSize: 12),
      ),
    );
  }

  String _formatLastOnline(String? lastOnline) {
    if (lastOnline == null) return 'Never';
    final date = DateTime.tryParse(lastOnline);
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 5) return 'Online';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AdminUserDialog(
        user: user,
        onUpdate: () {
          ref.invalidate(adminUsersProvider(_cachedFilters));
        },
      ),
    );
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    final isBanned = user['is_banned'] == true;
    final adminService = ref.read(adminServiceProvider);

    if (isBanned) {
      await adminService.unbanUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unbanned'), backgroundColor: Colors.green),
        );
      }
    } else {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const _BanDialog(),
      );

      if (result != null) {
        await adminService.banUser(
          userId,
          reason: result['reason'],
          days: result['days'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User banned'), backgroundColor: Colors.orange),
          );
        }
      }
    }

    ref.invalidate(adminUsersProvider(_cachedFilters));
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${user['name']}?\n\nThis will permanently delete all their data.',
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
      await adminService.deleteUser(user['id'] as String);
      ref.invalidate(adminUsersProvider(_cachedFilters));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Mobile user card
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final VoidCallback onBan;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onBan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final avatarUrl = user['avatar_url'] as String?;
    final photos = user['photos'] as List<dynamic>? ?? [];
    final profileType = user['profile_type'] as String? ?? 'unknown';
    final isBanned = user['is_banned'] == true;
    final isPremium = user['is_premium'] == true;
    final isVerified = user['is_verified'] == true;

    final firstPhoto = avatarUrl ?? (photos.isNotEmpty ? photos.first as String : null);

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBanned
            ? const BorderSide(color: Colors.red, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2D2D2D),
                backgroundImage: firstPhoto != null ? NetworkImage(firstPhoto) : null,
                child: firstPhoto == null
                    ? const Icon(Icons.person, color: Colors.white54, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Color(0xFF4A90D9), size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _ProfileTypeBadge(profileType: profileType, small: true),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Premium',
                              style: TextStyle(color: Colors.amber, fontSize: 10),
                            ),
                          ),
                        if (isBanned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Banned',
                              style: TextStyle(color: Colors.red, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: const Color(0xFF2D2D2D),
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      onTap();
                      break;
                    case 'ban':
                      onBan();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.white54, size: 18),
                        SizedBox(width: 8),
                        Text('View Details', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(
                          isBanned ? Icons.lock_open : Icons.block,
                          color: isBanned ? Colors.green : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBanned ? 'Unban' : 'Ban',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38)),
          dropdownColor: const Color(0xFF2D2D2D),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: items.entries.map((entry) {
            return DropdownMenuItem<T>(
              value: entry.key,
              child: Text(entry.value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  final String profileType;
  final bool small;

  const _ProfileTypeBadge({required this.profileType, this.small = false});

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
      'manAndWoman': 'M&W',
      'manPair': 'M Pair',
      'womanPair': 'W Pair',
    };

    final color = colors[profileType] ?? Colors.grey;
    final label = labels[profileType] ?? profileType;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: small ? 10 : 12),
      ),
    );
  }
}

class _BanDialog extends StatefulWidget {
  const _BanDialog();

  @override
  State<_BanDialog> createState() => _BanDialogState();
}

class _BanDialogState extends State<_BanDialog> {
  final _reasonController = TextEditingController();
  int? _days;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Ban User', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Reason',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD64557)),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _days,
            dropdownColor: const Color(0xFF2D2D2D),
            decoration: const InputDecoration(
              labelText: 'Duration',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD64557)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 day', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 7, child: Text('7 days', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 30, child: Text('30 days', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 365, child: Text('1 year', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: null, child: Text('Permanent', style: TextStyle(color: Colors.red))),
            ],
            onChanged: (value) => setState(() => _days = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'reason': _reasonController.text.isEmpty ? 'Banned by admin' : _reasonController.text,
              'days': _days,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Ban'),
        ),
      ],
    );
  }
}
