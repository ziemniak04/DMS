import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/core/config.dart';

/// AI Assistant Service
///
/// Uses custom LLM backend to analyze glucose readings and provide
/// personalized tips and warnings to the user.
///
/// IMPORTANT: All AI-generated advice includes a disclaimer that
/// users should consult their healthcare provider for medical decisions.
class AiAssistantService {
  static final String _baseUrl = AppConfig.aiAssistantBaseUrl;
  static final String _healthUrl = AppConfig.aiAssistantHealthUrl;
  static final String _apiKey = AppConfig.aiAssistantApiKey;
  
  /// Check if the service is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(_healthUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Service is always configured (uses built-in API key)
  bool get isConfigured => true;
  
  /// Analyze glucose readings and provide personalized advice
  /// 
  /// [currentReading] - The most recent glucose reading
  /// [recentReadings] - List of readings from the last few hours
  /// [userContext] - Optional context about meals, activity, etc.
  Future<AiAssistantResponse> analyzeGlucose({
    required GlucoseReading currentReading,
    required List<GlucoseReading> recentReadings,
    String? userContext,
  }) async {
    if (!isConfigured) {
      return AiAssistantResponse(
        message: 'AI Assistant is not configured. Please add your API key in settings.',
        type: AiResponseType.error,
        disclaimer: '',
      );
    }
    
    try {
      final prompt = _buildAnalysisPrompt(
        currentReading: currentReading,
        recentReadings: recentReadings,
        userContext: userContext,
      );
      
      final response = await _sendMessage(prompt);
      return response;
    } catch (e) {
      return AiAssistantResponse(
        message: 'Unable to analyze glucose data: ${e.toString()}',
        type: AiResponseType.error,
        disclaimer: '',
      );
    }
  }
  
  /// Get a quick status summary based on current reading
  Future<AiAssistantResponse> getQuickStatus(GlucoseReading currentReading) async {
    if (!isConfigured) {
      return AiAssistantResponse(
        message: 'AI Assistant is not configured.',
        type: AiResponseType.error,
        disclaimer: '',
      );
    }
    
    try {
      final prompt = '''
You are a helpful diabetes management assistant. Provide a brief, friendly status update based on this glucose reading:

Current glucose: ${currentReading.value} mg/dL
Trend: ${currentReading.trend ?? 'stable'}
Time: ${currentReading.timestamp.toIso8601String()}

Respond in 1-2 sentences with:
1. A brief assessment (good, needs attention, etc.)
2. One practical tip if relevant

Keep it concise and supportive. Do not provide medical diagnosis.
''';
      
      return await _sendMessage(prompt);
    } catch (e) {
      return AiAssistantResponse(
        message: 'Unable to get status: ${e.toString()}',
        type: AiResponseType.error,
        disclaimer: '',
      );
    }
  }
  
  /// Ask the AI assistant a question about diabetes management
  Future<AiAssistantResponse> askQuestion(String question, {
    GlucoseReading? currentReading,
    List<GlucoseReading>? recentReadings,
  }) async {
    if (!isConfigured) {
      return AiAssistantResponse(
        message: 'AI Assistant is not configured. Please add your API key in settings.',
        type: AiResponseType.error,
        disclaimer: '',
      );
    }
    
    try {
      String context = '';
      if (currentReading != null) {
        context += '\nCurrent glucose: ${currentReading.value} mg/dL';
        context += '\nTrend: ${currentReading.trend ?? 'stable'}';
      }
      if (recentReadings != null && recentReadings.isNotEmpty) {
        final avg = recentReadings.map((r) => r.value).reduce((a, b) => a + b) / recentReadings.length;
        context += '\nRecent average (${recentReadings.length} readings): ${avg.toStringAsFixed(1)} mg/dL';
      }
      
      final prompt = '''
You are a helpful diabetes management assistant. Answer the following question from a person managing their diabetes.

User's current context:$context

User's question: $question

Guidelines:
- Be helpful, supportive, and informative
- Provide practical, actionable advice when relevant
- Do NOT provide specific medical diagnosis or treatment recommendations
- Remind users to consult their healthcare provider for important decisions
- Keep responses concise but thorough
''';
      
      return await _sendMessage(prompt);
    } catch (e) {
      return AiAssistantResponse(
        message: 'Unable to process your question: ${e.toString()}',
        type: AiResponseType.error,
        disclaimer: '',
      );
    }
  }
  
