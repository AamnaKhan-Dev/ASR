import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/task_intent.dart';

class ADHDTaskPrioritizer {
  // ADHD-specific scoring weights
  static const double _urgencyWeight = 0.25;
  static const double _importanceWeight = 0.20;
  static const double _energyWeight = 0.15;
  static const double _dopamineWeight = 0.15;
  static const double _timeOptimizationWeight = 0.10;
  static const double _interestWeight = 0.10;
  static const double _contextWeight = 0.05;
  
  // Time-based factors
  static const int _morningPeakStart = 9;
  static const int _morningPeakEnd = 11;
  static const int _eveningPeakStart = 17;
  static const int _eveningPeakEnd = 20;
  
  /// Calculate priority score for a task based on ADHD-specific factors
  double calculatePriorityScore(Task task) {
    final urgencyScore = _calculateUrgencyScore(task);
    final importanceScore = _calculateImportanceScore(task);
    final energyScore = _calculateEnergyScore(task);
    final dopamineScore = _calculateDopamineScore(task);
    final timeOptimizationScore = _calculateTimeOptimizationScore(task);
    final interestScore = _calculateInterestScore(task);
    final contextScore = _calculateContextScore(task);
    
    final totalScore = (urgencyScore * _urgencyWeight) +
                      (importanceScore * _importanceWeight) +
                      (energyScore * _energyWeight) +
                      (dopamineScore * _dopamineWeight) +
                      (timeOptimizationScore * _timeOptimizationWeight) +
                      (interestScore * _interestWeight) +
                      (contextScore * _contextWeight);
    
    return totalScore.clamp(0.0, 100.0);
  }
  
  /// Calculate priority score from task intent
  double calculatePriorityScoreFromIntent(TaskIntent intent) {
    final urgencyScore = _mapUrgencyToScore(intent.urgency);
    final importanceScore = _mapCategoryToImportance(intent.category);
    final energyScore = _estimateEnergyFromIntent(intent);
    final dopamineScore = _estimateDopamineFromIntent(intent);
    final timeOptimizationScore = _calculateTimeOptimizationFromIntent(intent);
    final interestScore = _calculateInterestFromIntent(intent);
    final contextScore = _calculateContextFromIntent(intent);
    
    final totalScore = (urgencyScore * _urgencyWeight) +
                      (importanceScore * _importanceWeight) +
                      (energyScore * _energyWeight) +
                      (dopamineScore * _dopamineWeight) +
                      (timeOptimizationScore * _timeOptimizationWeight) +
                      (interestScore * _interestWeight) +
                      (contextScore * _contextWeight);
    
    return totalScore.clamp(0.0, 100.0);
  }
  
