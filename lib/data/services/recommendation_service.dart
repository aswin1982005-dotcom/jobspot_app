import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRecommendedJobs() async {
    try {
      final response = await _client.functions.invoke('recommend-jobs');

      final data = response.data;
      if (data == null) {
        return [];
      }

      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      // Log error or rethrow
      return [];
    }
  }
}
