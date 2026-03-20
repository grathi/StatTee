import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Platform-specific API key
// ---------------------------------------------------------------------------
const _iosKey    = 'AIzaSyD9qpVoecA0DQzfoeVKSiBD2VPz4xa_frk';
const _androidKey = 'AIzaSyB2fsBnxDnwYTmDWFDSNV6WKS278m_lyQE';

String get _apiKey {
  if (kIsWeb) return _iosKey;
  return Platform.isAndroid ? _androidKey : _iosKey;
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class GolfCourseSuggestion {
  final String placeId;
  final String name;
  final String address;

  const GolfCourseSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
  });
}

class GolfCourseDetail {
  final String placeId;
  final String name;
  final String address;
  final double? lat;
  final double? lng;

  const GolfCourseDetail({
    required this.placeId,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
  });
}

// ---------------------------------------------------------------------------
// PlacesService
// ---------------------------------------------------------------------------
class PlacesService {
  // ── Location helpers ────────────────────────────────────────────────────

  /// Request permission and return current position, or null if denied.
  static Future<Position?> getCurrentLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Autocomplete ────────────────────────────────────────────────────────

  /// Returns Place autocomplete suggestions filtered to golf courses.
  /// [input] is the user's typed text.
  /// [location] biases results toward the user's position (optional).
  static Future<List<GolfCourseSuggestion>> autocomplete({
    required String input,
    Position? location,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': '$input golf course',
      'types': 'establishment',
      'key': _apiKey,
    };

    if (location != null) {
      params['location'] = '${location.latitude},${location.longitude}';
      params['radius'] = '50000'; // 50 km bias
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];

      return predictions.map((p) {
        final structured = p['structured_formatting'] as Map<String, dynamic>?;
        return GolfCourseSuggestion(
          placeId: p['place_id'] as String? ?? '',
          name: structured?['main_text'] as String? ??
              p['description'] as String? ?? '',
          address: structured?['secondary_text'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Reverse geocode ──────────────────────────────────────────────────────

  /// Returns a short location label (e.g. "San Francisco, CA") from coordinates.
  static Future<String?> getLocationName(Position position) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '${position.latitude},${position.longitude}',
        'result_type': 'locality|administrative_area_level_1',
        'key': _apiKey,
      },
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;

      // Extract locality (city) and admin area (state/country)
      String? city;
      String? admin;
      for (final component in results.first['address_components'] as List) {
        final types = List<String>.from(component['types'] as List);
        if (types.contains('locality')) city = component['short_name'] as String?;
        if (types.contains('administrative_area_level_1')) admin = component['short_name'] as String?;
      }
      if (city != null && admin != null) return '$city, $admin';
      if (city != null) return city;
      return (results.first['formatted_address'] as String?)?.split(',').first;
    } catch (_) {
      return null;
    }
  }

  // ── Nearby search ────────────────────────────────────────────────────────

  /// Returns nearby golf courses around [location].
  static Future<List<GolfCourseDetail>> nearbyGolfCourses(
      Position location) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': '${location.latitude},${location.longitude}',
        'radius': '25000', // 25 km
        'type': 'golf_course',
        'key': _apiKey,
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results.take(8).map((r) {
        final geo = r['geometry']?['location'];
        return GolfCourseDetail(
          placeId: r['place_id'] as String? ?? '',
          name: r['name'] as String? ?? '',
          address: r['vicinity'] as String? ?? '',
          lat: (geo?['lat'] as num?)?.toDouble(),
          lng: (geo?['lng'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Place detail ─────────────────────────────────────────────────────────

  /// Fetch full name + formatted address for a placeId.
  static Future<GolfCourseDetail?> getPlaceDetail(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'name,formatted_address,geometry',
        'key': _apiKey,
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final geo = result['geometry']?['location'];
      return GolfCourseDetail(
        placeId: placeId,
        name: result['name'] as String? ?? '',
        address: result['formatted_address'] as String? ?? '',
        lat: (geo?['lat'] as num?)?.toDouble(),
        lng: (geo?['lng'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
