import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/task_intent.dart';
import '../models/task.dart';

class IntentRecognitionService {
  static const String _openAIApiUrl = 'https://api.openai.com/v1/chat/completions';
  final String? _apiKey;
  
  // Local pattern matching cache
  final Map<String, TaskIntent> _intentCache = {};
  
  IntentRecognitionService({String? apiKey}) : _apiKey = apiKey;
  
  /// Recognize intent from speech transcript
  Future<TaskIntent> recognizeIntent(String transcript) async {
    if (transcript.isEmpty) {
      return TaskIntent(
        intent: IntentType.unknown,
        taskDescription: '',
        rawTranscript: transcript,
        confidence: 0.0,
      );
    }
    
    // Check cache first
    if (_intentCache.containsKey(transcript.toLowerCase())) {
      return _intentCache[transcript.toLowerCase()]!;
    }
    
    // Try local pattern matching first (fast)
    final localIntent = await _recognizeLocalIntent(transcript);
    if (localIntent.confidence >= 0.7) {
      _intentCache[transcript.toLowerCase()] = localIntent;
      return localIntent;
    }
    
    // Fall back to LLM-based recognition for complex cases
    if (_apiKey != null) {
      try {
        final llmIntent = await _recognizeLLMIntent(transcript);
        if (llmIntent.confidence >= 0.6) {
          _intentCache[transcript.toLowerCase()] = llmIntent;
          return llmIntent;
        }
      } catch (e) {
        debugPrint('LLM intent recognition failed: $e');
      }
    }
    
    // Return the best local match even if confidence is low
    return localIntent;
  }
  
  /// Local pattern matching for common intents
  Future<TaskIntent> _recognizeLocalIntent(String transcript) async {
    final lowerTranscript = transcript.toLowerCase();
    final words = lowerTranscript.split(' ');
    
    // Task creation patterns
    if (_containsAny(lowerTranscript, [
      'create task', 'add task', 'new task', 'make a task',
      'i need to', 'i have to', 'i should', 'remind me to',
      'don\'t forget to', 'remember to', 'task:', 'todo:'
    ])) {
      return _createTaskIntent(transcript, lowerTranscript);
    }
    
    // Task completion patterns
    if (_containsAny(lowerTranscript, [
      'complete', 'done', 'finished', 'mark as done',
      'completed', 'finish', 'check off'
    ])) {
      return _createCompletionIntent(transcript, lowerTranscript);
    }
    
    // Task editing patterns
    if (_containsAny(lowerTranscript, [
      'edit', 'change', 'modify', 'update', 'alter'
    ])) {
      return _createEditIntent(transcript, lowerTranscript);
    }
    
    // Task deletion patterns
    if (_containsAny(lowerTranscript, [
      'delete', 'remove', 'cancel', 'get rid of'
    ])) {
      return _createDeleteIntent(transcript, lowerTranscript);
    }
    
    // List tasks patterns
    if (_containsAny(lowerTranscript, [
      'list tasks', 'show tasks', 'what tasks', 'my tasks',
      'what do i have', 'what\'s on my list'
    ])) {
      return _createListIntent(transcript, lowerTranscript);
    }
    
    // Help patterns
    if (_containsAny(lowerTranscript, [
      'help', 'what can you do', 'how do i', 'explain'
    ])) {
      return _createHelpIntent(transcript, lowerTranscript);
    }
    
    // Default to task creation for ambiguous cases
    return _createTaskIntent(transcript, lowerTranscript);
  }
  
  /// LLM-based intent recognition for complex cases
  Future<TaskIntent> _recognizeLLMIntent(String transcript) async {
    final prompt = _buildLLMPrompt(transcript);
    
    final response = await http.post(
      Uri.parse(_openAIApiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': transcript}
        ],
        'temperature': 0.3,
        'max_tokens': 500,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      
      try {
        final intentJson = jsonDecode(content);
        return TaskIntent.fromJson(intentJson);
      } catch (e) {
        debugPrint('Failed to parse LLM response: $e');
        return _createFallbackIntent(transcript);
      }
    } else {
      throw Exception('OpenAI API request failed: ${response.statusCode}');
    }
  }
  
