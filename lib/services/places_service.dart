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

/// Normalises any Google address string to "City, State" format.
/// Works with both `vicinity` ("4501 Main St, San Jose") and
/// `formatted_address` ("4501 Main St, San Jose, CA 94566, USA").
String _shortAddress(String raw) {
  final parts = raw.split(',').map((s) => s.trim()).toList();
  if (parts.length >= 3) {
    // formatted_address: [..., city, state+zip, country]
    // Take the second-to-last part for state (strip zip if present)
    final city  = parts[parts.length - 3];
    final state = parts[parts.length - 2].split(' ').first;
    return '$city, $state';
  }
  if (parts.length == 2) {
    // vicinity: "Street, City" — return just the city
    return parts[1];
  }
  return raw;
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

  // ── Text Search (wildcard / area search) ────────────────────────────────

  /// Returns golf course results for a free-text query.
  /// Works for city names ("Pleasanton"), partial course names, or both.
  /// Falls back to autocomplete for very short inputs.
  static Future<List<GolfCourseSuggestion>> autocomplete({
    required String input,
    Position? location,
    double? lat,
    double? lng,
    String? locationName,
  }) async {
    if (input.trim().isEmpty) return [];

    final useLat = lat ?? location?.latitude;
    final useLng = lng ?? location?.longitude;

    // Build query: if we have coords use plain search + tight radius,
    // otherwise append location name to anchor results geographically
    final query = (useLat == null && locationName != null)
        ? '$input golf course $locationName'
        : '$input golf course';

    final params = <String, String>{
      'query': query,
      'type': 'golf_course',
      'key': _apiKey,
    };

    if (useLat != null && useLng != null) {
      params['location'] = '$useLat,$useLng';
      params['radius'] = '30000'; // 30 km strict bias
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      params,
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .where((r) {
            final types = List<String>.from(r['types'] as List? ?? []);
            final name = (r['name'] as String? ?? '').toLowerCase();
            return types.contains('golf_course') ||
                name.contains('golf') ||
                name.contains('country club') ||
                name.contains('links');
          })
          .take(8)
          .map((r) {
        final address = r['formatted_address'] as String? ??
            r['vicinity'] as String? ?? '';
        // Shorten address to city + state for display
        final parts = address.split(',');
        final shortAddr = parts.length >= 2
            ? '${parts[parts.length - 3 < 0 ? 0 : parts.length - 3].trim()}, ${parts[parts.length - 2].trim()}'
            : address;
        return GolfCourseSuggestion(
          placeId: r['place_id'] as String? ?? '',
          name: r['name'] as String? ?? '',
          address: shortAddr,
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

  // ── City autocomplete suggestions ────────────────────────────────────────

  /// Returns city name suggestions for the given input using Places Autocomplete.
  static Future<List<({String description, String mainText, String secondaryText})>>
      getCitySuggestions(String input) async {
    if (input.trim().length < 2) return [];
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input.trim(),
        'types': '(cities)',
        'key': _apiKey,
      },
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions.take(5).map((p) {
        final fmt = p['structured_formatting'] as Map<String, dynamic>? ?? {};
        return (
          description: p['description'] as String? ?? '',
          mainText: fmt['main_text'] as String? ?? p['description'] as String? ?? '',
          secondaryText: fmt['secondary_text'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Search golf courses by city name ─────────────────────────────────────

  /// Searches golf courses in a city/area using Text Search (no Geocoding API needed).
  /// Returns up to 8 results with coordinates.
  static Future<({List<GolfCourseDetail> courses, String label, double? lat, double? lng})?> searchGolfCoursesByCity(
      String city) async {
    if (city.trim().isEmpty) return null;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {
        'query': '${city.trim()} golf course',
        'type': 'golf_course',
        'key': _apiKey,
      },
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['status'] == 'ZERO_RESULTS') return (courses: <GolfCourseDetail>[], label: city.trim(), lat: null, lng: null);
      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;

      // Derive a short label from first result's address
      final firstAddr = results.first['formatted_address'] as String? ?? city;
      final parts = firstAddr.split(',');
      final label = parts.length >= 2
          ? '${parts[parts.length - 3 < 0 ? 0 : parts.length - 3].trim()}, ${parts[parts.length - 2].trim()}'
          : city.trim();

      // Extract lat/lng of first result for location bias
      final firstGeo = results.first['geometry']?['location'];
      final centerLat = (firstGeo?['lat'] as num?)?.toDouble();
      final centerLng = (firstGeo?['lng'] as num?)?.toDouble();

      final courses = results
          .where((r) {
            final types = List<String>.from(r['types'] as List? ?? []);
            return types.contains('golf_course') ||
                (r['name'] as String? ?? '').toLowerCase().contains('golf') ||
                (r['name'] as String? ?? '').toLowerCase().contains('country club');
          })
          .take(8)
          .map((r) {
            final geo = r['geometry']?['location'];
            return GolfCourseDetail(
              placeId: r['place_id'] as String? ?? '',
              name: r['name'] as String? ?? '',
              address: _shortAddress(r['formatted_address'] as String? ?? r['vicinity'] as String? ?? ''),
              lat: (geo?['lat'] as num?)?.toDouble(),
              lng: (geo?['lng'] as num?)?.toDouble(),
            );
          })
          .toList();

      return (courses: courses, label: label, lat: centerLat, lng: centerLng);
    } catch (_) {
      return null;
    }
  }

  // ── Geocode a city/address to coordinates ───────────────────────────────

  /// Resolves a city name or address to a [Position]-like lat/lng pair.
  /// Returns null if the address cannot be resolved.
  static Future<({double lat, double lng, String label})?> geocodeCity(
      String address) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {'address': address, 'key': _apiKey},
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;
      final geo = results.first['geometry']['location'];
      final label = (results.first['formatted_address'] as String?)
              ?.split(',')
              .take(2)
              .join(',')
              .trim() ??
          address;
      return (
        lat: (geo['lat'] as num).toDouble(),
        lng: (geo['lng'] as num).toDouble(),
        label: label,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Nearby search ────────────────────────────────────────────────────────

  /// Returns nearby golf courses. Pass a GPS [location] or explicit [lat]/[lng].
  static Future<List<GolfCourseDetail>> nearbyGolfCourses(
      Position? location, {double? lat, double? lng}) async {
    final double useLat = lat ?? location!.latitude;
    final double useLng = lng ?? location!.longitude;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': '$useLat,$useLng',
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

      return results
          .where((r) {
            final types = List<String>.from(r['types'] as List? ?? []);
            return types.contains('golf_course');
          })
          .take(8)
          .map((r) {
        final geo = r['geometry']?['location'];
        return GolfCourseDetail(
          placeId: r['place_id'] as String? ?? '',
          name: r['name'] as String? ?? '',
          address: _shortAddress(r['vicinity'] as String? ?? r['formatted_address'] as String? ?? ''),
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
