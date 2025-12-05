import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  // Controller for the map
  late GoogleMapController mapController;

  // Initial camera position (e.g., centered on a default location like the USA)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(39.8283, -98.5795), // Center of the USA
    zoom: 4,
  );

  // Set of markers to display on the map (you would populate this with job locations)
  final Set<Marker> _markers = {
    // Example Marker
    const Marker(
      markerId: MarkerId('google_hq'),
      position: LatLng(37.4220, -122.0841), // Googleplex
      infoWindow: InfoWindow(
        title: 'Senior UI/UX Designer',
        snippet: 'Google Inc.',
      ),
    ),
    const Marker(
      markerId: MarkerId('apple_hq'),
      position: LatLng(37.3346, -122.0090), // Apple Park
      infoWindow: InfoWindow(
        title: 'Product Manager',
        snippet: 'Apple Inc.',
      ),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar can be removed if you want a full-screen map experience
      appBar: AppBar(
        title: const Text('Jobs Near You'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // Use a Stack to overlay other UI elements (like a search bar) on the map later
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationButtonEnabled: true, // Shows a button to center on the user's location
        myLocationEnabled: true, // Shows the user's location on the map
        mapToolbarEnabled: false,
        zoomControlsEnabled: false, // Hides the default zoom +/- buttons for a cleaner look
      ),
    );
  }
}