  String _buildLLMPrompt(String transcript) {
    return '''
You are an AI assistant specialized in understanding voice commands for task management, optimized for ADHD users. Analyze the user's speech and extract task information.

User input: "$transcript"

Extract and return ONLY valid JSON with this exact structure:
{
  "intent": "createTask|reminder|editTask|deleteTask|completeTask|listTasks|help|question|unknown",
  "taskDescription": "clean, actionable description of the task",
  "category": "work|personal|health|learning|social|creative|maintenance|urgent",
  "urgency": "low|medium|high|urgent",
  "dueDate": "extracted date/time if mentioned, null otherwise",
  "context": "additional context or details",
  "confidence": 0.0-1.0,
  "estimatedMinutes": estimated_time_in_minutes,
  "keywords": ["relevant", "keywords", "from", "speech"],
  "rawTranscript": "$transcript"
}

Guidelines for ADHD users:
- Be forgiving of unclear speech patterns
- Extract intent even from incomplete sentences
- Default to "medium" urgency if unclear
- Prefer "personal" category if ambiguous
- Set confidence based on clarity of intent
- Handle expressions like "I need to", "Don't forget", "Remember to"
- Recognize time expressions: "today", "tomorrow", "this evening", "next week"
- If no clear task, set intent to "question" or "help"

Return ONLY the JSON object, no additional text.
''';
  }
  
  // Helper methods for local pattern matching
  TaskIntent _createTaskIntent(String transcript, String lowerTranscript) {
    final category = _extractCategory(lowerTranscript);
    final urgency = _extractUrgency(lowerTranscript);
    final dueDate = _extractDueDate(lowerTranscript);
    final keywords = _extractKeywords(lowerTranscript);
    
    // Clean up task description
    String taskDescription = _cleanTaskDescription(transcript);
    
    return TaskIntent(
      intent: IntentType.createTask,
      taskDescription: taskDescription,
      rawTranscript: transcript,
      category: category,
      urgency: urgency,
      dueDate: dueDate,
      keywords: keywords,
      confidence: 0.8,
      estimatedMinutes: _estimateTaskDuration(lowerTranscript),
    );
  }
  
  TaskIntent _createCompletionIntent(String transcript, String lowerTranscript) {
    return TaskIntent(
      intent: IntentType.completeTask,
      taskDescription: _cleanTaskDescription(transcript),
      rawTranscript: transcript,
      confidence: 0.9,
      action: TaskAction.complete,
    );
  }
  
  TaskIntent _createEditIntent(String transcript, String lowerTranscript) {
    return TaskIntent(
      intent: IntentType.editTask,
      taskDescription: _cleanTaskDescription(transcript),
      rawTranscript: transcript,
      confidence: 0.85,
      action: TaskAction.edit,
    );
  }
  
  TaskIntent _createDeleteIntent(String transcript, String lowerTranscript) {
    return TaskIntent(
      intent: IntentType.deleteTask,
      taskDescription: _cleanTaskDescription(transcript),
      rawTranscript: transcript,
      confidence: 0.9,
      action: TaskAction.delete,
    );
  }
  
  TaskIntent _createListIntent(String transcript, String lowerTranscript) {
    return TaskIntent(
      intent: IntentType.listTasks,
      taskDescription: 'List all tasks',
      rawTranscript: transcript,
      confidence: 0.95,
      action: TaskAction.list,
    );
  }
  
  TaskIntent _createHelpIntent(String transcript, String lowerTranscript) {
    return TaskIntent(
      intent: IntentType.help,
      taskDescription: 'Help request',
      rawTranscript: transcript,
      confidence: 0.9,
    );
  }
  
  TaskIntent _createFallbackIntent(String transcript) {
    return TaskIntent(
      intent: IntentType.unknown,
      taskDescription: transcript,
      rawTranscript: transcript,
      confidence: 0.3,
    );
  }
  
