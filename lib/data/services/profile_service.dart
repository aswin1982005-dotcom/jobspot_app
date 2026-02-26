import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchEmployerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('employer_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_employer_profile_$userId',
          jsonEncode(response),
        );
      }
      return response;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_employer_profile_$userId');
      if (cachedStr != null) {
        debugPrint('Offline: Returning cached employer profile.');
        return jsonDecode(cachedStr) as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchSeekerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('job_seeker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_seeker_profile_$userId',
          jsonEncode(response),
        );
      }
      return response;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_seeker_profile_$userId');
      if (cachedStr != null) {
        debugPrint('Offline: Returning cached seeker profile.');
        return jsonDecode(cachedStr) as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('profile_completed')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['profile_completed'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateEmployerProfile(
    String userId,
    Map<String, dynamic> updateData, {
    bool complete = false,
  }) async {
    await _supabase.from('user_profiles').upsert({
      'user_id': userId,
      'profile_completed': complete,
    });

    if (updateData.isNotEmpty) {
      await _supabase
          .from('employer_profiles')
          .upsert(updateData, onConflict: "user_id");
    }
  }

  Future<void> updateSeekerProfile(
    String userId,
    Map<String, dynamic> updateData, {
    bool complete = false,
  }) async {
    await _supabase.from('user_profiles').upsert({
      'user_id': userId,
      'profile_completed': true,
    });

    if (updateData.isNotEmpty) {
      await _supabase
          .from('job_seeker_profiles')
          .upsert(updateData)
          .eq('user_id', userId);
    }
  }

  Future<void> createInitialProfile(String userId, String role) async {
    try {
      // 1. Create/Update user_profiles entry
      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'role': role,
        'profile_completed': false,
      });
    } catch (e) {
      debugPrint('Error creating initial profile: $e');
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrlResponse = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      return imageUrlResponse;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
}
