import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';
import 'user_role.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final bool profileCompleted;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? city;
  final String? grade;
  final String? fieldOfStudies;
  final String? fieldOfStudiesId;
  final bool isSubscribed;
  final DateTime? subscriptionExpiry;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.isDeleted = false,
    required this.createdAt,
    required this.profileCompleted,
    this.photoUrl,
    this.phone,
    this.dateOfBirth,
    this.bio,
    this.city,
    this.grade,
    this.fieldOfStudies,
    this.fieldOfStudiesId,
    this.isSubscribed = false,
    this.subscriptionExpiry,
  });

  bool get isStudent => role == UserRole.student;
  bool get isInstructor => role == UserRole.instructor;
  bool get isOrganizer => role == UserRole.organizer;
  bool get isAdmin => role == UserRole.admin;
  bool get isTrainer => role == UserRole.trainer;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? map['full_name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['photo_url'] as String?,
      role: UserRoleExtension.fromString(map['role'] as String?),
      isActive: map['isActive'] as bool? ?? map['is_active'] as bool? ?? true,
      isDeleted:
          map['isDeleted'] as bool? ?? map['is_deleted'] as bool? ?? false,
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      phone: map['phone'] as String?,
      dateOfBirth: AppTimestamp.fromFirestore(map['dateOfBirth']),
      bio: map['bio'] as String?,
      city: map['city'] as String?,
      grade: map['grade'] as String?,
      fieldOfStudies:
          map['fieldOfStudies'] as String? ??
          map['field_of_studies'] as String?,
      fieldOfStudiesId:
          map['fieldOfStudiesId'] as String? ??
          map['field_of_studies_id'] as String?,
      isSubscribed:
          map['isSubscribed'] as bool? ??
          map['is_subscribed'] as bool? ??
          false,
      subscriptionExpiry: AppTimestamp.fromFirestore(
        map['subscriptionExpiry'] ?? map['subscription_expiry'],
      ),
      createdAt:
          AppTimestamp.fromFirestore(map['createdAt'] ?? map['created_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'role': role.value,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'profileCompleted': profileCompleted,
      'phone': phone,
      'dateOfBirth': AppTimestamp.toFirestore(dateOfBirth),
      'bio': bio,
      'city': city,
      'grade': grade,
      'fieldOfStudies': fieldOfStudies,
      'fieldOfStudiesId': fieldOfStudiesId,
      'isSubscribed': isSubscribed,
      'subscriptionExpiry': AppTimestamp.toFirestore(subscriptionExpiry),
      'createdAt': AppTimestamp.toFirestore(createdAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    bool? isDeleted,
    bool? profileCompleted,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
    String? city,
    String? grade,
    String? fieldOfStudies,
    String? fieldOfStudiesId,
    bool? isSubscribed,
    DateTime? subscriptionExpiry,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      grade: grade ?? this.grade,
      fieldOfStudies: fieldOfStudies ?? this.fieldOfStudies,
      fieldOfStudiesId: fieldOfStudiesId ?? this.fieldOfStudiesId,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    fullName,
    role,
    isActive,
    isDeleted,
    profileCompleted,
    phone,
    city,
    grade,
  ];
}
