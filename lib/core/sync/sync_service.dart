import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jobspot_app/core/network/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  static const String _queueKey = 'offline_action_queue';
  final _uuid = const Uuid();
  bool _isProcessing = false;

  SyncService._internal() {
    // Listen for connectivity changes to trigger sync
    ConnectivityService().connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        processQueue();
      }
    });
  }

  /// Add an action to the offline queue
  Future<void> queueAction(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getStringList(_queueKey) ?? [];

    final action = {
      'id': _uuid.v4(),
      'type': actionType,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    };

    queueJson.add(jsonEncode(action));
    await prefs.setStringList(_queueKey, queueJson);
    debugPrint('Action queued: $actionType (Total: ${queueJson.length})');
  }

  /// Process all queued actions
  Future<void> processQueue() async {
    if (_isProcessing) return;

    // Safety check: only process if actually connected
    final isConnected = await ConnectivityService().checkConnection();
    if (!isConnected) return;

    _isProcessing = true;
    final prefs = await SharedPreferences.getInstance();
    List<String> queueJson = prefs.getStringList(_queueKey) ?? [];

    if (queueJson.isEmpty) {
      _isProcessing = false;
      return;
    }

    debugPrint('Starting sync for ${queueJson.length} queued actions...');
    final List<String> remainingQueue = [];
    final supabase = Supabase.instance.client;

    for (final itemStr in queueJson) {
      try {
        final action = jsonDecode(itemStr);
        final String type = action['type'];
        final Map<String, dynamic> payload = action['payload'];

        bool success = false;

        switch (type) {
          case 'fast_apply':
            await supabase.from('job_applications').insert({
              'job_post_id': payload['job_post_id'],
              'applicant_id': payload['applicant_id'],
              'application_type': payload['application_type'],
              'message': payload['message'],
            });
            success = true;
            break;
          // Add future offline actions here
          default:
            debugPrint('Unknown action type in queue: $type');
            success = true; // Remove unknown actions so they don't block
        }

        if (success) {
          debugPrint('Successfully synced action: $type');
        } else {
          // Keep in queue if not successful but didn't throw
          remainingQueue.add(itemStr);
        }
      } catch (e) {
        debugPrint('Error syncing queued action: $e');
        // Keep in queue on error (e.g., transient network issue while sinking)
        remainingQueue.add(itemStr);
      }
    }

    // Update queue with remaining items
    await prefs.setStringList(_queueKey, remainingQueue);
    _isProcessing = false;
    debugPrint('Sync completed. ${remainingQueue.length} items remaining.');
  }

  /// Get the current size of the queue
  Future<int> getQueueSize() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? []).length;
  }
}
