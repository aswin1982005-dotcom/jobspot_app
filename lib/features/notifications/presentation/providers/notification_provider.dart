import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jobspot_app/data/models/notification_model.dart';
import 'package:jobspot_app/data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _init();
  }

  void _init() {
    _loadInitialData();
    _subscribeToRealtime();
  }

  Future<void> _loadInitialData() async {
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
    _subscription = _notificationService.notificationStream.listen(
      (data) {
        _notifications = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Error in notification stream: $e");
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
    _subscription?.cancel();
    super.dispose();
  }
}
