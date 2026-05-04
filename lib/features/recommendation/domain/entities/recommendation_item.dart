import 'package:equatable/equatable.dart';

enum RecommendationItemType { course, session }

class RecommendationItem extends Equatable {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? subtitle;
  final double score;
  final RecommendationItemType type;
  final String category;
  final String? instructorId;
  final String? trainerId;
  final double popularityScore;
  final double recencyScore;
  final bool isFree;

  const RecommendationItem({
    required this.id,
    required this.title,
    required this.score,
    required this.type,
    this.thumbnailUrl,
    this.subtitle,
    this.category = '',
    this.instructorId,
    this.trainerId,
    this.popularityScore = 0.5,
    this.recencyScore = 0.5,
    this.isFree = false,
  });

  @override
  List<Object?> get props => [id, type];
}
