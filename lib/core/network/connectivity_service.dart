import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _connectionStatusController;

  ConnectivityService._internal() {
    _connectionStatusController = StreamController<bool>.broadcast();

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  Future<bool> checkConnection() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _connectionStatusController.add(_isConnected(results));
  }

  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // We consider it connected if at least one interface is not 'none'
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
