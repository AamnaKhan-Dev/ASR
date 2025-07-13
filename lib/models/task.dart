import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int estimatedMinutes;
  final int energyLevel; // 1-5 scale
  final double dopamineScore; // 0-1 scale
  final List<String> tags;
  final String? notes;
  final bool isRecurring;
  final RecurrenceType? recurrenceType;
  final double urgencyScore; // 0-100 scale
  final double importanceScore; // 0-100 scale
  final double priorityScore; // Calculated composite score

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
    this.dueDate,
    this.completedAt,
    this.estimatedMinutes = 15,
    this.energyLevel = 3,
    this.dopamineScore = 0.5,
    this.tags = const [],
    this.notes,
    this.isRecurring = false,
    this.recurrenceType,
    this.urgencyScore = 50.0,
    this.importanceScore = 50.0,
    this.priorityScore = 50.0,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    int? estimatedMinutes,
    int? energyLevel,
    double? dopamineScore,
    List<String>? tags,
    String? notes,
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    double? urgencyScore,
    double? importanceScore,
    double? priorityScore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      energyLevel: energyLevel ?? this.energyLevel,
      dopamineScore: dopamineScore ?? this.dopamineScore,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      importanceScore: importanceScore ?? this.importanceScore,
      priorityScore: priorityScore ?? this.priorityScore,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year &&
           dueDate!.month == today.month &&
           dueDate!.day == today.day;
  }

  bool get isDueSoon {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inHours;
    return difference <= 24 && difference >= 0;
  }
}

enum TaskCategory {
  work,
  personal,
  health,
  learning,
  social,
  creative,
  maintenance,
  urgent,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  paused,
}

enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.social:
        return 'Social';
      case TaskCategory.creative:
        return 'Creative';
      case TaskCategory.maintenance:
        return 'Maintenance';
      case TaskCategory.urgent:
        return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case TaskCategory.work:
        return '💼';
      case TaskCategory.personal:
        return '🏠';
      case TaskCategory.health:
        return '🏥';
      case TaskCategory.learning:
        return '📚';
      case TaskCategory.social:
        return '👥';
      case TaskCategory.creative:
        return '🎨';
      case TaskCategory.maintenance:
        return '🔧';
      case TaskCategory.urgent:
        return '🚨';
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case TaskPriority.low:
        return '🟢';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.high:
        return '🟠';
      case TaskPriority.urgent:
        return '🔴';
    }
  }
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
      case TaskStatus.paused:
        return 'Paused';
    }
  }

  String get emoji {
    switch (this) {
      case TaskStatus.pending:
        return '⏳';
      case TaskStatus.inProgress:
        return '⚡';
      case TaskStatus.completed:
        return '✅';
      case TaskStatus.cancelled:
        return '❌';
      case TaskStatus.paused:
        return '⏸️';
    }
  }
}