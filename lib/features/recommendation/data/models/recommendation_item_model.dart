import 'package:rayen_mobile/features/recommendation/data/models/course_vector_model.dart';
import 'package:rayen_mobile/features/recommendation/domain/entities/recommendation_item.dart';

class RecommendationItemModel extends RecommendationItem {
  const RecommendationItemModel({
    required super.id,
    required super.title,
    required super.score,
    required super.type,
    super.thumbnailUrl,
    super.subtitle,
    super.category,
    super.instructorId,
    super.trainerId,
    super.popularityScore,
    super.recencyScore,
    super.isFree,
  });

  factory RecommendationItemModel.fromCourse(
    Map<String, dynamic> map,
    String id,
    double score, {
    VectorMetadata? metadata,
  }) {
    return RecommendationItemModel(
      id: id,
      title: map['title'] as String? ?? '',
      thumbnailUrl:
          map['thumbnail'] as String? ?? map['thumbnailUrl'] as String?,
      subtitle:
          map['category_name'] as String? ??
          map['categoryName'] as String? ??
          metadata?.category,
      score: score,
      type: RecommendationItemType.course,
      category: metadata?.category ?? map['category'] as String? ?? '',
      instructorId: metadata?.instructorId,
      popularityScore: metadata?.popularityScore ?? 0.5,
      recencyScore: metadata?.recencyScore ?? 0.5,
      isFree:
          metadata?.isFree ??
          map['isFree'] as bool? ??
          map['is_free'] as bool? ??
          false,
    );
  }

  factory RecommendationItemModel.fromSession(
    Map<String, dynamic> map,
    String id,
    double score, {
    VectorMetadata? metadata,
  }) {
    return RecommendationItemModel(
      id: id,
      title: map['title'] as String? ?? '',
      thumbnailUrl: null,
      subtitle:
          map['domain'] as String? ?? metadata?.domain ?? metadata?.category,
      score: score,
      type: RecommendationItemType.session,
      category: metadata?.category ?? map['category'] as String? ?? '',
      trainerId: metadata?.trainerId,
      popularityScore: metadata?.popularityScore ?? 0.5,
      recencyScore: metadata?.recencyScore ?? 0.5,
      isFree: false,
    );
  }

  double get hybridScore {
    const contentWeight = 0.5;
    const popularityWeight = 0.25;
    const recencyWeight = 0.15;
    const diversityWeight = 0.1;

    return (score * contentWeight) +
        (popularityScore * popularityWeight) +
        (recencyScore * recencyWeight) +
        (diversityWeight);
  }
}
