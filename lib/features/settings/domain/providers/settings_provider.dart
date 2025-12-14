import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/settings_model.dart';

/// Settings state notifier with Supabase persistence
class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SupabaseService _supabase;
  bool _isLoading = false;

  SettingsNotifier(this._supabase) : super(SettingsModel.defaultSettings) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final data = await _supabase.getSettings();
      if (data != null) {
        state = SettingsModel.fromSupabase(data);
      }
    } catch (e) {
      print('Error loading settings: $e');
      // Keep default settings on error
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _supabase.updateSettings(state.toSupabase());
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  void updateNotifyMatches(bool value) {
    state = state.copyWith(notifyMatches: value);
    _saveSettings();
  }

  void updateNotifyLikes(bool value) {
    state = state.copyWith(notifyLikes: value);
    _saveSettings();
  }

  void updateNotifySuperLikes(bool value) {
    state = state.copyWith(notifySuperLikes: value);
    _saveSettings();
  }

  void updateNotifyMessages(bool value) {
    state = state.copyWith(notifyMessages: value);
    _saveSettings();
  }

  void updateIncognitoMode(bool value) {
    state = state.copyWith(incognitoMode: value);
    _saveSettings();
  }

  void updateMeasurementSystem(MeasurementSystem system) {
    state = state.copyWith(measurementSystem: system);
    _saveSettings();
  }

  void updateAppLanguage(AppLanguage language) {
    state = state.copyWith(appLanguage: language);
    _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = SettingsModel.defaultSettings;
    await _saveSettings();
  }

  Future<void> refresh() async {
    await _loadSettings();
  }
}

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return SettingsNotifier(supabase);
});

/// App language provider (shortcut)
final appLanguageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(settingsProvider).appLanguage;
});

/// Measurement system provider (shortcut)
final measurementSystemProvider = Provider<MeasurementSystem>((ref) {
  return ref.watch(settingsProvider).measurementSystem;
});
