import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jobspot_app/data/models/notification_model.dart';
import 'package:jobspot_app/data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Timer? _pollingTimer;

  NotificationProvider() {
    _init();
    WidgetsBinding.instance.addObserver(this);
  }

  void _init() {
    _loadInitialData();
    _subscribeToRealtime();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 5 minutes as a backup to Realtime
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      debugPrint("Auto-refreshing notifications (Polling)...");
      refresh();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> refresh() async {
    await _loadInitialData();
    // Re-subscribe if needed, or check connection status
    // For now, simpler is just to fetch latest state
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed: Refreshing notifications...");
      refresh();
      _startPolling();
      // Optionally re-subscribe if Supabase connection was lost
      // _subscribeToRealtime();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _stopPolling();
    }
  }

  Future<void> _loadInitialData() async {
    // If already loading, don't trigger another one (debounce)
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.fetchNotifications();
    } catch (e) {
      debugPrint("Error loading notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToRealtime() {
    _subscription?.cancel(); // Cancel existing before re-subscribing
    _subscription = _notificationService.notificationStream.listen(
      (data) {
        _notifications = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Error in notification stream: $e");
      },
      onDone: () {
        debugPrint("Notification stream closed.");
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      // Revert if failed (optional, usually not critical for read status)
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      debugPrint("Error marking all as read: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _stopPolling();
    super.dispose();
  }
}
