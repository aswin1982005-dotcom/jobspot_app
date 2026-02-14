import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jobspot_app/data/models/review_model.dart';

class ReviewService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch reviews for a specific Company (Reviewers are Seekers)
  Future<List<ReviewModel>> fetchCompanyReviews(String companyId) async {
    try {
      // 1. Fetch reviews
      final reviewsResponse = await _client
          .from('reviews')
          .select()
          .eq('reviewee_id', companyId)
          .order('created_at', ascending: false);

      final List<dynamic> reviewsData = reviewsResponse as List<dynamic>;
      if (reviewsData.isEmpty) return [];

      // 2. Extract reviewer IDs
      final reviewerIds = reviewsData
          .map((r) => r['reviewer_id'])
          .toSet()
          .toList();

      // 3. Fetch Seeker Profiles
      final profilesResponse = await _client
          .from('job_seeker_profiles')
          .select('user_id, full_name, avatar_url')
          .filter('user_id', 'in', reviewerIds);

      final List<dynamic> profilesData = profilesResponse as List<dynamic>;

      // 4. Create a map for quick lookup: user_id -> profile data
      final Map<String, dynamic> profilesMap = {
        for (var p in profilesData) p['user_id']: p,
      };

      // 5. Merge and return
      return reviewsData.map((reviewJson) {
        final reviewerId = reviewJson['reviewer_id'];
        final profile = profilesMap[reviewerId];

        // Manually construct or Inject profile data into json to use fromJson?
        // Let's use simpler approach: copy the json and add the 'reviewer' object
        // that ReviewModel.fromJson expects.

        final Map<String, dynamic> mergedJson = Map.from(reviewJson);
        if (profile != null) {
          mergedJson['reviewer'] = profile;
        }

        return ReviewModel.fromJson(mergedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load company reviews: $e');
    }
  }

  /// Fetch reviews for a specific Seeker (Reviewers are Employers)
  Future<List<ReviewModel>> fetchSeekerReviews(String seekerId) async {
    try {
      // 1. Fetch reviews
      final reviewsResponse = await _client
          .from('reviews')
          .select()
          .eq('reviewee_id', seekerId)
          .order('created_at', ascending: false);

      final List<dynamic> reviewsData = reviewsResponse as List<dynamic>;
      if (reviewsData.isEmpty) return [];

      // 2. Extract reviewer IDs
      final reviewerIds = reviewsData
          .map((r) => r['reviewer_id'])
          .toSet()
          .toList();

      // 3. Fetch Employer Profiles
      final profilesResponse = await _client
          .from('employer_profiles')
          .select('user_id, company_name, avatar_url')
          .filter('user_id', 'in', reviewerIds);

      final List<dynamic> profilesData = profilesResponse as List<dynamic>;

      // 4. Map user_id -> profile
      final Map<String, dynamic> profilesMap = {
        for (var p in profilesData) p['user_id']: p,
      };

      // 5. Merge
      return reviewsData.map((reviewJson) {
        final reviewerId = reviewJson['reviewer_id'];
        final profile = profilesMap[reviewerId];

        final Map<String, dynamic> mergedJson = Map.from(reviewJson);
        if (profile != null) {
          mergedJson['reviewer'] = profile;
        }

        return ReviewModel.fromJson(mergedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load seeker reviews: $e');
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
