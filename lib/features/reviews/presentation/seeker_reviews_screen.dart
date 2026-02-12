import 'package:flutter/material.dart';
import 'package:jobspot_app/data/models/review_model.dart';
import 'package:jobspot_app/data/services/review_service.dart';
import 'package:jobspot_app/features/reviews/presentation/add_review_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class SeekerReviewsScreen extends StatefulWidget {
  final String seekerId;
  final String seekerName;
  final bool
  canWriteReview; // Only employers who hired/connected should effectively write reviews, or at least be an employer

  const SeekerReviewsScreen({
    super.key,
    required this.seekerId,
    required this.seekerName,
    this.canWriteReview = false,
  });

  @override
  State<SeekerReviewsScreen> createState() => _SeekerReviewsScreenState();
}

class _SeekerReviewsScreenState extends State<SeekerReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<ReviewModel>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    setState(() {
      _reviewsFuture = _reviewService.fetchSeekerReviews(widget.seekerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.seekerName} Reviews')),
      floatingActionButton: widget.canWriteReview
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReviewScreen(
                      revieweeId: widget.seekerId,
                      revieweeName: widget.seekerName,
                    ),
                  ),
                );
                if (result == true) {
                  _loadReviews(); // Refresh after adding
                }
              },
              label: const Text('Rate Employee'),
              icon: const Icon(Icons.rate_review),
            )
          : null,
      body: FutureBuilder<List<ReviewModel>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (widget.canWriteReview)
                    const Text('Be the first to rate this employee!')
                  else
                    const Text('This seeker has no reviews yet.'),
                ],
              ),
            );
          }

          // Calculate Average
          final double averageRating =
              reviews.fold(0, (sum, item) => sum + item.rating) /
              reviews.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ),
                          Text('${reviews.length} reviews'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final review = reviews[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: review.reviewerAvatar != null
                              ? CachedNetworkImageProvider(
                                  review.reviewerAvatar!,
                                )
                              : null,
                          child: review.reviewerAvatar == null
                              ? Text(
                                  review.reviewerName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'C',
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.reviewerName ?? 'Anonymous Company',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeago.format(review.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            if (review.comment != null &&
                                review.comment!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(review.comment!),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }, childCount: reviews.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
