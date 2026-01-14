import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_app/services/ai_assistant_service.dart';
import 'package:dms_app/models/glucose_reading.dart';

/// AI Assistant Provider
/// 
/// Manages AI assistant state and interactions
class AiAssistantProvider extends ChangeNotifier {
  final AiAssistantService _service = AiAssistantService();
  
  static const String _apiKeyKey = 'ai_assistant_api_key';
  static const String _enabledKey = 'ai_assistant_enabled';
  
  final List<AiAssistantResponse> _chatHistory = [];
  bool _isLoading = false;
  bool _isEnabled = false;
  bool _isConfigured = false;
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
      final apiKey = prefs.getString(_apiKeyKey);
      _isEnabled = prefs.getBool(_enabledKey) ?? false;
      
      if (apiKey != null && apiKey.isNotEmpty) {
        _service.initialize(apiKey);
        _isConfigured = true;
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load AI settings: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Configure the AI assistant with an API key
  Future<bool> configure(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      
      _service.initialize(apiKey);
      _isConfigured = true;
      _error = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to configure AI assistant: ${e.toString()}';
      notifyListeners();
      return false;
    }
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
  
  /// Remove API key and disable assistant
  Future<void> disconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
      await prefs.setBool(_enabledKey, false);
      
      _isConfigured = false;
      _isEnabled = false;
      _chatHistory.clear();
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to disconnect: ${e.toString()}';
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
