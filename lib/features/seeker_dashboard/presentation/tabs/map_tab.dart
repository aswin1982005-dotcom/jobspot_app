import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'dart:ui' as ui;

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  late GoogleMapController mapController;
  final JobService _jobService = JobService();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Default to Mumbai
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

  Future<void> _fetchJobs() async {
    try {
      final jobs = await _jobService.fetchJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs.where((j) => j['latitude'] != null && j['longitude'] != null).toList();
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
    if (_unselectedMarkerIcon == null || _selectedMarkerIcon == null) return;

    final markers = _jobs.map((job) {
      final jobId = job['id'].toString();
      final isSelected = jobId == _selectedJobId;
      final lat = job['latitude'] as double;
      final lng = job['longitude'] as double;

      return Marker(
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
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_jobs.isNotEmpty) {
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          // Search/Filter UI
          Padding(
            padding: const EdgeInsets.only(top: 32, right: 16, left: 16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Search for position, company...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        onPressed: () {},
                        avatar: const Icon(Icons.sort, size: 18),
                        label: const Text('Sort'),
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ],
                  ),
                ),
              ],
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
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: const Icon(Icons.business, size: 32, color: AppColors.purple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? 'Job Position',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['location'] ?? 'Remote',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
                  labelStyle: const TextStyle(color: AppColors.purple, fontSize: 12),
                  side: BorderSide.none,
                ),
                Chip(
                  label: Text(salaryStr),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Details & Apply', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
