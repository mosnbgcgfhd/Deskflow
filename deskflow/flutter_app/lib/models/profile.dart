import '../core/constants.dart';

class Profile {
  final String id;
  final String organizationId;
  final String fullName;
  final UserRole role;
  final String? title;
  final String presence;

  Profile({
    required this.id,
    required this.organizationId,
    required this.fullName,
    required this.role,
    this.title,
    this.presence = 'offline',
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      fullName: map['full_name'] as String,
      role: UserRoleX.fromDb(map['role'] as String),
      title: map['title'] as String?,
      presence: map['presence'] as String? ?? 'offline',
    );
  }
}
