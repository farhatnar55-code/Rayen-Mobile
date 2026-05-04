enum UserRole {
  student,
  instructor,
  organizer,
  admin,
  trainer,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.student:    return 'student';
      case UserRole.instructor: return 'instructor';
      case UserRole.organizer:  return 'organizer';
      case UserRole.admin:      return 'admin';
      case UserRole.trainer:    return 'trainer';
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'instructor': return UserRole.instructor;
      case 'organizer':  return UserRole.organizer;
      case 'admin':      return UserRole.admin;
      case 'trainer':    return UserRole.trainer;
      default:           return UserRole.student;
    }
  }
}
