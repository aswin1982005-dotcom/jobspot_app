import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../models/location_address.dart';

class LocationService {
  final String apiKey;

  LocationService(this.apiKey);

  static const _basePlaces = 'https://maps.googleapis.com/maps/api/place';

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

    if (data['status'] != 'OK') {
      return [];
    }

    return (data['predictions'] as List)
        .map(
          (p) => {
            'description': p['description'] as String,
            'place_id': p['place_id'] as String,
          },
        )
        .toList();
  }

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
      result['formatted_address'],
    );
  }

  Future<LocationAddress> reverseGeocode(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        throw Exception('No address found');
      }
      Placemark place = placemarks[0];
      return _parseNativeAddress(place, lat, lng);
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  LocationAddress _parseNativeAddress(Placemark place, double lat, double lng) {
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
      placeId: null,
    );
  }

  LocationAddress _parseGoogleMapAddress(
    List components,
    double lat,
    double lng,
    String? placeId,
    String? formattedAddress,
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
    final addressLine = (streetNumber.isNotEmpty || route.isNotEmpty)
        ? '$streetNumber $route'.trim()
        : formattedAddress ?? '';

    // Robust city fallback
    String city = get('locality');
    if (city.isEmpty) city = get('sublocality');
    if (city.isEmpty) city = get('administrative_area_level_2');
    if (city.isEmpty) city = get('postal_town');

    return LocationAddress(
      addressLine: addressLine,
      city: city,
      state: get('administrative_area_level_1'),
      country: get('country'),
      postalCode: get('postal_code'),
      latitude: lat,
      longitude: lng,
      placeId: placeId,
    );
  }
}