  /// Sort tasks by ADHD-optimized priority
  List<Task> prioritizeTasks(List<Task> tasks) {
    final scoredTasks = tasks.map((task) {
      final score = calculatePriorityScore(task);
      return _ScoredTask(task, score);
    }).toList();
    
    // Sort by score (descending) and then by due date
    scoredTasks.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      
      // If scores are equal, prioritize by due date
      if (a.task.dueDate != null && b.task.dueDate != null) {
        return a.task.dueDate!.compareTo(b.task.dueDate!);
      } else if (a.task.dueDate != null) {
        return -1;
      } else if (b.task.dueDate != null) {
        return 1;
      }
      
      return 0;
    });
    
    return scoredTasks.map((scored) => scored.task).toList();
  }
  
  /// Get tasks suitable for current time and energy level
  List<Task> getOptimalTasksForNow(List<Task> tasks, int currentEnergyLevel) {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    return tasks.where((task) {
      // Filter by energy level compatibility
      if (task.energyLevel > currentEnergyLevel + 1) return false;
      
      // Filter by time compatibility
      if (!_isTimeOptimalForCategory(task.category, currentHour)) return false;
      
      // Filter by urgency
      if (task.isOverdue || task.isDueSoon) return true;
      
      return true;
    }).toList();
  }
  
  /// Get quick tasks suitable for ADHD hyperfocus breaks
  List<Task> getQuickTasks(List<Task> tasks, {int maxMinutes = 15}) {
    return tasks
        .where((task) => 
            task.estimatedMinutes <= maxMinutes && 
            task.status == TaskStatus.pending)
        .toList();
  }
  
  /// Get tasks suitable for hyperfocus sessions
  List<Task> getHyperfocusTasks(List<Task> tasks) {
    return tasks
        .where((task) => 
            task.estimatedMinutes >= 30 && 
            task.dopamineScore >= 0.6 &&
            task.status == TaskStatus.pending)
        .toList();
  }
  
  /// Calculate urgency score (0-100)
  double _calculateUrgencyScore(Task task) {
    if (task.isOverdue) return 100.0;
    if (task.isDueToday) return 90.0;
    if (task.isDueSoon) return 80.0;
    
    switch (task.priority) {
      case TaskPriority.urgent:
        return 95.0;
      case TaskPriority.high:
        return 75.0;
      case TaskPriority.medium:
        return 50.0;
      case TaskPriority.low:
        return 25.0;
    }
  }
  
  /// Calculate importance score (0-100)
  double _calculateImportanceScore(Task task) {
    // Base importance from category
    double baseScore = _mapCategoryToImportance(task.category);
    
    // Boost for recurring tasks (habits are important for ADHD)
    if (task.isRecurring) baseScore += 10.0;
    
    // Boost for tasks with clear deadlines
    if (task.dueDate != null) baseScore += 10.0;
    
    return baseScore.clamp(0.0, 100.0);
  }
  
  /// Calculate energy score based on current energy and task requirements
  double _calculateEnergyScore(Task task) {
    final currentHour = DateTime.now().hour;
    
    // Higher score for tasks that match current energy patterns
    if (_isHighEnergyTime(currentHour)) {
      return task.energyLevel >= 4 ? 80.0 : 60.0;
    } else if (_isMediumEnergyTime(currentHour)) {
      return task.energyLevel == 3 ? 80.0 : 60.0;
    } else {
      return task.energyLevel <= 2 ? 80.0 : 40.0;
    }
  }
  
  /// Calculate dopamine score for motivation
  double _calculateDopamineScore(Task task) {
    return task.dopamineScore * 100.0;
  }
  
  /// Calculate time optimization score
  double _calculateTimeOptimizationScore(Task task) {
    final currentHour = DateTime.now().hour;
    
    // Quick tasks get higher score during low-energy times
    if (task.estimatedMinutes <= 15 && !_isHighEnergyTime(currentHour)) {
      return 80.0;
    }
    
    // Time-blocking optimization
    if (_isTimeOptimalForCategory(task.category, currentHour)) {
      return 90.0;
    }
    
    return 50.0;
  }
  
  /// Calculate interest/motivation score
  double _calculateInterestScore(Task task) {
    // Creative and learning tasks often have high interest for ADHD
    if (task.category == TaskCategory.creative || 
        task.category == TaskCategory.learning) {
      return 80.0;
    }
    
    // Variety boost (different from last completed task)
    // This would require task history tracking
    return 60.0;
  }
  
  /// Calculate context score
  double _calculateContextScore(Task task) {
    final currentHour = DateTime.now().hour;
    
    // Work tasks during work hours
    if (task.category == TaskCategory.work && 
        currentHour >= 9 && currentHour <= 17) {
      return 90.0;
    }
    
    // Personal tasks during evening
    if (task.category == TaskCategory.personal && 
        currentHour >= 17) {
      return 90.0;
    }
    
    return 50.0;
  }
  
  // Helper methods
  double _mapUrgencyToScore(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return 95.0;
      case 'high':
        return 75.0;
      case 'medium':
        return 50.0;
      case 'low':
        return 25.0;
      default:
        return 50.0;
    }
  }
  
  double _mapCategoryToImportance(TaskCategory category) {
    switch (category) {
      case TaskCategory.urgent:
        return 95.0;
      case TaskCategory.health:
        return 85.0;
      case TaskCategory.work:
        return 80.0;
      case TaskCategory.learning:
        return 75.0;
      case TaskCategory.personal:
        return 70.0;
      case TaskCategory.social:
        return 65.0;
      case TaskCategory.creative:
        return 60.0;
      case TaskCategory.maintenance:
        return 55.0;
    }
  }
  
  double _estimateEnergyFromIntent(TaskIntent intent) {
    final keywords = intent.keywords;
    
    if (keywords.any((k) => ['complex', 'difficult', 'challenging', 'project'].contains(k))) {
      return 90.0; // High energy required
    } else if (keywords.any((k) => ['quick', 'simple', 'easy', 'call'].contains(k))) {
      return 30.0; // Low energy required
    }
    
    return 60.0; // Medium energy
  }
  
  double _estimateDopamineFromIntent(TaskIntent intent) {
    final keywords = intent.keywords;
    
    if (keywords.any((k) => ['creative', 'fun', 'interesting', 'learning'].contains(k))) {
      return 80.0;
    } else if (keywords.any((k) => ['boring', 'routine', 'paperwork'].contains(k))) {
      return 30.0;
    }
    
    return 50.0;
  }
  
  double _calculateTimeOptimizationFromIntent(TaskIntent intent) {
    final estimatedMinutes = intent.estimatedMinutes ?? 30;
    final currentHour = DateTime.now().hour;
    
    // Quick tasks during low-energy times
    if (estimatedMinutes <= 15 && !_isHighEnergyTime(currentHour)) {
      return 80.0;
    }
    
    return 50.0;
  }
  
  double _calculateInterestFromIntent(TaskIntent intent) {
    if (intent.category == TaskCategory.creative || 
        intent.category == TaskCategory.learning) {
      return 80.0;
    }
    
    return 60.0;
  }
  
  double _calculateContextFromIntent(TaskIntent intent) {
    return _calculateContextScore(Task(
      title: intent.taskDescription,
      description: intent.taskDescription,
      category: intent.category,
      priority: intent.priorityLevel,
    ));
  }
  
  bool _isHighEnergyTime(int hour) {
    return (hour >= _morningPeakStart && hour <= _morningPeakEnd);
  }
  
  bool _isMediumEnergyTime(int hour) {
    return (hour >= _eveningPeakStart && hour <= _eveningPeakEnd);
  }
  
  bool _isTimeOptimalForCategory(TaskCategory category, int hour) {
    switch (category) {
      case TaskCategory.work:
        return hour >= 9 && hour <= 17;
      case TaskCategory.creative:
        return hour >= 10 && hour <= 12 || hour >= 19 && hour <= 22;
      case TaskCategory.learning:
        return hour >= 9 && hour <= 11 || hour >= 15 && hour <= 17;
      case TaskCategory.social:
        return hour >= 17 && hour <= 22;
      case TaskCategory.health:
        return hour >= 7 && hour <= 9 || hour >= 18 && hour <= 20;
      case TaskCategory.maintenance:
        return hour >= 16 && hour <= 18;
      case TaskCategory.personal:
        return hour >= 17 && hour <= 23;
      case TaskCategory.urgent:
        return true; // Any time is good for urgent tasks
    }
  }
  
  /// Generate priority explanation for user
  String generatePriorityExplanation(Task task) {
    final score = calculatePriorityScore(task);
    final explanations = <String>[];
    
    if (task.isOverdue) {
      explanations.add('This task is overdue');
    } else if (task.isDueToday) {
      explanations.add('This task is due today');
    } else if (task.isDueSoon) {
      explanations.add('This task is due soon');
    }
    
    if (task.priority == TaskPriority.urgent) {
      explanations.add('Marked as urgent priority');
    }
    
    if (task.dopamineScore >= 0.7) {
      explanations.add('High motivation potential');
    }
    
    if (task.estimatedMinutes <= 15) {
      explanations.add('Quick task - good for momentum');
    }
    
    final currentHour = DateTime.now().hour;
    if (_isTimeOptimalForCategory(task.category, currentHour)) {
      explanations.add('Optimal time for this type of task');
    }
    
    if (explanations.isEmpty) {
      explanations.add('Standard priority task');
    }
    
    return explanations.join(', ');
  }
}

