import 'package:equatable/equatable.dart';

/// Measurement system enum
enum MeasurementSystem {
  metric,
  imperial,
}

/// App language enum
enum AppLanguage {
  english,
  russian,
}

/// App settings model
class SettingsModel extends Equatable {
  // Notifications
  final bool notifyMatches;
  final bool notifyLikes;
  final bool notifySuperLikes;
  final bool notifyMessages;

  // Security
  final bool incognitoMode;

  // Preferences
  final MeasurementSystem measurementSystem;
  final AppLanguage appLanguage;

  const SettingsModel({
    this.notifyMatches = true,
    this.notifyLikes = true,
    this.notifySuperLikes = true,
    this.notifyMessages = true,
    this.incognitoMode = false,
    this.measurementSystem = MeasurementSystem.metric,
    this.appLanguage = AppLanguage.english,
  });

  /// Default settings
  static const SettingsModel defaultSettings = SettingsModel();

  /// Get locale code
  String get localeCode {
    switch (appLanguage) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.russian:
        return 'ru';
    }
  }

  /// Format height based on measurement system
  String formatHeight(int heightCm) {
    if (measurementSystem == MeasurementSystem.imperial) {
      final totalInches = (heightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet'$inches\"";
    }
    return '$heightCm cm';
  }

  /// Format weight based on measurement system
  String formatWeight(int weightKg) {
    if (measurementSystem == MeasurementSystem.imperial) {
      final lbs = (weightKg * 2.205).round();
      return '$lbs lbs';
    }
    return '$weightKg kg';
  }

  /// Format distance based on measurement system
  String formatDistance(int distanceKm) {
    if (measurementSystem == MeasurementSystem.imperial) {
      final miles = (distanceKm * 0.621371).round();
      return '$miles mi';
    }
    return '$distanceKm km';
  }

  SettingsModel copyWith({
    bool? notifyMatches,
    bool? notifyLikes,
    bool? notifySuperLikes,
    bool? notifyMessages,
    bool? incognitoMode,
    MeasurementSystem? measurementSystem,
    AppLanguage? appLanguage,
  }) {
    return SettingsModel(
      notifyMatches: notifyMatches ?? this.notifyMatches,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifySuperLikes: notifySuperLikes ?? this.notifySuperLikes,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      appLanguage: appLanguage ?? this.appLanguage,
    );
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      notifyMatches: json['notifyMatches'] as bool? ?? true,
      notifyLikes: json['notifyLikes'] as bool? ?? true,
      notifySuperLikes: json['notifySuperLikes'] as bool? ?? true,
      notifyMessages: json['notifyMessages'] as bool? ?? true,
      incognitoMode: json['incognitoMode'] as bool? ?? false,
      measurementSystem: MeasurementSystem.values
          .byName(json['measurementSystem'] as String? ?? 'metric'),
      appLanguage:
          AppLanguage.values.byName(json['appLanguage'] as String? ?? 'english'),
    );
  }

  /// From Supabase JSON (snake_case format)
  factory SettingsModel.fromSupabase(Map<String, dynamic> json) {
    return SettingsModel(
      notifyMatches: json['notify_matches'] as bool? ?? true,
      notifyLikes: json['notify_likes'] as bool? ?? true,
      notifySuperLikes: json['notify_super_likes'] as bool? ?? true,
      notifyMessages: json['notify_messages'] as bool? ?? true,
      incognitoMode: json['incognito_mode'] as bool? ?? false,
      measurementSystem: MeasurementSystem.values
          .byName(json['measurement_system'] as String? ?? 'metric'),
      appLanguage:
          AppLanguage.values.byName(json['app_language'] as String? ?? 'english'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifyMatches': notifyMatches,
      'notifyLikes': notifyLikes,
      'notifySuperLikes': notifySuperLikes,
      'notifyMessages': notifyMessages,
      'incognitoMode': incognitoMode,
      'measurementSystem': measurementSystem.name,
      'appLanguage': appLanguage.name,
    };
  }

  /// To Supabase JSON (snake_case format)
  Map<String, dynamic> toSupabase() {
    return {
      'notify_matches': notifyMatches,
      'notify_likes': notifyLikes,
      'notify_super_likes': notifySuperLikes,
      'notify_messages': notifyMessages,
      'incognito_mode': incognitoMode,
      'measurement_system': measurementSystem.name,
      'app_language': appLanguage.name,
    };
  }

  @override
  List<Object?> get props => [
        notifyMatches,
        notifyLikes,
        notifySuperLikes,
        notifyMessages,
        incognitoMode,
        measurementSystem,
        appLanguage,
      ];
}
