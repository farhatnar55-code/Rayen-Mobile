import 'package:rayen_mobile/features/recommendation/domain/entities/recommendation_item.dart';

abstract class RecommendationRepository {
  Future<List<RecommendationItem>> getRecommendations({
    required String userId,
    required String fieldOfStudies,
    int topN = 5,
  });
}