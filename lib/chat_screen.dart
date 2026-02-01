import 'package:flutter/material.dart';
import 'services/api_service.dart';

class ChatSession {
  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Жаңа чат',
      lastMessagePreview: json['lastMessagePreview'] ?? '',
      lastMessageAt:
          json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt']) : null,
    );
  }
}

class ChatMessage {
  final String role;
  final String message;
  final DateTime? createdAt;

  ChatMessage({required this.role, required this.message, this.createdAt});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'assistant',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _activeSessionId;
  String _activeTitle = 'ЖИ кеңесші';
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final data = await ApiService.fetchChatSessions();
      if (!mounted) return;
      setState(() {
        _sessions = data.map((item) => ChatSession.fromJson(item)).toList();
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    setState(() => _isLoadingMessages = true);
    try {
      final data = await ApiService.fetchChatMessages(sessionId);
      final List<dynamic> items = data['messages'] ?? [];
      final session = data['session'];
      if (!mounted) return;
      setState(() {
        _activeSessionId = sessionId;
        _activeTitle = session?['title'] ?? 'ЖИ кеңесші';
        _messages
          ..clear()
          ..addAll(items.map((item) => ChatMessage.fromJson(item)));
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _startNewChat() async {
    try {
      final session = await ApiService.createChatSession();
      if (!mounted) return;
      setState(() {
        _activeSessionId = session['id'];
        _activeTitle = session['title'] ?? 'ЖИ кеңесші';
        _messages.clear();
      });
      await _loadSessions();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final userText = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(role: 'user', message: userText));
      _isSending = true;
    });
    _messageController.clear();

    try {
      String? sessionId = _activeSessionId;
      if (sessionId == null) {
        final session = await ApiService.createChatSession(title: userText);
        sessionId = session['id'];
        if (!mounted) return;
        setState(() {
          _activeSessionId = sessionId;
          _activeTitle = session['title'] ?? 'ЖИ кеңесші';
        });
      }

      final reply = await ApiService.sendChatMessage(userText, sessionId: sessionId);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', message: reply['message'] ?? ''));
      });
      await _loadSessions();
    } catch (e) {
      debugPrint("AI Error: $e");
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          message: 'Қате болды. Интернетті немесе API кілтін тексеріңіз.',
        ));
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _exitToList() {
    setState(() {
      _activeSessionId = null;
      _activeTitle = 'ЖИ кеңесші';
      _messages.clear();
    });
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final isChatOpen = _activeSessionId != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_activeTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink,
        elevation: 0.5,
        leading: isChatOpen
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _exitToList,
              )
            : null,
        actions: [
          if (isChatOpen)
            IconButton(
              icon: const Icon(Icons.add_comment),
              onPressed: _startNewChat,
            ),
        ],
      ),
      body: isChatOpen ? _buildChatView() : _buildSessionList(),
    );
  }

  Widget _buildSessionList() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNewChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Жаңа чат', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Text('Әзірге чат жоқ', style: TextStyle(color: Colors.grey)),
                )
              : ListView.separated(
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return ListTile(
                      title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        session.lastMessagePreview.isEmpty
                            ? 'Жаңа чат'
                            : session.lastMessagePreview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _loadMessages(session.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatView() {
    final messages = List<ChatMessage>.from(_messages);
    if (messages.isEmpty) {
      messages.add(ChatMessage(
        role: 'assistant',
        message: 'Сәлем! Гүлдер туралы қандай сұрағыңыз бар?',
      ));
    }

    return Column(
      children: [
        Expanded(
          child: _isLoadingMessages
              ? const Center(child: CircularProgressIndicator(color: Colors.pink))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message.role == 'user';
                    return _buildChatBubble(message.message, isUser);
                  },
                ),
        ),
        if (_isSending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              color: Colors.pink,
              backgroundColor: Colors.pink.withOpacity(0.2),
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.pink.shade400 : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Сұрағыңызды қойыңыз...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.pink,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
