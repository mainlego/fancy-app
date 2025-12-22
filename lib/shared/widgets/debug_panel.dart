import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/debug_logger.dart';
import '../../core/constants/app_colors.dart';

/// Debug panel overlay that shows logs and allows copying
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  /// Show debug panel as bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DebugPanel(),
    );
  }

  /// Show debug panel as full screen
  static void showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugPanelScreen(),
      ),
    );
  }

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  List<LogEntry> _logs = [];
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logs = debugLogger.logs;
    debugLogger.addListener(_onLogsUpdated);
  }

  @override
  void dispose() {
    debugLogger.removeListener(_onLogsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onLogsUpdated() {
    if (mounted) {
      setState(() {
        _logs = debugLogger.logs;
      });
    }
  }

  List<LogEntry> get _filteredLogs {
    var logs = _logs;

    if (_filterLevel != null) {
      logs = logs.where((e) => e.level == _filterLevel).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((e) =>
          e.message.toLowerCase().contains(query) ||
          (e.tag?.toLowerCase().contains(query) ?? false)).toList();
    }

    return logs;
  }

  Future<void> _copyLogs() async {
    final logsText = _filteredLogs.map((e) => e.toString()).join('\n');
    await Clipboard.setData(ClipboardData(text: logsText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${_filteredLogs.length} logs to clipboard'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _clearLogs() {
    debugLogger.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Debug Logs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredLogs.length} logs',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Copy button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _copyLogs,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearLogs,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              const SizedBox(height: 12),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterLevel == null,
                      onTap: () => setState(() => _filterLevel = null),
                    ),
                    _FilterChip(
                      label: '❌ Errors',
                      isSelected: _filterLevel == LogLevel.error,
                      onTap: () => setState(() => _filterLevel = LogLevel.error),
                      color: Colors.red,
                    ),
                    _FilterChip(
                      label: '⚠️ Warnings',
                      isSelected: _filterLevel == LogLevel.warning,
                      onTap: () => setState(() => _filterLevel = LogLevel.warning),
                      color: Colors.orange,
                    ),
                    _FilterChip(
                      label: 'ℹ️ Info',
                      isSelected: _filterLevel == LogLevel.info,
                      onTap: () => setState(() => _filterLevel = LogLevel.info),
                      color: Colors.blue,
                    ),
                    _FilterChip(
                      label: '🔍 Debug',
                      isSelected: _filterLevel == LogLevel.debug,
                      onTap: () => setState(() => _filterLevel = LogLevel.debug),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),

              // Logs list
              Expanded(
                child: _filteredLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredLogs.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          return _LogEntryTile(entry: log);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primary).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppColors.primary)
                  : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (color ?? AppColors.primary) : Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryTile({required this.entry});

  Color get _levelColor {
    switch (entry.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: entry.toString()));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log copied to clipboard'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _levelColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _levelColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.levelIcon,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.timeString,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                if (entry.tag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _levelColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.tag!,
                      style: TextStyle(
                        color: _levelColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen debug panel
class DebugPanelScreen extends StatefulWidget {
  const DebugPanelScreen({super.key});

  @override
  State<DebugPanelScreen> createState() => _DebugPanelScreenState();
}

class _DebugPanelScreenState extends State<DebugPanelScreen> {
  List<LogEntry> _logs = [];
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logs = debugLogger.logs;
    debugLogger.addListener(_onLogsUpdated);
  }

  @override
  void dispose() {
    debugLogger.removeListener(_onLogsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onLogsUpdated() {
    if (mounted) {
      setState(() {
        _logs = debugLogger.logs;
      });
    }
  }

  List<LogEntry> get _filteredLogs {
    var logs = _logs;

    if (_filterLevel != null) {
      logs = logs.where((e) => e.level == _filterLevel).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((e) =>
          e.message.toLowerCase().contains(query) ||
          (e.tag?.toLowerCase().contains(query) ?? false)).toList();
    }

    return logs;
  }

  Future<void> _copyLogs() async {
    final logsText = _filteredLogs.map((e) => e.toString()).join('\n');
    await Clipboard.setData(ClipboardData(text: logsText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${_filteredLogs.length} logs to clipboard'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Debug Logs'),
            const Spacer(),
            Text(
              '${_filteredLogs.length}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy all logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              debugLogger.clear();
            },
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterLevel == null,
                  onTap: () => setState(() => _filterLevel = null),
                ),
                _FilterChip(
                  label: '❌ Errors',
                  isSelected: _filterLevel == LogLevel.error,
                  onTap: () => setState(() => _filterLevel = LogLevel.error),
                  color: Colors.red,
                ),
                _FilterChip(
                  label: '⚠️ Warnings',
                  isSelected: _filterLevel == LogLevel.warning,
                  onTap: () => setState(() => _filterLevel = LogLevel.warning),
                  color: Colors.orange,
                ),
                _FilterChip(
                  label: 'ℹ️ Info',
                  isSelected: _filterLevel == LogLevel.info,
                  onTap: () => setState(() => _filterLevel = LogLevel.info),
                  color: Colors.blue,
                ),
                _FilterChip(
                  label: '🔍 Debug',
                  isSelected: _filterLevel == LogLevel.debug,
                  onTap: () => setState(() => _filterLevel = LogLevel.debug),
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Logs list
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return _LogEntryTile(entry: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Floating debug button widget
class DebugButton extends StatelessWidget {
  const DebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'debug_button',
      backgroundColor: AppColors.primary.withOpacity(0.8),
      onPressed: () => DebugPanel.show(context),
      child: const Icon(Icons.bug_report, size: 20),
    );
  }
}
