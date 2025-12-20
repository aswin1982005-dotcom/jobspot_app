enum UserRole { seeker, employer, admin }

extension UserRoleExtension on UserRole {
  String toDbValue() {
    switch (this) {
      case UserRole.seeker:
        return 'seeker';
      case UserRole.employer:
        return 'employer';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole? fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'seeker':
        return UserRole.seeker;
      case 'employer':
        return UserRole.employer;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}
