import 'package:flutter_test/flutter_test.dart';

// Copying the logic to be tested since we can't easily access the private method
// and we don't want to change visibility just for testing if we can avoid it.
// This is a "white box" test of the logic we just implemented.

class LocationAddress {
  final String addressLine;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String? placeId;

  LocationAddress({
    required this.addressLine,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });
}

LocationAddress parseGoogleMapAddress(
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

void main() {
  test('Logic correctly prioritizes city components', () {
    // Case 1: Has locality
    final components1 = [
      {
        'types': ['locality'],
        'long_name': 'New York',
      },
      {
        'types': ['administrative_area_level_1'],
        'long_name': 'NY',
      },
    ];
    final result1 = parseGoogleMapAddress(components1, 0, 0, null, null);
    expect(result1.city, 'New York');

    // Case 2: No locality, has sublocality
    final components2 = [
      {
        'types': ['sublocality'],
        'long_name': 'Brooklyn',
      },
      {
        'types': ['administrative_area_level_1'],
        'long_name': 'NY',
      },
    ];
    final result2 = parseGoogleMapAddress(components2, 0, 0, null, null);
    expect(result2.city, 'Brooklyn');

    // Case 3: Fallback to postal_town
    final components3 = [
      {
        'types': ['postal_town'],
        'long_name': 'London',
      },
    ];
    final result3 = parseGoogleMapAddress(components3, 0, 0, null, null);
    expect(result3.city, 'London');

    // Case 4: No direct address components, rely on formatted address
    final components4 = <Map<String, dynamic>>[];
    final result4 = parseGoogleMapAddress(
      components4,
      0,
      0,
      null,
      '123 Main St',
    );
    expect(result4.addressLine, '123 Main St');
  });
}
