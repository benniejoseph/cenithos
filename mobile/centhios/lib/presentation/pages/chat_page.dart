import 'dart:async';
import 'dart:convert';
import 'package:centhios/app_theme.dart';
import 'package:centhios/core/config.dart';
import 'package:centhios/presentation/widgets/glassmorphic_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  String _aiStatus = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add a default welcome message from the bot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.insert(0, {
          'sender': 'bot',
          'text':
              'Hello! I am Alex, your personal finance assistant. How can I help you today?'
        });
      });
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoading) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _isLoading = true;
      _aiStatus = 'Alex is thinking...';
      _messages.insert(0, {'sender': 'user', 'text': userMessage});
    });
    _scrollToBottom();

    try {
      // Fake delay for typing effect
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _aiStatus = 'Analyzing your query...';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      // This is a placeholder for the actual API call.
      // In a real scenario, you would make the HTTP request here.
      const mockResponse =
          'This is a simulated response from Alex. Integrating the actual AI API would show a real answer here.';
      setState(() {
        _messages.insert(0, {'sender': 'bot', 'text': mockResponse});
        _aiStatus = '';
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.insert(
            0, {'sender': 'bot', 'text': 'Sorry, something went wrong.'});
        _isLoading = false;
        _aiStatus = '';
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chat with Alex'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, theme);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(radius: 8),
                  const SizedBox(width: 8),
                  Text(_aiStatus, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          _buildMessageComposer(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message, ThemeData theme) {
    final isUser = message['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GlassmorphicCard(
        isGlowEnabled: isUser,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            message['text']!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageComposer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GlassmorphicCard(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Ask Alex anything...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send, color: AppTheme.accent.withOpacity(0.8)),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
