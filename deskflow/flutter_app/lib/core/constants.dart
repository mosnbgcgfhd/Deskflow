/// Fill these in with your Supabase project credentials.
/// Get them from: Supabase Dashboard -> Project Settings -> API
class SupabaseConfig {
  static const String url = 'https://YOUR-PROJECT.supabase.co';
  static const String anonKey = 'YOUR-ANON-KEY';
}

/// Mirrors the `user_role` enum defined in the Postgres schema.
/// Fixed 3-role model for V1 — no custom/dynamic permissions.
enum UserRole { admin, manager, employee }

extension UserRoleX on UserRole {
  String get dbValue => name; // 'admin' | 'manager' | 'employee'

  static UserRole fromDb(String value) {
    return UserRole.values.firstWhere(
      (r) => r.dbValue == value,
      orElse: () => UserRole.employee,
    );
  }

  bool get canManageProjects => this == UserRole.admin || this == UserRole.manager;
  bool get canManageTeam => this == UserRole.admin || this == UserRole.manager;
  bool get canViewReports => this == UserRole.admin || this == UserRole.manager;
  bool get canManageCompanySettings => this == UserRole.admin;
}

enum TaskStatus { todo, inProgress, inReview, done }

extension TaskStatusX on TaskStatus {
  String get dbValue {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.inReview:
        return 'in_review';
      case TaskStatus.done:
        return 'done';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.inReview:
        return 'In Review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromDb(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'in_review':
        return TaskStatus.inReview;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }
}
