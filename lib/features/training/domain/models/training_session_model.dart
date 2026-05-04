import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

enum SessionStatus { draft, published, cancelled, completed }

extension SessionStatusExtension on SessionStatus {
  String get value {
    switch (this) {
      case SessionStatus.draft:
        return 'draft';
      case SessionStatus.published:
        return 'published';
      case SessionStatus.cancelled:
        return 'cancelled';
      case SessionStatus.completed:
        return 'completed';
    }
  }

  static SessionStatus fromString(String? value) {
    switch (value) {
      case 'published':
        return SessionStatus.published;
      case 'cancelled':
        return SessionStatus.cancelled;
      case 'completed':
        return SessionStatus.completed;
      default:
        return SessionStatus.draft;
    }
  }
}

class TrainingSessionModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String domain;
  final String? topic;
  final String? imageUrl;
  final String trainerId;
  final String trainerName;
  final String organizerId;
  final String organizerName;
  final DateTime sessionDate;
  final int durationMinutes;
  final int maxParticipants;
  final int enrolledCount;
  final double price;
  final bool isFree;
  final String currency;
  final String? meetingLink;
  final SessionStatus status;
  final bool certificateEnabled;
  final DateTime createdAt;

  const TrainingSessionModel({
    required this.id,
    required this.title,
    required this.domain,
    required this.trainerId,
    required this.trainerName,
    required this.organizerId,
    required this.organizerName,
    required this.sessionDate,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.enrolledCount,
    required this.price,
    required this.isFree,
    required this.currency,
    required this.status,
    required this.certificateEnabled,
    required this.createdAt,
    this.description,
    this.topic,
    this.imageUrl,
    this.meetingLink,
  });

  bool get isFull => enrolledCount >= maxParticipants;
  bool get isAvailable => status == SessionStatus.published && !isFull;
  int get spotsRemaining => maxParticipants - enrolledCount;

  factory TrainingSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return TrainingSessionModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      domain: map['domain'] as String? ?? '',
      topic: map['topic'] as String?,
      imageUrl: map['imageUrl'] as String? ?? map['image_url'] as String?,
      trainerId: map['trainerId'] as String? ?? '',
      trainerName: map['trainerName'] as String? ?? '',
      organizerId: map['organizerId'] as String? ?? '',
      organizerName: map['organizerName'] as String? ?? '',
      sessionDate:
          AppTimestamp.fromFirestore(map['sessionDate']) ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] as int? ?? 60,
      maxParticipants: map['maxParticipants'] as int? ?? 10,
      enrolledCount: map['enrolledCount'] as int? ?? 0,
      price: (map['price'] as num? ?? 0).toDouble(),
      isFree: map['isFree'] as bool? ?? false,
      currency: map['currency'] as String? ?? 'TND',
      meetingLink: map['meetingLink'] as String?,
      status: SessionStatusExtension.fromString(map['status'] as String?),
      certificateEnabled: map['certificateEnabled'] as bool? ?? false,
      createdAt: AppTimestamp.fromFirestore(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'domain': domain,
      'topic': topic,
      'imageUrl': imageUrl,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'sessionDate': AppTimestamp.toFirestore(sessionDate),
      'durationMinutes': durationMinutes,
      'maxParticipants': maxParticipants,
      'enrolledCount': enrolledCount,
      'price': price,
      'isFree': isFree,
      'currency': currency,
      'meetingLink': meetingLink,
      'status': status.value,
      'certificateEnabled': certificateEnabled,
      'createdAt': AppTimestamp.toFirestore(createdAt),
    };
  }

  TrainingSessionModel copyWith({
    String? title,
    String? description,
    String? meetingLink,
    String? imageUrl,
    SessionStatus? status,
    int? enrolledCount,
    bool? certificateEnabled,
  }) {
    return TrainingSessionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      domain: domain,
      topic: topic,
      imageUrl: imageUrl ?? this.imageUrl,
      trainerId: trainerId,
      trainerName: trainerName,
      organizerId: organizerId,
      organizerName: organizerName,
      sessionDate: sessionDate,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      price: price,
      isFree: isFree,
      currency: currency,
      meetingLink: meetingLink ?? this.meetingLink,
      status: status ?? this.status,
      certificateEnabled: certificateEnabled ?? this.certificateEnabled,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    domain,
    trainerId,
    organizerId,
    sessionDate,
    status,
    enrolledCount,
  ];
}
