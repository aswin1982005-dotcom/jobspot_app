import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  bool _isProfileCompleted = false;
  String? _role;

  final _profileService = ProfileService();

  Map<String, dynamic>? get profileData => _profileData;

  bool get isLoading => _isLoading;

  bool get isProfileCompleted => _isProfileCompleted;

  String? get role => _role;

  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get role and completion status from user_profiles
      final userProfile = await Supabase.instance.client
          .from('user_profiles')
          .select('role, profile_completed')
          .eq('user_id', userId)
          .maybeSingle();

      if (userProfile != null) {
        _role = userProfile['role'];
        _isProfileCompleted = userProfile['profile_completed'] == true;

        // 2. Fetch specific profile data based on role
        if (_role == 'seeker') {
          _profileData = await _profileService.fetchSeekerProfile(userId);
        } else if (_role == 'employer') {
          _profileData = await _profileService.fetchEmployerProfile(userId);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateProfileData(Map<String, dynamic> newData) {
    if (_profileData != null) {
      _profileData!.addAll(newData);
      notifyListeners();
    }
  }

  void setProfileCompleted(bool value) {
    _isProfileCompleted = value;
    notifyListeners();
  }

  // Method to refresh data (wrapper around fetch)
  Future<void> refreshProfile() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      await fetchProfile(user.id);
    }
  }
}
