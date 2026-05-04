import 'package:rayen_mobile/features/recommendation/domain/entities/recommendation_item.dart';
import 'package:rayen_mobile/features/recommendation/domain/repositories/recommendation_repository.dart';

class GetRecommendations {
  final RecommendationRepository repository;

  GetRecommendations(this.repository);

  Future<List<RecommendationItem>> call({
    required String userId,
    required String fieldOfStudies,
    int topN = 5,
  }) {
    return repository.getRecommendations(
      userId: userId,
      fieldOfStudies: fieldOfStudies,
      topN: topN,
    );
  }
}