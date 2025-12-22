import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      };
}

/// Location service for getting user position and calculating distances
class LocationService {
  static const String _latKey = 'user_latitude';
  static const String _lngKey = 'user_longitude';
  static const String _cityKey = 'user_city';
  static const String _countryKey = 'user_country';

  final SupabaseService _supabase;

  LocationService(this._supabase);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission (including background/always)
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Check if we have "always" (background) location permission
  Future<bool> hasAlwaysPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Request "always" location permission for background access
  /// Returns true if permission is granted, false otherwise
  /// On Android 10+, user must manually grant this in settings after initial "while in use" grant
  Future<bool> requestAlwaysPermission() async {
    var permission = await Geolocator.checkPermission();

    // First request basic permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If denied forever, we can't request again
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // If we already have "always", we're good
    if (permission == LocationPermission.always) {
      return true;
    }

    // If we have "while in use", try requesting again
    // On Android 11+, this will show the permission dialog with "Allow all the time" option
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        return null;
      }

      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get and save user location to profile with city detection
  Future<LocationData?> updateUserLocation() async {
    debugPrint('LocationService.updateUserLocation: Starting...');
    final position = await getCurrentPosition();
    if (position == null) {
      debugPrint('LocationService.updateUserLocation: No position available');
      return null;
    }
    debugPrint('LocationService.updateUserLocation: Got position (${position.latitude}, ${position.longitude})');

    // Reverse geocode to get city and country
    String? city;
    String? country;
    try {
      final geoData = await reverseGeocodeWithCountry(position.latitude, position.longitude);
      city = geoData['city'];
      country = geoData['country'];
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }

    final locationData = LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      country: country,
    );

    // Save to local storage
    await _saveLocationLocally(locationData);

    // Update profile in Supabase
    final userId = _supabase.currentUser?.id;
    if (userId != null) {
      debugPrint('LocationService.updateUserLocation: Saving to Supabase - lat=${position.latitude}, lon=${position.longitude}, city=$city, country=$country');
      await _supabase.updateProfile(userId, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      });
      debugPrint('LocationService.updateUserLocation: Saved to Supabase successfully');
    } else {
      debugPrint('LocationService.updateUserLocation: No user ID, cannot save to Supabase');
    }

    return locationData;
  }

  /// Save location to local storage
  Future<void> _saveLocationLocally(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lngKey, location.longitude);
    if (location.city != null) await prefs.setString(_cityKey, location.city!);
    if (location.country != null) await prefs.setString(_countryKey, location.country!);
  }

  /// Get saved location from local storage
  Future<LocationData?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);

    if (lat == null || lng == null) return null;

    return LocationData(
      latitude: lat,
      longitude: lng,
      city: prefs.getString(_cityKey),
      country: prefs.getString(_countryKey),
    );
  }

  /// Calculate distance between two points in kilometers using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Calculate distance from current user to another user
  Future<int?> getDistanceToUser(double? targetLat, double? targetLng) async {
    if (targetLat == null || targetLng == null) return null;

    final myLocation = await getSavedLocation();
    if (myLocation == null) return null;

    final distance = calculateDistance(
      myLocation.latitude,
      myLocation.longitude,
      targetLat,
      targetLng,
    );

    return distance.round();
  }

  /// Update city and country from coordinates (reverse geocoding)
  /// Note: For production, use a geocoding service like Google Maps or OpenStreetMap
  Future<void> updateLocationWithCity(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
    await prefs.setString(_countryKey, country);

    // Update profile
    final userId = _supabase.currentUser?.id;
    if (userId != null) {
      await _supabase.updateProfile(userId, {
        'city': city,
        'country': country,
      });
    }
  }

  /// Open app settings for location permissions
  Future<bool> openSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Reverse geocode coordinates to get city name (works on web)
  /// Uses OpenStreetMap Nominatim API (free, no API key required)
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final data = await reverseGeocodeWithCountry(latitude, longitude);
    return data['city'];
  }

  /// Reverse geocode coordinates to get city and country
  /// Uses OpenStreetMap Nominatim API (free, no API key required)
  Future<Map<String, String?>> reverseGeocodeWithCountry(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FancyApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Try to get city name from various fields (priority order)
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'] ??
              address['state_district'] ??
              address['state'];

          final country = address['country'];

          return {
            'city': city?.toString(),
            'country': country?.toString(),
          };
        }
      }
      return {'city': null, 'country': null};
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return {'city': null, 'country': null};
    }
  }

  /// Get location and city without saving to profile
  /// Useful for one-time location detection
  Future<LocationData?> getLocationWithCity() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    String? city;
    String? country;
    try {
      final geoData = await reverseGeocodeWithCountry(position.latitude, position.longitude);
      city = geoData['city'];
      country = geoData['country'];
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      country: country,
    );
  }
}

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return LocationService(supabase);
});

