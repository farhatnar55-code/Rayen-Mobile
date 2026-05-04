class CourseVectorModel {
  final String id;
  final List<double> vector;
  final VectorMetadata? metadata;

  CourseVectorModel({required this.id, required this.vector, this.metadata});

  factory CourseVectorModel.fromMap(Map<String, dynamic> map, String id) {
    final raw = map['vector'] as List<dynamic>? ?? [];
    final meta = map['metadata'] as Map<String, dynamic>?;

    return CourseVectorModel(
      id: id,
      vector: raw.map((e) => (e as num).toDouble()).toList(),
      metadata: meta != null ? VectorMetadata.fromMap(meta) : null,
    );
  }
}

class VectorMetadata {
  final String category;
  final String? instructorId;
  final String? trainerId;
  final String? domain;
  final String level;
  final bool isFree;
  final int studentsCount;
  final int enrolledCount;
  final int maxParticipants;
  final double rating;
  final double popularityScore;
  final double recencyScore;

  VectorMetadata({
    this.category = '',
    this.instructorId,
    this.trainerId,
    this.domain,
    this.level = 'All Levels',
    this.isFree = false,
    this.studentsCount = 0,
    this.enrolledCount = 0,
    this.maxParticipants = 0,
    this.rating = 0.0,
    this.popularityScore = 0.5,
    this.recencyScore = 0.5,
  });

  factory VectorMetadata.fromMap(Map<String, dynamic> map) {
    return VectorMetadata(
      category: map['category'] as String? ?? '',
      instructorId: map['instructorId'] as String?,
      trainerId: map['trainerId'] as String?,
      domain: map['domain'] as String?,
      level: map['level'] as String? ?? 'All Levels',
      isFree: map['isFree'] as bool? ?? false,
      studentsCount: (map['studentsCount'] as num?)?.toInt() ?? 0,
      enrolledCount: (map['enrolledCount'] as num?)?.toInt() ?? 0,
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      popularityScore: (map['popularityScore'] as num?)?.toDouble() ?? 0.5,
      recencyScore: (map['recencyScore'] as num?)?.toDouble() ?? 0.5,
    );
  }

  double get capacityRatio {
    if (maxParticipants <= 0) return 0.0;
    return enrolledCount / maxParticipants;
  }
}
