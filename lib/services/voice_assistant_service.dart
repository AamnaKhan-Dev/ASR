import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

import '../models/task.dart';
import '../models/task_intent.dart';
import 'speech_to_text_service.dart';
import 'intent_recognition_service.dart';
import 'adhd_task_prioritizer.dart';
import 'task_storage_service.dart';

class VoiceAssistantService extends ChangeNotifier {
  // Core services
  late final SpeechToTextService _speechService;
  late final IntentRecognitionService _intentService;
  late final ADHDTaskPrioritizer _prioritizer;
  late final TaskStorageService _storageService;
  late final FlutterTts _tts;
  
  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isWakeWordEnabled = false;
  
  // Current session
  String _currentTranscript = '';
  TaskIntent? _currentIntent;
  double _confidence = 0.0;
  String _lastResponse = '';
  
  // ADHD-specific features
  int _currentEnergyLevel = 3; // 1-5 scale
  List<String> _motivationalPhrases = [];
  int _tasksCompletedToday = 0;
  int _consecutiveDays = 0;
  
  // Configuration
  String? _openAIApiKey;
  bool _useVoiceFeedback = true;
  bool _useMotivationalMessages = true;
  Duration _sessionTimeout = const Duration(minutes: 5);
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isWakeWordEnabled => _isWakeWordEnabled;
  String get currentTranscript => _currentTranscript;
  TaskIntent? get currentIntent => _currentIntent;
  double get confidence => _confidence;
  String get lastResponse => _lastResponse;
  int get currentEnergyLevel => _currentEnergyLevel;
  int get tasksCompletedToday => _tasksCompletedToday;
  
  // Callbacks
  Function(Task)? onTaskCreated;
  Function(Task)? onTaskCompleted;
  Function(String)? onError;
  Function(String)? onFeedback;
  
  /// Initialize the voice assistant service
  Future<bool> initialize({String? openAIApiKey}) async {
    if (_isInitialized) return true;
    
    try {
      _openAIApiKey = openAIApiKey;
      
      // Initialize services
      _speechService = SpeechToTextService();
      _intentService = IntentRecognitionService(apiKey: _openAIApiKey);
      _prioritizer = ADHDTaskPrioritizer();
      _storageService = TaskStorageService();
      _tts = FlutterTts();
      
      // Initialize speech recognition
      final speechInitialized = await _speechService.initialize();
      if (!speechInitialized) {
        debugPrint('Speech recognition failed to initialize');
        return false;
      }
      
      // Initialize storage
      await _storageService.initialize();
      
      // Initialize TTS
      await _initializeTTS();
      
      // Load user preferences
      await _loadUserPreferences();
      
      // Load motivational phrases
      _loadMotivationalPhrases();
      
      // Set up speech service callbacks
      _setupSpeechCallbacks();
      
      _isInitialized = true;
      notifyListeners();
      
      // Welcome message
      if (_useVoiceFeedback) {
        await _speak(_getWelcomeMessage());
      }
      
      return true;
    } catch (e) {
      debugPrint('Voice assistant initialization failed: $e');
      return false;
    }
  }
  
  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;
    
    try {
      _currentTranscript = '';
      _currentIntent = null;
      _confidence = 0.0;
      
      await _speechService.quickListen(
        onComplete: _handleSpeechComplete,
        onPartial: _handleSpeechPartial,
      );
      
      _isListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start listening: $e');
      onError?.call('Failed to start listening: $e');
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speechService.stopListening();
    _isListening = false;
    notifyListeners();
  }
  
