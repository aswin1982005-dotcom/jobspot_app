import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_address.dart';

class LocationService {
  final FlutterGooglePlacesSdk _places;

  LocationService(String apiKey) : _places = FlutterGooglePlacesSdk(apiKey);

  Future<List<Map<String, String>>> searchPlaces(String query) async {
    try {
      final result = await _places.findAutocompletePredictions(query);

      return result.predictions
          .map((p) => {'description': p.fullText, 'place_id': p.placeId})
          .toList();
    } catch (e) {
      debugPrint('Google Places SDK Error: $e');
      return [];
    }
  }

  Future<LocationAddress> getPlaceDetails(String placeId) async {
    try {
      final result = await _places.fetchPlace(
        placeId,
        fields: [
          PlaceField.Address,
          PlaceField.AddressComponents,
          PlaceField.Location,
        ],
      );

      final place = result.place;
      if (place == null) {
        throw Exception('Place not found');
      }

      return _parseGoogleMapAddress(
        place.addressComponents ?? [],
        place.latLng?.lat ?? 0.0,
        place.latLng?.lng ?? 0.0,
        placeId,
        place.address,
      );
    } catch (e) {
      debugPrint('Google Places SDK Details Error: $e');
      throw Exception('Failed to get place details: $e');
    }
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
    List<AddressComponent> components,
    double lat,
    double lng,
    String? placeId,
    String? formattedAddress,
  ) {
    String get(String type) {
      try {
        return components.firstWhere((c) => c.types.contains(type)).name;
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
