import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jobspot_app/core/utils/location_service.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng initialPosition;

  const MapPickerPage({
    super.key,
    this.initialPosition = const LatLng(19.0760, 72.8777),
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _currentPosition;
  final _locationService = LocationService(
    dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '',
  );
  bool _isReversing = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
  }

  Future<void> _confirmLocation() async {
    setState(() => _isReversing = true);
    try {
      final address = await _locationService.reverseGeocode(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      if (mounted) {
        Navigator.pop(context, address);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReversing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting address: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            onCameraMove: (position) {
              _currentPosition = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _isReversing ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isReversing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
