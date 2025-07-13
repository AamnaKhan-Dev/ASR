import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';

import '../models/task.dart';

class TaskStorageService {
  static const String _tableName = 'tasks';
  static const String _databaseName = 'adhd_tasks.db';
  static const int _databaseVersion = 1;
  
  Database? _database;
  bool _isInitialized = false;
  
  /// Initialize the database
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, _databaseName);
      
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
      
      _isInitialized = true;
      debugPrint('Task storage initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize task storage: $e');
      rethrow;
    }
  }
  
  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        due_date INTEGER,
        completed_at INTEGER,
        estimated_minutes INTEGER NOT NULL,
        energy_level INTEGER NOT NULL,
        dopamine_score REAL NOT NULL,
        tags TEXT NOT NULL,
        notes TEXT,
        is_recurring INTEGER NOT NULL,
        recurrence_type TEXT,
        urgency_score REAL NOT NULL,
        importance_score REAL NOT NULL,
        priority_score REAL NOT NULL
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_status ON $_tableName(status)');
    await db.execute('CREATE INDEX idx_due_date ON $_tableName(due_date)');
    await db.execute('CREATE INDEX idx_priority_score ON $_tableName(priority_score)');
    await db.execute('CREATE INDEX idx_category ON $_tableName(category)');
    await db.execute('CREATE INDEX idx_created_at ON $_tableName(created_at)');
    
    debugPrint('Database tables created successfully');
  }
  
  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
  }
  
  /// Save a task (insert or update)
  Future<void> saveTask(Task task) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      await _database!.insert(
        _tableName,
        _taskToMap(task),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('Task saved: ${task.title}');
    } catch (e) {
      debugPrint('Failed to save task: $e');
      rethrow;
    }
  }
  
  /// Get all tasks
  Future<List<Task>> getAllTasks() async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        orderBy: 'priority_score DESC, created_at DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get all tasks: $e');
      return [];
    }
  }
  
  /// Get task by ID
  Future<Task?> getTaskById(String id) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return _mapToTask(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get task by ID: $e');
      return null;
    }
  }
  
  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'status = ?',
        whereArgs: [status.toString().split('.').last],
        orderBy: 'priority_score DESC, created_at DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by status: $e');
      return [];
    }
  }
  
  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(TaskCategory category) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'category = ?',
        whereArgs: [category.toString().split('.').last],
        orderBy: 'priority_score DESC, created_at DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by category: $e');
      return [];
    }
  }
  
  /// Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'due_date >= ? AND due_date < ? AND status = ?',
        whereArgs: [
          todayStart.millisecondsSinceEpoch,
          todayEnd.millisecondsSinceEpoch,
          TaskStatus.pending.toString().split('.').last,
        ],
        orderBy: 'priority_score DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get tasks due today: $e');
      return [];
    }
  }
  
  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final now = DateTime.now();
      
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'due_date < ? AND status = ?',
        whereArgs: [
          now.millisecondsSinceEpoch,
          TaskStatus.pending.toString().split('.').last,
        ],
        orderBy: 'due_date ASC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get overdue tasks: $e');
      return [];
    }
  }
  
  /// Get tasks by priority
  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'priority = ? AND status = ?',
        whereArgs: [
          priority.toString().split('.').last,
          TaskStatus.pending.toString().split('.').last,
        ],
        orderBy: 'priority_score DESC, created_at DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by priority: $e');
      return [];
    }
  }
  
  /// Get tasks by energy level
  Future<List<Task>> getTasksByEnergyLevel(int energyLevel) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'energy_level <= ? AND status = ?',
        whereArgs: [
          energyLevel,
          TaskStatus.pending.toString().split('.').last,
        ],
        orderBy: 'priority_score DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get tasks by energy level: $e');
      return [];
    }
  }
  
  /// Get quick tasks (low time estimate)
  Future<List<Task>> getQuickTasks({int maxMinutes = 15}) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'estimated_minutes <= ? AND status = ?',
        whereArgs: [
          maxMinutes,
          TaskStatus.pending.toString().split('.').last,
        ],
        orderBy: 'priority_score DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to get quick tasks: $e');
      return [];
    }
  }
  
  /// Search tasks by title or description
  Future<List<Task>> searchTasks(String query) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'title LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'priority_score DESC, created_at DESC',
      );
      
      return maps.map((map) => _mapToTask(map)).toList();
    } catch (e) {
      debugPrint('Failed to search tasks: $e');
      return [];
    }
  }
  
  /// Delete a task
  Future<void> deleteTask(String id) async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      await _database!.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      debugPrint('Task deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete task: $e');
      rethrow;
    }
  }
  
  /// Delete all completed tasks
  Future<void> deleteCompletedTasks() async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final count = await _database!.delete(
        _tableName,
        where: 'status = ?',
        whereArgs: [TaskStatus.completed.toString().split('.').last],
      );
      
      debugPrint('Deleted $count completed tasks');
    } catch (e) {
      debugPrint('Failed to delete completed tasks: $e');
      rethrow;
    }
  }
  
  /// Get task statistics
  Future<Map<String, int>> getTaskStatistics() async {
    if (!_isInitialized) throw Exception('Storage not initialized');
    
    try {
      final stats = <String, int>{};
      
      // Count by status
      for (final status in TaskStatus.values) {
        final count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE status = ?',
          [status.toString().split('.').last],
        )) ?? 0;
        stats['${status.toString().split('.').last}_count'] = count;
      }
      
      // Count by category
      for (final category in TaskCategory.values) {
        final count = Sqflite.firstIntValue(await _database!.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE category = ?',
          [category.toString().split('.').last],
        )) ?? 0;
        stats['${category.toString().split('.').last}_count'] = count;
      }
      
      // Count overdue
      final now = DateTime.now();
      final overdueCount = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $_tableName WHERE due_date < ? AND status = ?',
        [now.millisecondsSinceEpoch, TaskStatus.pending.toString().split('.').last],
      )) ?? 0;
      stats['overdue_count'] = overdueCount;
      
      // Count due today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final dueTodayCount = Sqflite.firstIntValue(await _database!.rawQuery(
        'SELECT COUNT(*) FROM $_tableName WHERE due_date >= ? AND due_date < ? AND status = ?',
        [todayStart.millisecondsSinceEpoch, todayEnd.millisecondsSinceEpoch, TaskStatus.pending.toString().split('.').last],
      )) ?? 0;
      stats['due_today_count'] = dueTodayCount;
      
      return stats;
    } catch (e) {
      debugPrint('Failed to get task statistics: $e');
      return {};
    }
  }
  
  /// Convert Task to Map for database storage
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'category': task.category.toString().split('.').last,
      'priority': task.priority.toString().split('.').last,
      'status': task.status.toString().split('.').last,
      'created_at': task.createdAt.millisecondsSinceEpoch,
      'due_date': task.dueDate?.millisecondsSinceEpoch,
      'completed_at': task.completedAt?.millisecondsSinceEpoch,
      'estimated_minutes': task.estimatedMinutes,
      'energy_level': task.energyLevel,
      'dopamine_score': task.dopamineScore,
      'tags': jsonEncode(task.tags),
      'notes': task.notes,
      'is_recurring': task.isRecurring ? 1 : 0,
      'recurrence_type': task.recurrenceType?.toString().split('.').last,
      'urgency_score': task.urgencyScore,
      'importance_score': task.importanceScore,
      'priority_score': task.priorityScore,
    };
  }
  
  /// Convert Map to Task from database
  Task _mapToTask(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: TaskCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => TaskCategory.personal,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      dueDate: map['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
          : null,
      estimatedMinutes: map['estimated_minutes'],
      energyLevel: map['energy_level'],
      dopamineScore: map['dopamine_score'],
      tags: List<String>.from(jsonDecode(map['tags'])),
      notes: map['notes'],
      isRecurring: map['is_recurring'] == 1,
      recurrenceType: map['recurrence_type'] != null
          ? RecurrenceType.values.firstWhere(
              (e) => e.toString().split('.').last == map['recurrence_type'],
              orElse: () => RecurrenceType.daily,
            )
          : null,
      urgencyScore: map['urgency_score'],
      importanceScore: map['importance_score'],
      priorityScore: map['priority_score'],
    );
  }
  
  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }
}