class ReviewModel {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName; // Optional, joined from profiles
  final String? reviewerAvatar; // Optional, joined from profiles

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data if available
    String? name;
    String? avatar;

    if (json['reviewer'] != null) {
      final reviewer = json['reviewer'];
      if (reviewer is Map) {
        // Check both possible keys for name
        name =
            reviewer['full_name'] ?? reviewer['company_name'] ?? 'Unknown User';
        avatar = reviewer['avatar_url'];
      }
    }

    return ReviewModel(
      id: json['id'],
      reviewerId: json['reviewer_id'],
      revieweeId: json['reviewee_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      reviewerName: name ?? 'Anonymous',
      reviewerAvatar: avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
    };
  }
}
