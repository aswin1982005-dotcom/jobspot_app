import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jobspot_app/data/models/review_model.dart';

class ReviewService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch reviews for a specific user (company or seeker)
  Future<List<ReviewModel>> fetchReviews(String revieweeId) async {
    try {
      final response = await _client
          .from('reviews')
          .select(
            '*, reviewer:reviewer_id(full_name, company_name, avatar_url)',
          )
          .eq('reviewee_id', revieweeId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  /// Add a new review
  Future<void> addReview({
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _client.from('reviews').insert({
        'reviewer_id': user.id,
        'reviewee_id': revieweeId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }
}
