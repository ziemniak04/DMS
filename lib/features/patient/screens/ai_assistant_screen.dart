import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dms_app/providers/ai_assistant_provider.dart';
import 'package:dms_app/providers/glucose_provider.dart';
import 'package:dms_app/services/ai_assistant_service.dart';
import 'package:dms_app/core/theme/app_theme.dart';

/// AI Assistant Screen
/// 
/// Chat interface for interacting with the Claude-powered AI assistant
/// that provides glucose insights and diabetes management tips.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initializeAndAnalyze();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _initializeAndAnalyze() async {
    final aiProvider = context.read<AiAssistantProvider>();
    final glucoseProvider = context.read<GlucoseProvider>();
    
    // If configured and we have glucose data, do an initial analysis
    if (aiProvider.isConfigured && glucoseProvider.currentReading != null) {
      final readings = glucoseProvider.getReadingsForTimeRange(6);
      if (readings.isNotEmpty) {
        await aiProvider.analyzeGlucose(
          currentReading: glucoseProvider.currentReading!,
          recentReadings: readings,
        );
        _scrollToBottom();
      }
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    
    final aiProvider = context.read<AiAssistantProvider>();
    final glucoseProvider = context.read<GlucoseProvider>();
    
    await aiProvider.askQuestion(
      message,
      currentReading: glucoseProvider.currentReading,
      recentReadings: glucoseProvider.getReadingsForTimeRange(6),
    );
    
    _scrollToBottom();
  }
  
  void _analyzeCurrentData() async {
    final aiProvider = context.read<AiAssistantProvider>();
    final glucoseProvider = context.read<GlucoseProvider>();
    
    if (glucoseProvider.currentReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No glucose data available to analyze')),
      );
      return;
    }
    
    final readings = glucoseProvider.getReadingsForTimeRange(6);
    await aiProvider.analyzeGlucose(
      currentReading: glucoseProvider.currentReading!,
      recentReadings: readings,
    );
    
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _analyzeCurrentData,
            tooltip: 'Analyze current glucose data',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<AiAssistantProvider>().clearHistory();
            },
            tooltip: 'Clear chat history',
          ),
        ],
      ),
      body: Consumer<AiAssistantProvider>(
        builder: (context, aiProvider, child) {
          if (!aiProvider.isConfigured) {
            return _buildSetupPrompt(context);
          }
          
          return Column(
            children: [
              // Disclaimer banner
              _buildDisclaimerBanner(),
              
              // Chat messages
              Expanded(
                child: aiProvider.chatHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildChatList(aiProvider),
              ),
              
              // Loading indicator
              if (aiProvider.isLoading)
                const LinearProgressIndicator(),
              
              // Input area
              _buildInputArea(aiProvider),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI advice is not a substitute for professional medical guidance.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSetupPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'AI Assistant Not Configured',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To use the AI assistant, you need to add your Anthropic API key in settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showApiKeyDialog(context),
              icon: const Icon(Icons.key),
              label: const Text('Add API Key'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ask me about your glucose levels',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I can analyze your readings and provide tips',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Analyze my glucose'),
                _buildSuggestionChip('How am I doing today?'),
                _buildSuggestionChip('Tips for stable glucose'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }
  
  Widget _buildChatList(AiAssistantProvider aiProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: aiProvider.chatHistory.length,
      itemBuilder: (context, index) {
        final response = aiProvider.chatHistory[index];
        final isUserMessage = response.disclaimer.isEmpty && 
            response.type == AiResponseType.info &&
            index > 0;
        
        return _buildMessageBubble(response, isUserMessage);
      },
    );
  }
  
  Widget _buildMessageBubble(AiAssistantResponse response, bool isUserMessage) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: isUserMessage 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? AppTheme.primaryColor
                    : _getResponseColor(response.type),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUserMessage ? Radius.zero : null,
                  bottomLeft: !isUserMessage ? Radius.zero : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUserMessage && response.type != AiResponseType.info)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getResponseIcon(response.type),
                            size: 16,
                            color: isUserMessage ? Colors.white : _getResponseIconColor(response.type),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            response.type.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isUserMessage ? Colors.white : _getResponseIconColor(response.type),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    response.message,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (!isUserMessage && response.disclaimer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  response.disclaimer,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getResponseColor(AiResponseType type) {
    switch (type) {
      case AiResponseType.positive:
        return Colors.green.withValues(alpha: 0.1);
      case AiResponseType.warning:
        return Colors.orange.withValues(alpha: 0.1);
      case AiResponseType.error:
        return Colors.red.withValues(alpha: 0.1);
      case AiResponseType.info:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }
  
  Color _getResponseIconColor(AiResponseType type) {
    switch (type) {
      case AiResponseType.positive:
        return Colors.green[700]!;
      case AiResponseType.warning:
        return Colors.orange[700]!;
      case AiResponseType.error:
        return Colors.red[700]!;
      case AiResponseType.info:
        return Colors.grey[700]!;
    }
  }
  
  IconData _getResponseIcon(AiResponseType type) {
    switch (type) {
      case AiResponseType.positive:
        return Icons.thumb_up;
      case AiResponseType.warning:
        return Icons.warning_amber;
      case AiResponseType.error:
        return Icons.error_outline;
      case AiResponseType.info:
        return Icons.info_outline;
    }
  }
  
  Widget _buildInputArea(AiAssistantProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask about your glucose...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !aiProvider.isLoading,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: aiProvider.isLoading ? null : _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Anthropic API key to enable the AI assistant.',
            ),
            const SizedBox(height: 8),
            Text(
              'Get your API key from console.anthropic.com',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-ant-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<AiAssistantProvider>().configure(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