  // Extraction helper methods
  TaskCategory _extractCategory(String lowerTranscript) {
    if (_containsAny(lowerTranscript, ['work', 'office', 'meeting', 'call', 'email', 'project'])) {
      return TaskCategory.work;
    } else if (_containsAny(lowerTranscript, ['health', 'doctor', 'medicine', 'exercise', 'workout'])) {
      return TaskCategory.health;
    } else if (_containsAny(lowerTranscript, ['learn', 'study', 'read', 'course', 'tutorial'])) {
      return TaskCategory.learning;
    } else if (_containsAny(lowerTranscript, ['social', 'friend', 'family', 'party', 'visit'])) {
      return TaskCategory.social;
    } else if (_containsAny(lowerTranscript, ['creative', 'art', 'music', 'write', 'design'])) {
      return TaskCategory.creative;
    } else if (_containsAny(lowerTranscript, ['urgent', 'asap', 'immediately', 'now', 'emergency'])) {
      return TaskCategory.urgent;
    } else if (_containsAny(lowerTranscript, ['clean', 'fix', 'repair', 'maintain', 'organize'])) {
      return TaskCategory.maintenance;
    }
    return TaskCategory.personal;
  }
  
  String _extractUrgency(String lowerTranscript) {
    if (_containsAny(lowerTranscript, ['urgent', 'asap', 'immediately', 'now', 'emergency'])) {
      return 'urgent';
    } else if (_containsAny(lowerTranscript, ['important', 'priority', 'high', 'critical'])) {
      return 'high';
    } else if (_containsAny(lowerTranscript, ['low', 'whenever', 'sometime', 'eventually'])) {
      return 'low';
    }
    return 'medium';
  }
  
  String? _extractDueDate(String lowerTranscript) {
    if (_containsAny(lowerTranscript, ['today', 'this morning', 'this afternoon', 'this evening', 'tonight'])) {
      return 'today';
    } else if (_containsAny(lowerTranscript, ['tomorrow', 'next morning', 'next afternoon', 'next evening'])) {
      return 'tomorrow';
    } else if (_containsAny(lowerTranscript, ['next week', 'next monday', 'next tuesday', 'next wednesday', 'next thursday', 'next friday'])) {
      return 'next week';
    } else if (_containsAny(lowerTranscript, ['this week', 'this monday', 'this tuesday', 'this wednesday', 'this thursday', 'this friday'])) {
      return 'this week';
    }
    return null;
  }
  
  List<String> _extractKeywords(String lowerTranscript) {
    final stopWords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'can', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'her', 'its', 'our', 'their', 'this', 'that', 'these', 'those'};
    
    return lowerTranscript
        .split(' ')
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();
  }
  
  String _cleanTaskDescription(String transcript) {
    // Remove common prefixes
    String cleaned = transcript.replaceAll(RegExp(r'^(create task|add task|new task|remind me to|don\'t forget to|remember to|i need to|i have to|i should|task:|todo:)\s*', caseSensitive: false), '');
    
    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned.trim();
  }
  
  int _estimateTaskDuration(String lowerTranscript) {
    if (_containsAny(lowerTranscript, ['quick', 'fast', 'briefly', 'call', 'email', 'text'])) {
      return 5;
    } else if (_containsAny(lowerTranscript, ['meeting', 'appointment', 'class', 'session'])) {
      return 60;
    } else if (_containsAny(lowerTranscript, ['project', 'research', 'study', 'read', 'write'])) {
      return 120;
    }
    return 30; // Default 30 minutes
  }
  
  bool _containsAny(String text, List<String> patterns) {
    return patterns.any((pattern) => text.contains(pattern));
  }
  
  /// Clear the intent cache
  void clearCache() {
    _intentCache.clear();
  }
  
  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'cached_intents': _intentCache.length,
      'cache_hits': _intentCache.values.where((intent) => intent.confidence >= 0.7).length,
    };
  }
}