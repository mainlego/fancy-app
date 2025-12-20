import 'dart:async';

/// Stub implementation for non-web platforms
class PwaUpdateService {
  static final PwaUpdateService _instance = PwaUpdateService._internal();
  factory PwaUpdateService() => _instance;
  PwaUpdateService._internal();

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get updateAvailable => _updateController.stream;

  bool _hasUpdate = false;
  bool get hasUpdate => _hasUpdate;

  /// Initialize - no-op on non-web platforms
  void init() {}

  /// Apply update - no-op on non-web platforms
  void applyUpdate() {}

  /// Skip update
  void skipUpdate() {
    _hasUpdate = false;
    _updateController.add(false);
  }

  void dispose() {
    _updateController.close();
  }
}
