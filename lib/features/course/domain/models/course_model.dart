import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

enum CourseLevel { beginner, intermediate, advanced, all }

enum CourseType { video, pdf, pack, live }

extension CourseLevelExtension on CourseLevel {
  String get value {
    switch (this) {
      case CourseLevel.beginner:
        return 'beginner';
      case CourseLevel.intermediate:
        return 'intermediate';
      case CourseLevel.advanced:
        return 'advanced';
      case CourseLevel.all:
        return 'all';
    }
  }

  static CourseLevel fromString(String? value) {
    switch (value) {
      case 'intermediate':
        return CourseLevel.intermediate;
      case 'advanced':
        return CourseLevel.advanced;
      case 'all':
        return CourseLevel.all;
      default:
        return CourseLevel.beginner;
    }
  }
}

extension CourseTypeExtension on CourseType {
  String get value {
    switch (this) {
      case CourseType.video:
        return 'video';
      case CourseType.pdf:
        return 'pdf';
      case CourseType.pack:
        return 'pack';
      case CourseType.live:
        return 'live';
    }
  }

  static CourseType fromString(String? value) {
    switch (value) {
      case 'pdf':
        return CourseType.pdf;
      case 'pack':
        return CourseType.pack;
      case 'live':
        return CourseType.live;
      default:
        return CourseType.video;
    }
  }
}

class CourseModel extends Equatable {
  final String id;
  final String title;
  final String? slug;
  final String? thumbnailUrl;
  final String? pdfUrl;
  final bool certificateEnabled;
  final String? certificatePdfUrl;
  final String? instructorId;
  final String? instructorName;
  final String? organizerId;
  final double price;
  final double? originalPrice;
  final bool isFree;
  final String currency;
  final double rating;
  final int reviewsCount;
  final int studentsCount;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final CourseLevel level;
  final CourseType type;
  final String? shortDescription;
  final String? duration;
  final String? badge;
  final bool isPublished;
  final DateTime? datePublished;

  const CourseModel({
    required this.id,
    required this.title,
    required this.price,
    required this.isFree,
    required this.currency,
    required this.rating,
    required this.reviewsCount,
    required this.studentsCount,
    required this.level,
    required this.type,
    required this.isPublished,
    this.slug,
    this.thumbnailUrl,
    this.pdfUrl,
    this.certificateEnabled = false,
    this.certificatePdfUrl,
    this.instructorId,
    this.instructorName,
    this.organizerId,
    this.originalPrice,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.shortDescription,
    this.duration,
    this.badge,
    this.datePublished,
  });

  bool get hasDiscount =>
      originalPrice != null && originalPrice! > price && !isFree;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    final price = _parsePrice(map['price']);
    final isFree =
        map['is_free'] as bool? ?? map['isFree'] as bool? ?? price == 0;

    return CourseModel(
      id: id,
      title: map['title'] as String? ?? '',
      slug: map['slug'] as String?,

      thumbnailUrl:
          map['thumbnail'] as String? ?? map['thumbnailUrl'] as String?,

      pdfUrl: map['pdfUrl'] as String? ?? map['pdf_url'] as String?,

      certificateEnabled:
          map['certificateEnabled'] as bool? ??
          map['certificate_enabled'] as bool? ??
          false,

      certificatePdfUrl:
          map['certificatePdfUrl'] as String? ??
          map['certificate_pdf_url'] as String?,

      instructorId: map['instructorId'] as String?,

      instructorName:
          map['instructor'] as String? ?? map['instructorName'] as String?,

      organizerId:
          map['organizerId'] as String? ?? map['organizer_id'] as String?,

      price: price,
      originalPrice: _parsePrice(map['original_price'] ?? map['originalPrice']),
      isFree: isFree,
      currency: map['currency'] as String? ?? 'TND',

      rating: (map['rating'] as num? ?? 0).toDouble(),
      reviewsCount: map['reviewsCount'] as int? ?? 0,

      studentsCount: _parseStudentsCount(
        map['students_count'] ?? map['studentsCount'],
      ),

      categoryId: map['category_id'] as String? ?? map['categoryId'] as String?,

      categoryName:
          map['category_name'] as String? ?? map['categoryName'] as String?,

      subcategoryId:
          map['subcategory_id'] as String? ?? map['subcategoryId'] as String?,

      subcategoryName:
          map['subcategory_name'] as String? ??
          map['subcategoryName'] as String?,

      level: CourseLevelExtension.fromString(map['level'] as String?),
      type: CourseTypeExtension.fromString(map['type'] as String?),

      shortDescription:
          map['short_description'] as String? ??
          map['shortDescription'] as String?,

      duration: map['duration'] as String?,
      badge: map['badge'] as String?,

      isPublished: map['isPublished'] as bool? ?? true,

      datePublished: _parseDate(map['date_published'] ?? map['datePublished']),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value
          .replaceAll('TND', '')
          .replaceAll('DT', '')
          .replaceAll('Gratuit', '0')
          .replaceAll('Free', '0')
          .replaceAll(RegExp(r'[^\d.]'), '')
          .trim();
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  static int _parseStudentsCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d]'), '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    return AppTimestamp.fromFirestore(value);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'thumbnailUrl': thumbnailUrl,
      'pdfUrl': pdfUrl,
      'certificateEnabled': certificateEnabled,
      'certificatePdfUrl': certificatePdfUrl,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'organizerId': organizerId,
      'price': price,
      'originalPrice': originalPrice,
      'isFree': isFree,
      'currency': currency,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'studentsCount': studentsCount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'level': level.value,
      'type': type.value,
      'shortDescription': shortDescription,
      'duration': duration,
      'badge': badge,
      'isPublished': isPublished,
      'datePublished': AppTimestamp.toFirestore(datePublished),
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? thumbnailUrl,
    String? pdfUrl,
    bool? certificateEnabled,
    String? certificatePdfUrl,
    String? instructorId,
    String? instructorName,
    String? organizerId,
    double? price,
    double? originalPrice,
    bool? isFree,
    String? currency,
    double? rating,
    int? reviewsCount,
    int? studentsCount,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    CourseLevel? level,
    CourseType? type,
    String? shortDescription,
    String? duration,
    String? badge,
    bool? isPublished,
    DateTime? datePublished,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      certificateEnabled: certificateEnabled ?? this.certificateEnabled,
      certificatePdfUrl: certificatePdfUrl ?? this.certificatePdfUrl,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      organizerId: organizerId ?? this.organizerId,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      isFree: isFree ?? this.isFree,
      currency: currency ?? this.currency,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      studentsCount: studentsCount ?? this.studentsCount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      level: level ?? this.level,
      type: type ?? this.type,
      shortDescription: shortDescription ?? this.shortDescription,
      duration: duration ?? this.duration,
      badge: badge ?? this.badge,
      isPublished: isPublished ?? this.isPublished,
      datePublished: datePublished ?? this.datePublished,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    slug,
    price,
    isFree,
    certificateEnabled,
    rating,
    studentsCount,
    categoryId,
    subcategoryId,
    isPublished,
  ];
}
