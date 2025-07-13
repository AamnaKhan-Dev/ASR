import 'package:json_annotation/json_annotation.dart';
import 'task.dart';

part 'task_intent.g.dart';

@JsonSerializable()
class TaskIntent {
  final IntentType intent;
  final String taskDescription;
  final String? rawTranscript;
  final TaskCategory category;
  final String urgency;
  final String? dueDate;
  final String? context;
  final double confidence;
  final int? estimatedMinutes;
  final List<String> keywords;
  final TaskAction? action;
  final String? targetTaskId;

  TaskIntent({
    required this.intent,
    required this.taskDescription,
    this.rawTranscript,
    this.category = TaskCategory.personal,
    this.urgency = 'medium',
    this.dueDate,
    this.context,
    required this.confidence,
    this.estimatedMinutes,
    this.keywords = const [],
    this.action,
    this.targetTaskId,
  });

  factory TaskIntent.fromJson(Map<String, dynamic> json) => _$TaskIntentFromJson(json);
  Map<String, dynamic> toJson() => _$TaskIntentToJson(this);

  TaskIntent copyWith({
    IntentType? intent,
    String? taskDescription,
    String? rawTranscript,
    TaskCategory? category,
    String? urgency,
    String? dueDate,
    String? context,
    double? confidence,
    int? estimatedMinutes,
    List<String>? keywords,
    TaskAction? action,
    String? targetTaskId,
  }) {
    return TaskIntent(
      intent: intent ?? this.intent,
      taskDescription: taskDescription ?? this.taskDescription,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      dueDate: dueDate ?? this.dueDate,
      context: context ?? this.context,
      confidence: confidence ?? this.confidence,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      keywords: keywords ?? this.keywords,
      action: action ?? this.action,
      targetTaskId: targetTaskId ?? this.targetTaskId,
    );
  }

  TaskPriority get priorityLevel {
    switch (urgency.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  DateTime? get parsedDueDate {
    if (dueDate == null) return null;
    
    final now = DateTime.now();
    final lowerDueDate = dueDate!.toLowerCase();
    
    // Handle relative dates
    if (lowerDueDate.contains('today')) {
      return DateTime(now.year, now.month, now.day, 23, 59);
    } else if (lowerDueDate.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
    } else if (lowerDueDate.contains('next week')) {
      final nextWeek = now.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 23, 59);
    } else if (lowerDueDate.contains('this evening')) {
      return DateTime(now.year, now.month, now.day, 18, 0);
    } else if (lowerDueDate.contains('this morning')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    }
    
    // Try to parse as a date
    try {
      return DateTime.parse(dueDate!);
    } catch (e) {
      return null;
    }
  }

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.6 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.6;
}

enum IntentType {
  createTask,
  reminder,
  question,
  help,
  explain,
  editTask,
  deleteTask,
  completeTask,
  pauseTask,
  resumeTask,
  listTasks,
  searchTasks,
  prioritizeTask,
  schedule,
  unknown,
}

enum TaskAction {
  create,
  edit,
  delete,
  complete,
  pause,
  resume,
  prioritize,
  schedule,
  search,
  list,
}

extension IntentTypeExtension on IntentType {
  String get displayName {
    switch (this) {
      case IntentType.createTask:
        return 'Create Task';
      case IntentType.reminder:
        return 'Reminder';
      case IntentType.question:
        return 'Question';
      case IntentType.help:
        return 'Help';
      case IntentType.explain:
        return 'Explain';
      case IntentType.editTask:
        return 'Edit Task';
      case IntentType.deleteTask:
        return 'Delete Task';
      case IntentType.completeTask:
        return 'Complete Task';
      case IntentType.pauseTask:
        return 'Pause Task';
      case IntentType.resumeTask:
        return 'Resume Task';
      case IntentType.listTasks:
        return 'List Tasks';
      case IntentType.searchTasks:
        return 'Search Tasks';
      case IntentType.prioritizeTask:
        return 'Prioritize Task';
      case IntentType.schedule:
        return 'Schedule';
      case IntentType.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case IntentType.createTask:
        return '➕';
      case IntentType.reminder:
        return '🔔';
      case IntentType.question:
        return '❓';
      case IntentType.help:
        return '🆘';
      case IntentType.explain:
        return '💡';
      case IntentType.editTask:
        return '✏️';
      case IntentType.deleteTask:
        return '🗑️';
      case IntentType.completeTask:
        return '✅';
      case IntentType.pauseTask:
        return '⏸️';
      case IntentType.resumeTask:
        return '▶️';
      case IntentType.listTasks:
        return '📋';
      case IntentType.searchTasks:
        return '🔍';
      case IntentType.prioritizeTask:
        return '🔺';
      case IntentType.schedule:
        return '📅';
      case IntentType.unknown:
        return '❓';
    }
  }
}

extension TaskActionExtension on TaskAction {
  String get displayName {
    switch (this) {
      case TaskAction.create:
        return 'Create';
      case TaskAction.edit:
        return 'Edit';
      case TaskAction.delete:
        return 'Delete';
      case TaskAction.complete:
        return 'Complete';
      case TaskAction.pause:
        return 'Pause';
      case TaskAction.resume:
        return 'Resume';
      case TaskAction.prioritize:
        return 'Prioritize';
      case TaskAction.schedule:
        return 'Schedule';
      case TaskAction.search:
        return 'Search';
      case TaskAction.list:
        return 'List';
    }
  }
}