  /// Process voice command manually
  Future<void> processCommand(String command) async {
    if (!_isInitialized) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Recognize intent
      final intent = await _intentService.recognizeIntent(command);
      _currentIntent = intent;
      _confidence = intent.confidence;
      
      // Process the intent
      await _processIntent(intent);
      
    } catch (e) {
      debugPrint('Failed to process command: $e');
      onError?.call('Failed to process command: $e');
      await _speak('Sorry, I had trouble processing that command.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// Set current energy level (1-5)
  void setEnergyLevel(int level) {
    _currentEnergyLevel = level.clamp(1, 5);
    notifyListeners();
    _saveUserPreferences();
  }
  
  /// Get optimal tasks for current time and energy
  Future<List<Task>> getOptimalTasks() async {
    final allTasks = await _storageService.getAllTasks();
    return _prioritizer.getOptimalTasksForNow(allTasks, _currentEnergyLevel);
  }
  
  /// Get quick tasks for breaks
  Future<List<Task>> getQuickTasks() async {
    final allTasks = await _storageService.getAllTasks();
    return _prioritizer.getQuickTasks(allTasks);
  }
  
  /// Toggle wake word detection
  void toggleWakeWord(bool enabled) {
    _isWakeWordEnabled = enabled;
    notifyListeners();
    _saveUserPreferences();
  }
  
  /// Toggle voice feedback
  void toggleVoiceFeedback(bool enabled) {
    _useVoiceFeedback = enabled;
    notifyListeners();
    _saveUserPreferences();
  }
  
  /// Toggle motivational messages
  void toggleMotivationalMessages(bool enabled) {
    _useMotivationalMessages = enabled;
    notifyListeners();
    _saveUserPreferences();
  }
  
  // Private methods
  Future<void> _initializeTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.8); // Slightly slower for ADHD users
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.0);
    