  /// Build analysis prompt from glucose data
  String _buildAnalysisPrompt({
    required GlucoseReading currentReading,
    required List<GlucoseReading> recentReadings,
    String? userContext,
  }) {
    // Calculate statistics
    final values = recentReadings.map((r) => r.value).toList();
    final average = values.isNotEmpty 
        ? values.reduce((a, b) => a + b) / values.length 
        : currentReading.value;
    final min = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : currentReading.value;
    final max = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : currentReading.value;
    
    // Count time in range
    final inRange = values.where((v) => v >= 70 && v <= 180).length;
    final timeInRange = values.isNotEmpty ? (inRange / values.length * 100) : 0;
    
    // Identify patterns
    final lowCount = values.where((v) => v < 70).length;
    final highCount = values.where((v) => v > 180).length;
    
    return '''
You are an AI assistant helping a person with diabetes understand their glucose readings. Analyze the following data and provide helpful insights.

CURRENT STATUS:
- Current glucose: ${currentReading.value} mg/dL
- Trend: ${currentReading.trend ?? 'stable'}
- Status: ${currentReading.status.label}

RECENT HISTORY (${recentReadings.length} readings):
- Average: ${average.toStringAsFixed(1)} mg/dL
- Range: ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} mg/dL
- Time in target range (70-180): ${timeInRange.toStringAsFixed(1)}%
- Low episodes (<70): $lowCount
- High episodes (>180): $highCount

${userContext != null ? 'USER CONTEXT: $userContext' : ''}

Please provide:
1. A brief assessment of the current glucose status
2. Analysis of recent patterns (good or concerning trends)
3. 2-3 practical tips or recommendations
4. Any warnings if glucose is critically low or high

IMPORTANT:
- Be supportive and encouraging
- Focus on actionable advice
- Do NOT provide specific insulin dosing recommendations
- Do NOT diagnose medical conditions
- Keep the response concise (under 200 words)
''';
  }
  
  /// Send message to LLM API
  Future<AiAssistantResponse> _sendMessage(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'key': _apiKey,
        'query': prompt,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['response'] as String;
      
      // Determine response type based on content
      AiResponseType type = AiResponseType.info;
      if (content.toLowerCase().contains('warning') || 
          content.toLowerCase().contains('attention') ||
          content.toLowerCase().contains('concern')) {
        type = AiResponseType.warning;
      } else if (content.toLowerCase().contains('great') || 
                 content.toLowerCase().contains('excellent') ||
                 content.toLowerCase().contains('good job')) {
        type = AiResponseType.positive;
      }
      
      return AiAssistantResponse(
        message: content,
        type: type,
        disclaimer: _getDisclaimer(),
      );
    } else {
      throw Exception('API request failed with status ${response.statusCode}');
    }
  }
  
  /// Get the standard disclaimer text
  String _getDisclaimer() {
    return '⚠️ This is AI-generated advice and should not replace professional medical guidance. '
           'Always consult your healthcare provider for important decisions about your diabetes management.';
  }
}

/// Response from the AI assistant
class AiAssistantResponse {
  final String message;
  final AiResponseType type;
  final String disclaimer;
  final DateTime timestamp;
  
  AiAssistantResponse({
    required this.message,
    required this.type,
    required this.disclaimer,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Type of AI response
enum AiResponseType {
  info,
  positive,
  warning,
  error,
}

extension AiResponseTypeExtension on AiResponseType {
  String get label {
    switch (this) {
      case AiResponseType.info:
        return 'Information';
      case AiResponseType.positive:
        return 'Good News';
      case AiResponseType.warning:
        return 'Attention Needed';
      case AiResponseType.error:
        return 'Error';
    }
  }
}
