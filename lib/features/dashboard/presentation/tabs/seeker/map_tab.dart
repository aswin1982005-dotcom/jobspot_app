import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/core/theme/map_styles.dart';
import 'package:jobspot_app/core/utils/map_clustering_helper.dart'; // Import Custom Clusterer
import 'package:jobspot_app/features/jobs/presentation/job_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';

class JobItem implements ClusterItem {
  final Map<String, dynamic> job;
  final LatLng jobLocation;

  JobItem(this.job, this.jobLocation);

  @override
  LatLng get location => jobLocation;
}

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  late GoogleMapController _mapController;

  // State
  Set<Marker> _markers = {};
  List<JobItem> _jobItems = [];
  bool _isLoading = true;
  double _currentZoom = 10.0;
  String? _selectedJobId;
  CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 10,
  );

  List<Map<String, dynamic>>? _lastJobs;

  // Icons cache
  final Map<String, BitmapDescriptor> _iconCache = {};

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedJobTypes = [];
  final List<String> _jobTypes = [
    'Full-Time',
    'Part-Time',
    'Contract',
    'Internship',
    'Freelance',
  ];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithProvider();
  }

  void _syncWithProvider() {
    final provider = Provider.of<SeekerHomeProvider>(context);
    if (provider.recommendedJobs != _lastJobs) {
      _lastJobs = provider.recommendedJobs;
      _updateJobItemsFromProvider(provider.recommendedJobs);
    }
  }

  void _updateJobItemsFromProvider(List<Map<String, dynamic>> jobs) {
    final items = jobs
        .where((j) => j['latitude'] != null && j['longitude'] != null)
        .map((j) => JobItem(j, LatLng(j['latitude'], j['longitude'])))
        .toList();

    setState(() {
      _jobItems = items;
      _isLoading = false;
    });
    _updateFilteredItems();
  }

  Future<void> _initMap() async {
    await _loadMarkerIcons();
    _initLocation();
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition();
        _initialPosition = CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 10,
        );
      } catch (e) {
        // Handle error or permission denied silently or via snackbar
      }
    }
  }

  Future<void> _loadMarkerIcons() async {
    _iconCache['unselected_small'] = await _getBitmapDescriptor(
      'assets/icons/map_icon_2.png',
      32,
    ); // Resize to 32
    _iconCache['unselected_medium'] = await _getBitmapDescriptor(
      'assets/icons/map_icon_2.png',
      48,
    ); // Resize to 48
    _iconCache['unselected_large'] = await _getBitmapDescriptor(
      'assets/icons/map_icon_2.png',
      64,
    ); // Resize to 64

    // Selected
    _iconCache['selected_small'] = await _getBitmapDescriptor(
      'assets/icons/map_icon_1.png',
      40,
    );
    _iconCache['selected_medium'] = await _getBitmapDescriptor(
      'assets/icons/map_icon_1.png',
      64,
    );
    _iconCache['selected_large'] = await _getBitmapDescriptor(
      'assets/icons/map_icon_1.png',
      80,
    );

    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _getBitmapDescriptor(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  void _updateFilteredItems() {
    List<JobItem> filtered = _jobItems;
    final query = _searchController.text.toLowerCase();

    // Search Filter
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        final title = (item.job['title'] as String?)?.toLowerCase() ?? '';
        final company =
            (item.job['company_name'] as String?)?.toLowerCase() ?? '';
        return title.contains(query) || company.contains(query);
      }).toList();
    }

    // Type Filter
    if (_selectedJobTypes.isNotEmpty) {
      filtered = filtered.where((item) {
        final type =
            (item.job['job_type'] as String?) ??
            (item.job['work_mode'] as String?) ??
            '';
        return _selectedJobTypes.any(
          (selected) => type.toLowerCase().contains(selected.toLowerCase()),
        );
      }).toList();
    }

    // Run clustering
    _clusterItems(filtered);
  }

  Future<void> _clusterItems(List<JobItem> items) async {
    // Run clustering implementation
    final clusters = MapClusterer.cluster(items, _currentZoom);
    final markers = <Marker>{};

    for (final cluster in clusters) {
      markers.add(await _buildMarker(cluster));
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  // Cluster icon cache
  final Map<int, BitmapDescriptor> _clusterIconCache = {};

  Future<Marker> _buildMarker(MapCluster<JobItem> cluster) async {
    if (cluster.isMultiple) {
      final count = cluster.count;
      BitmapDescriptor icon;

      if (_clusterIconCache.containsKey(count)) {
        icon = _clusterIconCache[count]!;
      } else {
        icon = await _getClusterBitmap(
          count,
          size: 100,
          text: count.toString(),
        );
        _clusterIconCache[count] = icon;
      }

      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        onTap: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(cluster.location, _currentZoom + 2),
          );
        },
        icon: icon,
      );
    } else {
      final item = cluster.items.first;
      final jobId = item.job['id'].toString();
      final isSelected = jobId == _selectedJobId;

      // Dynamic sizing logic based on _currentZoom
      String sizeKey = 'medium';
      if (_currentZoom < 11) {
        sizeKey = 'small';
      } else if (_currentZoom > 15) {
        sizeKey = 'large';
      }

      final iconKey = '${isSelected ? "selected" : "unselected"}_$sizeKey';
      final icon = _iconCache[iconKey] ?? BitmapDescriptor.defaultMarker;

      return Marker(
        markerId: MarkerId(jobId),
        position: cluster.location,
        icon: icon,
        zIndexInt: isSelected ? 10 : 1,
        onTap: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(cluster.location, 16),
          ); // Zoom in on tap
          setState(() {
            _selectedJobId = jobId;
          });
          _updateFilteredItems();
          _showJobDetails(item.job);
        },
      );
    }
  }

  Future<BitmapDescriptor> _getClusterBitmap(
    int count, {
    int size = 150,
    String? text,
  }) async {
    if (kIsWeb) return BitmapDescriptor.defaultMarker;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = AppColors.purple;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  void _showJobDetails(Map<String, dynamic> job) {
    final provider = Provider.of<SeekerHomeProvider>(context, listen: false);

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
            final isApplied = provider.isJobApplied(job['id']);
            return JobDetailsSheet(
              job: job,
              scrollController: controller,
              isApplied: isApplied,
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _selectedJobId = null;
          _updateFilteredItems();
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    } catch (e) {
      // Handle error or permission denied silently or via snackbar
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Job Type',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._jobTypes.map((type) {
                    return CheckboxListTile(
                      title: Text(type),
                      value: _selectedJobTypes.contains(type),
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedJobTypes.add(type);
                          } else {
                            _selectedJobTypes.remove(type);
                          }
                        });
                        // Update main state
                        setState(() {
                          _updateFilteredItems();
                        });
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            style: Theme.of(context).brightness == Brightness.dark
                ? MapStyles.darkStyle
                : null,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            onCameraMove: (position) {
              _currentZoom = position.zoom;
            },
            onCameraIdle: () {
              _updateFilteredItems();
            },
            onTap: (_) {
              if (_selectedJobId != null) {
                setState(() {
                  _selectedJobId = null;
                  _updateFilteredItems();
                });
              }
            },
          ),
          if (_isLoading ||
              context.select<SeekerHomeProvider, bool>((p) => p.isLoading))
            const Center(child: CircularProgressIndicator()),

          // Search/Filter UI
          Padding(
            padding: const EdgeInsets.only(
              top: 48,
              right: 16,
              left: 16,
            ), // Increased top padding for safe area
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _updateFilteredItems();
                    }),
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Search position, company...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
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
                        onPressed: _showFilterOptions,
                        avatar: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filter Type'),
                        backgroundColor: Theme.of(context).cardColor,
                        // elevation: 2, // Removed elevation to fix lint
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
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
  final bool isApplied;

  const JobDetailsSheet({
    super.key,
    required this.job,
    required this.scrollController,
    this.isApplied = false,
  });

  Future<void> _openDirections() async {
    final lat = job['latitude'];
    final lng = job['longitude'];
    if (lat != null && lng != null) {
      final uri = Uri.parse("google.navigation:q=$lat,$lng");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to web map
        final webUri = Uri.parse(
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

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
                IconButton(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.directions, color: AppColors.purple),
                  tooltip: "Get Directions",
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
                      builder: (context) => JobDetailsScreen(
                        job: job,
                        userRole: 'seeker',
                        isApplied: isApplied,
                      ),
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
                child: Text(
                  isApplied ? 'Applied' : 'View Details & Apply',
                  style: const TextStyle(color: Colors.white),
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
