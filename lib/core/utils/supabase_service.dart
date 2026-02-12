import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  static Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<bool> signInWithGoogle() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutterquickstart://login-callback/',
    );
  }

  static Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  static Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  static Future<bool> signInWithApple() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutterquickstart://login-callback/',
    );
  }

  static Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) {
    return _client.auth.updateUser(UserAttributes(data: data));
  }
}