    // Set completion handler
    _tts.setCompletionHandler(() {
      debugPrint('TTS completed');
    });
    
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
    });
  }
  
  void _setupSpeechCallbacks() {
    _speechService.onResult = _handleSpeechComplete;
    _speechService.onPartialResult = _handleSpeechPartial;
    _speechService.onError = (error) {
      debugPrint('Speech error: $error');
      onError?.call(error);
    };
    
    _speechService.onListeningStarted = () {
      _isListening = true;
      notifyListeners();
    };
    
    _speechService.onListeningStopped = () {
      _isListening = false;
      notifyListeners();
    };
  }
  
  Future<void> _handleSpeechComplete(String transcript) async {
    _currentTranscript = transcript;
    
    if (transcript.isEmpty) {
      await _speak('I didn\'t catch that. Could you try again?');
      return;
    }
    
    await processCommand(transcript);
  }
  
  void _handleSpeechPartial(String transcript) {
    _currentTranscript = transcript;
    notifyListeners();
  }
  
  Future<void> _processIntent(TaskIntent intent) async {
    _lastResponse = '';
    
    switch (intent.intent) {
      case IntentType.createTask:
        await _handleCreateTask(intent);
        break;
      case IntentType.completeTask:
        await _handleCompleteTask(intent);
        break;
      case IntentType.editTask:
        await _handleEditTask(intent);
        break;
      case IntentType.deleteTask:
        await _handleDeleteTask(intent);
        break;
      case IntentType.listTasks:
        await _handleListTasks(intent);
        break;
      case IntentType.help:
        await _handleHelp(intent);
        break;
      case IntentType.reminder:
        await _handleReminder(intent);
        break;
      default:
        await _handleUnknownIntent(intent);
    }
  }
  
  Future<void> _handleCreateTask(TaskIntent intent) async {
    try {
      // Calculate priority score
      final priorityScore = _prioritizer.calculatePriorityScoreFromIntent(intent);
      
      // Create task
      final task = Task(
        title: intent.taskDescription,
        description: intent.context ?? intent.taskDescription,
        category: intent.category,
        priority: intent.priorityLevel,
        dueDate: intent.parsedDueDate,
        estimatedMinutes: intent.estimatedMinutes ?? 30,
        energyLevel: _estimateEnergyLevel(intent),
        dopamineScore: _estimateDopamineScore(intent),
        tags: intent.keywords,
        urgencyScore: _prioritizer.calculatePriorityScoreFromIntent(intent),
        importanceScore: _prioritizer.calculatePriorityScoreFromIntent(intent),
        priorityScore: priorityScore,
      );
      
      // Save task
      await _storageService.saveTask(task);
      
      // Notify callback
      onTaskCreated?.call(task);
      
      // Generate response
      final response = _generateTaskCreationResponse(task);
      _lastResponse = response;
      
      if (_useVoiceFeedback) {
        await _speak(response);
      }
      
    } catch (e) {
      debugPrint('Failed to create task: $e');
      await _speak('Sorry, I couldn\'t create that task. Please try again.');
    }
  }
  
  Future<void> _handleCompleteTask(TaskIntent intent) async {
    try {
      // Find task to complete
      final allTasks = await _storageService.getAllTasks();
      final matchingTasks = allTasks.where((task) => 
        task.title.toLowerCase().contains(intent.taskDescription.toLowerCase()) &&
        task.status == TaskStatus.pending
      ).toList();
      
      if (matchingTasks.isEmpty) {
        await _speak('I couldn\'t find a task matching "${intent.taskDescription}".');
        return;
      }
      
      // Complete the first matching task
      final task = matchingTasks.first;
      final completedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      
      await _storageService.saveTask(completedTask);
      
      // Update stats
      _tasksCompletedToday++;
      _saveUserPreferences();
      
      // Notify callback
      onTaskCompleted?.call(completedTask);
      
      // Generate celebratory response
      final response = _generateTaskCompletionResponse(completedTask);
      _lastResponse = response;
      
      if (_useVoiceFeedback) {
        await _speak(response);
      }
      
    } catch (e) {
      debugPrint('Failed to complete task: $e');
      await _speak('Sorry, I couldn\'t complete that task.');
    }
  }
  
  Future<void> _handleEditTask(TaskIntent intent) async {
    await _speak('Task editing isn\'t implemented yet, but I\'ve noted your request.');
  }
  
  Future<void> _handleDeleteTask(TaskIntent intent) async {
    await _speak('Task deletion isn\'t implemented yet, but I\'ve noted your request.');
  }
  
  Future<void> _handleListTasks(TaskIntent intent) async {
    try {
      final allTasks = await _storageService.getAllTasks();
      final pendingTasks = allTasks
          .where((task) => task.status == TaskStatus.pending)
          .toList();
      
      if (pendingTasks.isEmpty) {
        await _speak('Great job! You have no pending tasks.');
        return;
      }
      
      // Prioritize tasks
      final prioritizedTasks = _prioritizer.prioritizeTasks(pendingTasks);
      final topTasks = prioritizedTasks.take(5).toList();
      
      String response = 'Here are your top ${topTasks.length} tasks: ';
      for (int i = 0; i < topTasks.length; i++) {
        final task = topTasks[i];
        response += '${i + 1}. ${task.title}';
        if (task.dueDate != null) {
          response += ' (due ${_formatDueDate(task.dueDate!)})';
        }
        response += '. ';
      }
      
      _lastResponse = response;
      
      if (_useVoiceFeedback) {
        await _speak(response);
      }
      
    } catch (e) {
      debugPrint('Failed to list tasks: $e');
      await _speak('Sorry, I couldn\'t retrieve your tasks.');
    }
  }
  
  Future<void> _handleHelp(TaskIntent intent) async {
    const helpMessage = 'I can help you manage tasks with voice commands. '
        'Say things like "Create a task to call mom", "Complete grocery shopping", '
        '"List my tasks", or "What should I work on now?". '
        'I understand natural speech and I\'m optimized for ADHD brain patterns.';
    
    _lastResponse = helpMessage;
    
    if (_useVoiceFeedback) {
      await _speak(helpMessage);
    }
  }
  
  Future<void> _handleReminder(TaskIntent intent) async {
    await _handleCreateTask(intent.copyWith(intent: IntentType.createTask));
  }
  
  Future<void> _handleUnknownIntent(TaskIntent intent) async {
    final responses = [
      'I didn\'t quite understand that. Could you try rephrasing?',
      'I\'m not sure what you meant. Try saying it differently.',
      'Could you clarify what you\'d like me to do?',
    ];
    
    final response = responses[Random().nextInt(responses.length)];
    _lastResponse = response;
    
    if (_useVoiceFeedback) {
      await _speak(response);
    }
  }
  
  String _generateTaskCreationResponse(Task task) {
    final motivationalStart = _useMotivationalMessages ? 
        _getRandomMotivationalPhrase() + ' ' : '';
    
    String response = '${motivationalStart}I\'ve created the task "${task.title}"';
    
    if (task.dueDate != null) {
      response += ' due ${_formatDueDate(task.dueDate!)}';
    }
    
    response += '. ';
    
    // Add priority context
    final explanation = _prioritizer.generatePriorityExplanation(task);
    if (explanation.isNotEmpty) {
      response += explanation + '. ';
    }
    
    // Add encouragement
    if (_useMotivationalMessages) {
      response += 'You\'ve got this!';
    }
    
    return response;
  }
  
  String _generateTaskCompletionResponse(Task task) {
    final celebrations = [
      'Awesome! Great job completing "${task.title}"!',
      'Fantastic work! You finished "${task.title}"!',
      'Well done! "${task.title}" is complete!',
      'Amazing! You knocked out "${task.title}"!',
      'Excellent! "${task.title}" is done!',
    ];
    
    String response = celebrations[Random().nextInt(celebrations.length)];
    
    // Add milestone celebration
    if (_tasksCompletedToday % 5 == 0) {
      response += ' That\'s $_tasksCompletedToday tasks completed today! You\'re on fire!';
    }
    
    return response;
  }
  
  String _getWelcomeMessage() {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    
    if (timeOfDay < 12) {
      greeting = 'Good morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    
    return '$greeting! I\'m your ADHD-friendly voice assistant. '
           'I\'m here to help you manage your tasks. What would you like to work on?';
  }
  
  String _getRandomMotivationalPhrase() {
    if (_motivationalPhrases.isEmpty) return '';
    return _motivationalPhrases[Random().nextInt(_motivationalPhrases.length)];
  }
  
  void _loadMotivationalPhrases() {
    _motivationalPhrases = [
      'Great idea!',
      'You\'re being so productive!',
      'I love your motivation!',
      'Perfect!',
      'You\'re crushing it!',
      'Fantastic!',
      'Keep up the great work!',
      'You\'re doing amazing!',
      'Way to go!',
      'Brilliant!',
    ];
  }
  
  int _estimateEnergyLevel(TaskIntent intent) {
    final keywords = intent.keywords;
    
    if (keywords.any((k) => ['difficult', 'complex', 'challenging'].contains(k))) {
      return 5;
    } else if (keywords.any((k) => ['easy', 'simple', 'quick'].contains(k))) {
      return 2;
    }
    
    return 3;
  }
  
  double _estimateDopamineScore(TaskIntent intent) {
    final keywords = intent.keywords;
    
    if (keywords.any((k) => ['creative', 'fun', 'interesting'].contains(k))) {
      return 0.8;
    } else if (keywords.any((k) => ['boring', 'tedious', 'routine'].contains(k))) {
      return 0.3;
    }
    
    return 0.5;
  }
  
  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (taskDate == today) {
      return 'today';
    } else if (taskDate == tomorrow) {
      return 'tomorrow';
    } else {
      return '${dueDate.month}/${dueDate.day}';
    }
  }
  
  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
      onFeedback?.call(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }
  
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentEnergyLevel = prefs.getInt('energy_level') ?? 3;
    _useVoiceFeedback = prefs.getBool('voice_feedback') ?? true;
    _useMotivationalMessages = prefs.getBool('motivational_messages') ?? true;
    _isWakeWordEnabled = prefs.getBool('wake_word_enabled') ?? false;
    _tasksCompletedToday = prefs.getInt('tasks_completed_today') ?? 0;
    _consecutiveDays = prefs.getInt('consecutive_days') ?? 0;
  }
  
  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('energy_level', _currentEnergyLevel);
    await prefs.setBool('voice_feedback', _useVoiceFeedback);
    await prefs.setBool('motivational_messages', _useMotivationalMessages);
    await prefs.setBool('wake_word_enabled', _isWakeWordEnabled);
    await prefs.setInt('tasks_completed_today', _tasksCompletedToday);
    await prefs.setInt('consecutive_days', _consecutiveDays);
  }
  
  @override
  void dispose() {
    _speechService.dispose();
    _tts.stop();
    super.dispose();
  }
}