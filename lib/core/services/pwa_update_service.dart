import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Service to handle PWA updates
class PwaUpdateService {
  static final PwaUpdateService _instance = PwaUpdateService._internal();
  factory PwaUpdateService() => _instance;
  PwaUpdateService._internal();

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get updateAvailable => _updateController.stream;

  bool _hasUpdate = false;
  bool get hasUpdate => _hasUpdate;

  /// Initialize the service and listen for service worker updates
  void init() {
    if (!kIsWeb) return;

    _checkForUpdates();
    // Check periodically for updates (every 5 minutes)
    Timer.periodic(const Duration(minutes: 5), (_) => _checkForUpdates());
  }

  void _checkForUpdates() {
    if (!kIsWeb) return;

    try {
      final navigator = html.window.navigator;
      final serviceWorker = navigator.serviceWorker;

      if (serviceWorker != null) {
        serviceWorker.ready.then((registration) {
          registration.update();

          registration.addEventListener('updatefound', (event) {
            final newWorker = registration.installing;
            if (newWorker != null) {
              newWorker.addEventListener('statechange', (event) {
                if (newWorker.state == 'installed' &&
                    navigator.serviceWorker?.controller != null) {
                  _hasUpdate = true;
                  _updateController.add(true);
                }
              });
            }
          });
        });
      }
    } catch (e) {
      print('PWA update check error: $e');
    }
  }

  /// Force reload the app to apply update
  void applyUpdate() {
    if (kIsWeb) {
      html.window.location.reload();
    }
  }

  /// Skip the current update
  void skipUpdate() {
    _hasUpdate = false;
    _updateController.add(false);
  }

  void dispose() {
    _updateController.close();
  }
}
