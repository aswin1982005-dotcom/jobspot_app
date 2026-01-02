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

  Map<String, dynamic> toJson() {
    return {
      'address_line': addressLine,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
    };
  }

  factory LocationAddress.fromJson(Map<String, dynamic> json) {
    return LocationAddress(
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      placeId: json['place_id'],
    );
  }
}
