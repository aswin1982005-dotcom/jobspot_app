import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class ClusterItem {
  LatLng get location;
}

class MapCluster<T extends ClusterItem> {
  final LatLng location;
  final List<T> items;

  MapCluster({required this.location, required this.items});

  int get count => items.length;
  bool get isMultiple => count > 1;

  String getId() {
    return '${location.latitude}_${location.longitude}_$count';
  }
}

class MapClusterer {
  /// Clusters items based on a simple grid algorithm.
  /// [items] The list of items to cluster.
  /// [zoom] The current zoom level of the map.
  /// [gridSize] The size of the grid cell in pixels (approximate).
  static List<MapCluster<T>> cluster<T extends ClusterItem>(
    List<T> items,
    double zoom, {
    int gridSize = 80,
  }) {
    if (items.isEmpty) return [];

    // 1. Calculate the map width in pixels at the current zoom level.
    // Standard Google Maps tile size is 256x256.
    final double mapSize = 256 * pow(2, zoom).toDouble();

    // 2. Define the grid.
    // We want cells of roughly [gridSize] pixels.
    // The number of cells along the width is mapSize / gridSize.
    final double numCells = mapSize / gridSize; // e.g. 5000 cells across

    // 3. Bucket items into cells.
    // Key: "x_y" (cell coordinates)
    final Map<String, List<T>> grid = {};

    for (final item in items) {
      final point = _latLngToPoint(item.location);

      // Normalize point (0..1) to cell coordinates (0..numCells)
      final int cellX = (point.x * numCells).floor();
      final int cellY = (point.y * numCells).floor();

      final String key = '${cellX}_$cellY';
      if (!grid.containsKey(key)) {
        grid[key] = [];
      }
      grid[key]!.add(item);
    }

    // 4. Create Clusters from the grid.
    final List<MapCluster<T>> clusters = [];

    grid.forEach((key, clusterItems) {
      // Calculate average position for the cluster
      double sumLat = 0;
      double sumLng = 0;

      for (final item in clusterItems) {
        sumLat += item.location.latitude;
        sumLng += item.location.longitude;
      }

      final avgLat = sumLat / clusterItems.length;
      final avgLng = sumLng / clusterItems.length;

      clusters.add(
        MapCluster<T>(location: LatLng(avgLat, avgLng), items: clusterItems),
      );
    });

    return clusters;
  }

  /// Projects a LatLng to a Point in the range [0, 1].
  /// Uses Web Mercator projection matches Google Maps.
  static Point<double> _latLngToPoint(LatLng latLng) {
    var siny = sin(latLng.latitude * pi / 180);
    // Truncate to 0.9999 to avoid singularity at poles
    siny = min(max(siny, -0.9999), 0.9999);

    return Point<double>(
      0.5 + latLng.longitude / 360,
      0.5 - log((1 + siny) / (1 - siny)) / (4 * pi),
    );
  }
}
