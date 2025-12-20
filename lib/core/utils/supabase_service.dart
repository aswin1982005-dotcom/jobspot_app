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
}
