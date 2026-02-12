import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/admin_service.dart';

class UserManagementProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _users = [];
  String? _roleFilter;
  bool? _disabledFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get users => _users;
  String? get roleFilter => _roleFilter;
  bool? get disabledFilter => _disabledFilter;

  /// Load users with current filters
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminService.fetchAllUsers(
        roleFilter: _roleFilter,
        disabledOnly: _disabledFilter,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set role filter
  void setRoleFilter(String? role) {
    _roleFilter = role;
    loadUsers();
  }

  /// Set disabled filter
  void setDisabledFilter(bool? disabled) {
    _disabledFilter = disabled;
    loadUsers();
  }

  /// Clear all filters
  void clearFilters() {
    _roleFilter = null;
    _disabledFilter = null;
    loadUsers();
  }

  /// Disable a user
  Future<void> disableUser(String userId, String reason) async {
    try {
      await _adminService.disableUser(userId, reason);
      await loadUsers(); // Refresh list
    } catch (e) {
      _error = e.toString();
      debugPrint('Error disabling user: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Enable a user
  Future<void> enableUser(String userId) async {
    try {
      await _adminService.enableUser(userId);
      await loadUsers(); // Refresh list
    } catch (e) {
      _error = e.toString();
      debugPrint('Error enabling user: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh users list
  Future<void> refresh() => loadUsers();
}