/// Location state for tracking user position with timestamps
class LocationState {
  final LocationData? location;
  final DateTime? lastUpdated;
  final bool isLoading;

  const LocationState({
    this.location,
    this.lastUpdated,
    this.isLoading = false,
  });

  LocationState copyWith({
    LocationData? location,
    DateTime? lastUpdated,
    bool? isLoading,
  }) {
    return LocationState(
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Location notifier for managing user location with periodic updates
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  static const Duration _updateInterval = Duration(minutes: 5);
  static const double _significantDistanceMeters = 100; // 100m threshold for update

  LocationNotifier(this._locationService) : super(const LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    state = state.copyWith(isLoading: true);

    // Try to get saved location first
    var location = await _locationService.getSavedLocation();

    if (location != null) {
      state = LocationState(
        location: location,
        lastUpdated: DateTime.now(),
        isLoading: false,
      );
    }

    // Then try to get fresh location
    await updateLocation();
  }

  /// Update location if needed (checks interval and significant distance change)
  Future<bool> updateLocation({bool force = false}) async {
    // Check if we should update (time-based)
    if (!force && state.lastUpdated != null) {
      final timeSinceUpdate = DateTime.now().difference(state.lastUpdated!);
      if (timeSinceUpdate < _updateInterval) {
        debugPrint('LocationNotifier: Skipping update, last update was ${timeSinceUpdate.inSeconds}s ago');
        return false;
      }
    }

    state = state.copyWith(isLoading: true);

    try {
      final newLocation = await _locationService.updateUserLocation();

      if (newLocation == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final oldLocation = state.location;
      final hasSignificantChange = oldLocation == null ||
          _hasSignificantDistanceChange(oldLocation, newLocation);

      state = LocationState(
        location: newLocation,
        lastUpdated: DateTime.now(),
        isLoading: false,
      );

      debugPrint('LocationNotifier: Updated location to (${newLocation.latitude}, ${newLocation.longitude}), significant change: $hasSignificantChange');

      return hasSignificantChange;
    } catch (e) {
      debugPrint('LocationNotifier: Error updating location: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Check if distance change is significant (> 100m)
  bool _hasSignificantDistanceChange(LocationData old, LocationData newLoc) {
    final distance = LocationService.calculateDistance(
      old.latitude, old.longitude,
      newLoc.latitude, newLoc.longitude,
    );
    // Convert km to meters
    return distance * 1000 > _significantDistanceMeters;
  }

  /// Force refresh location
  Future<bool> forceRefresh() async {
    return updateLocation(force: true);
  }
}

/// Location notifier provider
final locationNotifierProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

/// Current user location provider (legacy, for compatibility)
final userLocationProvider = FutureProvider<LocationData?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);

  // Try to get saved location first
  var location = await locationService.getSavedLocation();

  // If saved location has no city, try to geocode it
  if (location != null && location.city == null) {
    try {
      final geoData = await locationService.reverseGeocodeWithCountry(
        location.latitude,
        location.longitude,
      );
      if (geoData['city'] != null) {
        location = LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          city: geoData['city'],
          country: geoData['country'],
        );
        // Save updated location with city
        await locationService.updateLocationWithCity(
          geoData['city']!,
          geoData['country'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error geocoding saved location: $e');
    }
  }

  // If no saved location, try to get current with city
  if (location == null) {
    location = await locationService.updateUserLocation();
  }

  return location;
});

/// Location permission status provider
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.checkPermission();
});

/// Has "always" location permission provider
final hasAlwaysLocationPermissionProvider = FutureProvider<bool>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.hasAlwaysPermission();
});
