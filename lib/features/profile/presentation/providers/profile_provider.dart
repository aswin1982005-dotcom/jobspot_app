import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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

  Future<bool> uploadProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return false;

      // Crop image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) return false;

      _isLoading = true;
      notifyListeners();

      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId == null) return false;

      final imageUrl = await _profileService.uploadProfileImage(
        userId,
        File(croppedFile.path),
      );

      // Update Database
      if (_role == 'seeker') {
        await _profileService.updateSeekerProfile(userId, {
          'avatar_url': imageUrl,
        });
      } else if (_role == 'employer') {
        await _profileService.updateEmployerProfile(userId, {
          'avatar_url': imageUrl,
        });
      }

      // Update local state
      updateProfileData({'avatar_url': imageUrl});

      return true;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
