import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isListening = false;
  bool _isAvailable = false;
  bool _isInitialized = false;
  String _lastWords = '';
  String _currentTranscript = '';
  double _confidence = 0.0;
  double _soundLevel = 0.0;
  String _localeId = 'en_US';
  
  // ADHD-specific settings
  Duration _listenTimeout = const Duration(seconds: 30);
  Duration _pauseTimeout = const Duration(seconds: 3);
  bool _partialResults = true;
  
  // Getters
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;
  String get currentTranscript => _currentTranscript;
  double get confidence => _confidence;
  double get soundLevel => _soundLevel;
  String get localeId => _localeId;
  
  // Callbacks
  Function(String)? onResult;
  Function(String)? onPartialResult;
  Function(String)? onError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;
  
  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }
      
      // Initialize speech recognition
      _isAvailable = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );
      
      _isInitialized = _isAvailable;
      
      if (_isAvailable) {
        // Get available locales
        final locales = await _speechToText.locales();
        debugPrint('Available locales: ${locales.map((l) => l.localeId).join(', ')}');
        
        // Set optimal locale for ADHD users (clear speech recognition)
        final preferredLocales = ['en_US', 'en_GB', 'en_AU'];
        for (final locale in preferredLocales) {
          if (locales.any((l) => l.localeId == locale)) {
            _localeId = locale;
            break;
          }
        }
      }
      
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      debugPrint('Speech recognition initialization failed: $e');
      return false;
    }
  }
  
  /// Start listening for speech with ADHD-optimized settings
  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    bool? partialResults,
    String? localeId,
  }) async {
    if (!_isAvailable || _isListening) return;
    
    _currentTranscript = '';
    _lastWords = '';
    _confidence = 0.0;
    
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: listenFor ?? _listenTimeout,
        pauseFor: pauseFor ?? _pauseTimeout,
        partialResults: partialResults ?? _partialResults,
        localeId: localeId ?? _localeId,
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
      
      _isListening = true;
      onListeningStarted?.call();
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      onError?.call('Failed to start listening: $e');
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speechToText.stop();
    _isListening = false;
    onListeningStopped?.call();
    notifyListeners();
  }
  
  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;
    
    await _speechToText.cancel();
    _isListening = false;
    _currentTranscript = '';
    _lastWords = '';
    onListeningStopped?.call();
    notifyListeners();
  }
  
  /// Set listening timeout (optimized for ADHD attention spans)
  void setListenTimeout(Duration timeout) {
    _listenTimeout = timeout;
  }
  
  /// Set pause timeout (how long to wait for more speech)
  void setPauseTimeout(Duration timeout) {
    _pauseTimeout = timeout;
  }
  
  /// Enable/disable partial results for real-time feedback
  void setPartialResults(bool enabled) {
    _partialResults = enabled;
  }
  
  /// Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isAvailable) return [];
    return await _speechToText.locales();
  }
  
  /// Set locale for speech recognition
  void setLocale(String localeId) {
    _localeId = localeId;
  }
  
  /// Check if speech recognition is available
  Future<bool> checkAvailability() async {
    return await _speechToText.initialize();
  }
  
  // Private methods
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;
    
    if (result.finalResult) {
      _currentTranscript = result.recognizedWords;
      onResult?.call(_currentTranscript);
    } else {
      _currentTranscript = result.recognizedWords;
      onPartialResult?.call(_currentTranscript);
    }
    
    notifyListeners();
  }
  
  void _onSoundLevelChange(double level) {
    _soundLevel = level;
    notifyListeners();
  }
  
  void _onError(dynamic error) {
    debugPrint('Speech recognition error: $error');
    _isListening = false;
    onError?.call('Speech recognition error: $error');
    notifyListeners();
  }
  
  void _onStatus(String status) {
    debugPrint('Speech recognition status: $status');
    
    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
        _isListening = false;
        break;
      case 'done':
        _isListening = false;
        break;
    }
    
    notifyListeners();
  }
  
  /// Clean up resources
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

/// Extension for better ADHD-specific functionality
extension ADHDOptimizations on SpeechToTextService {
  /// Quick start listening with ADHD-optimized settings
  Future<void> quickListen({
    Function(String)? onComplete,
    Function(String)? onPartial,
  }) async {
    onResult = onComplete;
    onPartialResult = onPartial;
    
    await startListening(
      listenFor: const Duration(seconds: 15), // Shorter for ADHD attention
      pauseFor: const Duration(seconds: 2),   // Quick pause detection
      partialResults: true,                   // Real-time feedback
    );
  }
  
  /// Extended listening for complex tasks
  Future<void> extendedListen({
    Function(String)? onComplete,
    Function(String)? onPartial,
  }) async {
    onResult = onComplete;
    onPartialResult = onPartial;
    
    await startListening(
      listenFor: const Duration(seconds: 45), // Longer for complex tasks
      pauseFor: const Duration(seconds: 4),   // More patient pause
      partialResults: true,
    );
  }
  
  /// Check if current sound level indicates speech
  bool get isSpeaking {
    return _soundLevel > 0.1; // Threshold for detecting speech
  }
  
  /// Get formatted confidence percentage
  String get confidencePercentage {
    return '${(_confidence * 100).toStringAsFixed(1)}%';
  }
}