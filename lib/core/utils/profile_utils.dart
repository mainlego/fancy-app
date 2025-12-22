/// Profile utility functions to avoid code duplication

/// Calculate age from birth date
/// Returns the age in years, or null if birthDate is null
int? calculateAge(DateTime? birthDate) {
  if (birthDate == null) return null;
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  // Adjust if birthday hasn't occurred this year
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

/// Calculate age from birth date string
/// Returns the age in years, or defaultAge if parsing fails
int calculateAgeFromString(String? birthDateStr, {int defaultAge = 18}) {
  if (birthDateStr == null) return defaultAge;
  try {
    final birthDate = DateTime.parse(birthDateStr);
    return calculateAge(birthDate) ?? defaultAge;
  } catch (_) {
    return defaultAge;
  }
}

/// Get display avatar URL from profile data
/// Prefers avatar_url, falls back to first photo
String? getDisplayAvatar(Map<String, dynamic>? profile) {
  if (profile == null) return null;

  // Try avatar_url first
  final avatarUrl = profile['avatar_url'] as String?;
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    return avatarUrl;
  }

  // Fall back to first photo
  final photos = profile['photos'] as List<dynamic>?;
  if (photos != null && photos.isNotEmpty) {
    return photos.first as String?;
  }

  return null;
}

/// Get display name from profile data
/// Tries 'name' first, then 'display_name', defaults to 'Unknown'
String getDisplayName(Map<String, dynamic>? profile) {
  if (profile == null) return 'Unknown';
  return profile['name'] as String? ??
      profile['display_name'] as String? ??
      'Unknown';
}
