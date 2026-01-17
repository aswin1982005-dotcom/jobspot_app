import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/features/jobs/presentation/job_details_screen.dart';
import 'dart:ui' as ui;

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  late GoogleMapController mapController;
  final JobService _jobService = JobService();

  LatLng? _currentPos;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 10,
  );

  List<Map<String, dynamic>> _jobs = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;

  BitmapDescriptor? _selectedMarkerIcon;
  BitmapDescriptor? _unselectedMarkerIcon;
  String? _selectedJobId;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _loadMarkerIcons();
    await _fetchJobs();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar("Location permission denied!");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
          "Location permissions are permanently denied. Please enable them in app settings.",
        );
        return;
      }
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _currentPos = LatLng(pos!.latitude, pos.longitude);
        });
        _buildMarkers();
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPos!, 14),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Location Services Disabled"),
          content: const Text(
            "Please enable location services to find jobs near you.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Settings"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Geolocator.openLocationSettings();
              },
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await _jobService.fetchJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs
              .where((j) => j['latitude'] != null && j['longitude'] != null)
              .toList();
          _isLoading = false;
        });
        _buildMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching jobs for map: $e')),
        );
      }
    }
  }

  Future<void> _loadMarkerIcons() async {
    final Uint8List selectedIconBytes = await getBytesFromAsset(
      'assets/icons/map_icon_1.png',
      72,
    );
    final Uint8List unselectedIconBytes = await getBytesFromAsset(
      'assets/icons/map_icon_2.png',
      64,
    );

    if (mounted) {
      setState(() {
        _selectedMarkerIcon = BitmapDescriptor.bytes(selectedIconBytes);
        _unselectedMarkerIcon = BitmapDescriptor.bytes(unselectedIconBytes);
      });
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  void _buildMarkers() {
    final Set<Marker> markers = {};

    if (_currentPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPos!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'You are here'),
          zIndexInt: 2,
        ),
      );
    }

    if (_unselectedMarkerIcon != null && _selectedMarkerIcon != null) {
      for (var job in _jobs) {
        final jobId = job['id'].toString();
        final isSelected = jobId == _selectedJobId;
        final lat = job['latitude'] as double;
        final lng = job['longitude'] as double;

        markers.add(
          Marker(
            markerId: MarkerId(jobId),
            position: LatLng(lat, lng),
            icon: isSelected ? _selectedMarkerIcon! : _unselectedMarkerIcon!,
            zIndexInt: isSelected ? 1 : 0,
            onTap: () {
              mapController.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
              );

              setState(() {
                _selectedJobId = jobId;
                _buildMarkers();
              });

              _showJobDetails(job);
            },
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getCurrentLocation(); // Fetch location once map is ready
    if (_jobs.isNotEmpty || _currentPos != null) {
      _buildMarkers();
    }
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          expand: false,
          builder: (_, controller) {
            return JobDetailsSheet(job: job, scrollController: controller);
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _selectedJobId = null;
          _buildMarkers();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onTap: (_) {
              if (_selectedJobId != null) {
                setState(() {
                  _selectedJobId = null;
                  _buildMarkers();
                });
              }
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Search/Filter UI
          Padding(
            padding: const EdgeInsets.only(top: 32, right: 16, left: 16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Search for position, company...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ActionChip(
                        onPressed: () {},
                        avatar: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filter'),
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        onPressed: () {},
                        avatar: const Icon(Icons.sort, size: 18),
                        label: const Text('Sort'),
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

class JobDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> job;
  final ScrollController scrollController;

  const JobDetailsSheet({
    super.key,
    required this.job,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final minPay = job['pay_amount_min'] ?? 0;
    final maxPay = job['pay_amount_max'];
    final salaryStr = maxPay != null ? '₹$minPay - ₹$maxPay' : '₹$minPay';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 32,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? 'Job Position',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['location'] ?? 'Remote',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8.0,
              children: [
                Chip(
                  label: Text(job['work_mode']?.toString().toUpperCase() ?? ''),
                  backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                ),
                Chip(
                  label: Text(salaryStr),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JobDetailsScreen(job: job, userRole: 'seeker'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Details & Apply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
