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

  /// Check and request location permission
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
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

  /// Get and save user location to profile
  Future<LocationData?> updateUserLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final locationData = LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // Save to local storage
    await _saveLocationLocally(locationData);

    // Update profile in Supabase
    final userId = _supabase.currentUser?.id;
    if (userId != null) {
      await _supabase.updateProfile(userId, {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
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
          // Try to get city name from various fields
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'] ??
              address['state'];

          return city?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }
}

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return LocationService(supabase);
});

/// Current user location provider
final userLocationProvider = FutureProvider<LocationData?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);

  // Try to get saved location first
  var location = await locationService.getSavedLocation();

  // If no saved location, try to get current
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
