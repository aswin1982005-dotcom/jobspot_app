import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart'; // Import the native package
import '../models/location_address.dart';

class LocationService {
  final String apiKey;

  LocationService(this.apiKey);

  static const _basePlaces = 'https://maps.googleapis.com/maps/api/place';

  // ---------- SEARCH (Autocomplete) ----------
  // We still use HTTP for search as the native package doesn't support Autocomplete
  Future<List<Map<String, String>>> searchPlaces(
    String query, {
    String? sessionToken,
  }) async {
    final uri = Uri.parse(
      '$_basePlaces/autocomplete/json'
      '?input=$query'
      '&key=$apiKey'
      '&sessiontoken=$sessionToken',
    );

    final res = await http.get(uri);
    final data = json.decode(res.body);

    if (data['status'] != 'OK') return [];

    return (data['predictions'] as List)
        .map(
          (p) => {
            'description': p['description'] as String,
            'place_id': p['place_id'] as String,
          },
        )
        .toList();
  }

  // ---------- PLACE DETAILS ----------
  // Fetches details for a selected search result
  Future<LocationAddress> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    final uri = Uri.parse(
      '$_basePlaces/details/json'
      '?place_id=$placeId'
      '&key=$apiKey'
      '&sessiontoken=$sessionToken',
    );

    final res = await http.get(uri);
    final result = json.decode(res.body)['result'];

    return _parseGoogleMapAddress(
      result['address_components'],
      result['geometry']['location']['lat'],
      result['geometry']['location']['lng'],
      placeId,
    );
  }

  // ---------- REVERSE GEOCODING (THE FIX) ----------
  // Uses the native device geocoder (Free & Secure)
  Future<LocationAddress> reverseGeocode(double lat, double lng) async {
    try {
      // This calls the native Android/iOS system geocoder
      // It does NOT use your API Key and allows "Android App" restrictions on other calls.
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) {
        throw Exception('No address found');
      }

      Placemark place = placemarks[0];

      // Format the address manually since Native objects are different from Google JSON
      return _parseNativeAddress(place, lat, lng);
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  // ---------- HELPER: Parse Native Placemark ----------
  LocationAddress _parseNativeAddress(Placemark place, double lat, double lng) {
    // Construct a readable address string
    // e.g., "123 Main St, New York, NY, 10001, USA"
    final components = [
      place.street,
      place.subLocality,
      place.locality,
      place.postalCode,
      place.country,
    ].where((element) => element != null && element.isNotEmpty).toList();

    final formattedAddress = components.join(', ');

    return LocationAddress(
      addressLine: formattedAddress,
      city: place.locality ?? place.subLocality ?? '',
      state: place.administrativeArea ?? '',
      country: place.country ?? '',
      postalCode: place.postalCode ?? '',
      latitude: lat,
      longitude: lng,
      placeId: null, // Native geocoder doesn't return Google Place IDs
    );
  }

  // ---------- HELPER: Parse Google HTTP Response ----------
  // Kept for the 'getPlaceDetails' method which still uses HTTP
  LocationAddress _parseGoogleMapAddress(
    List components,
    double lat,
    double lng,
    String? placeId,
  ) {
    String get(String type) {
      try {
        return components.firstWhere(
              (c) => (c['types'] as List).contains(type),
            )['long_name'] ??
            '';
      } catch (_) {
        return '';
      }
    }

    final streetNumber = get('street_number');
    final route = get('route');
    final addressLine = streetNumber.isNotEmpty
        ? '$streetNumber $route'
        : route;

    return LocationAddress(
      addressLine: addressLine,
      city: get('locality').isNotEmpty ? get('locality') : get('sublocality'),
      state: get('administrative_area_level_1'),
      country: get('country'),
      postalCode: get('postal_code'),
      latitude: lat,
      longitude: lng,
      placeId: placeId,
    );
  }
}