class _ScoredTask {
  final Task task;
  final double score;
  
  _ScoredTask(this.task, this.score);
}

/// Priority quadrant categorization
enum PriorityQuadrant {
  urgentImportant,    // Do First
  importantNotUrgent, // Schedule
  urgentNotImportant, // Delegate
  notUrgentNotImportant, // Eliminate
}

class PriorityMatrix {
  static PriorityQuadrant categorizeTask(double urgency, double importance) {
    bool isUrgent = urgency >= 70.0;
    bool isImportant = importance >= 70.0;
    
    if (isUrgent && isImportant) {
      return PriorityQuadrant.urgentImportant;
    } else if (!isUrgent && isImportant) {
      return PriorityQuadrant.importantNotUrgent;
    } else if (isUrgent && !isImportant) {
      return PriorityQuadrant.urgentNotImportant;
    } else {
      return PriorityQuadrant.notUrgentNotImportant;
    }
  }
  
  static String getActionAdvice(PriorityQuadrant quadrant) {
    switch (quadrant) {
      case PriorityQuadrant.urgentImportant:
        return "Do this now! High priority task.";
      case PriorityQuadrant.importantNotUrgent:
        return "Schedule this for later. Important for your goals.";
      case PriorityQuadrant.urgentNotImportant:
        return "Can this be delegated or simplified?";
      case PriorityQuadrant.notUrgentNotImportant:
        return "Consider if this task is really necessary.";
    }
  }
  
  static String getEmoji(PriorityQuadrant quadrant) {
    switch (quadrant) {
      case PriorityQuadrant.urgentImportant:
        return "🔥";
      case PriorityQuadrant.importantNotUrgent:
        return "📅";
      case PriorityQuadrant.urgentNotImportant:
        return "⚡";
      case PriorityQuadrant.notUrgentNotImportant:
        return "🗑️";
    }
  }
}