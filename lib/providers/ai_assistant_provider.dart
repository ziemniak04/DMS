import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_app/services/ai_assistant_service.dart';
import 'package:dms_app/models/glucose_reading.dart';

/// AI Assistant Provider
/// 
/// Manages AI assistant state and interactions
class AiAssistantProvider extends ChangeNotifier {
  final AiAssistantService _service = AiAssistantService();
  
  static const String _enabledKey = 'ai_assistant_enabled';
  
  final List<AiAssistantResponse> _chatHistory = [];
  bool _isLoading = false;
  bool _isEnabled = true; // Enabled by default since no API key needed
  bool _isConfigured = true; // Always configured with built-in API
  String? _error;
  
  List<AiAssistantResponse> get chatHistory => List.unmodifiable(_chatHistory);
  bool get isLoading => _isLoading;
  bool get isEnabled => _isEnabled;
  bool get isConfigured => _isConfigured;
  String? get error => _error;
  
  AiAssistantProvider() {
    _loadSettings();
  }
  
  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_enabledKey) ?? true;
      _isConfigured = true; // Always configured
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load AI settings: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Check if the AI service is available
  Future<bool> checkHealth() async {
    return await _service.checkHealth();
  }
  
  /// Enable or disable the AI assistant
  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
      _isEnabled = enabled;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update settings: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Analyze current glucose readings
  Future<AiAssistantResponse?> analyzeGlucose({
    required GlucoseReading currentReading,
    required List<GlucoseReading> recentReadings,
    String? userContext,
  }) async {
    if (!_isConfigured || !_isEnabled) {
      return null;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _service.analyzeGlucose(
        currentReading: currentReading,
        recentReadings: recentReadings,
        userContext: userContext,
      );
      
      _chatHistory.add(response);
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _error = 'Analysis failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Get a quick status update
  Future<AiAssistantResponse?> getQuickStatus(GlucoseReading currentReading) async {
    if (!_isConfigured || !_isEnabled) {
      return null;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _service.getQuickStatus(currentReading);
      
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _error = 'Failed to get status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Ask the AI assistant a question
  Future<AiAssistantResponse?> askQuestion(
    String question, {
    GlucoseReading? currentReading,
    List<GlucoseReading>? recentReadings,
  }) async {
    if (!_isConfigured) {
      _error = 'AI assistant is not configured. Please add your API key in settings.';
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Add user question to history
      _chatHistory.add(AiAssistantResponse(
        message: question,
        type: AiResponseType.info,
        disclaimer: '',
      ));
      
      final response = await _service.askQuestion(
        question,
        currentReading: currentReading,
        recentReadings: recentReadings,
      );
      
      _chatHistory.add(response);
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _error = 'Failed to get response: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Clear chat history
  void clearHistory() {
    _chatHistory.clear();
    notifyListeners();
  }
}
