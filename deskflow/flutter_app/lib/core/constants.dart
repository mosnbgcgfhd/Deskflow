/// Fill these in with your Supabase project credentials.
/// Get them from: Supabase Dashboard -> Project Settings -> API
class SupabaseConfig {
  static const String url = 'https://nwfybyxwxtydwovdfdco.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53ZnlieXh3eHR5ZHdvdmRmZGNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0ODA3MjEsImV4cCI6MjEwMjA1NjcyMX0.zQ8myRIWKsNs2d6IEYY_9bqANR1bWvPBZfYrt4Frl9s';
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
