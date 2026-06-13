import 'package:flutter/material.dart';
import 'add_to_cart_sheet.dart';
import 'app_language.dart';
import 'product.dart';
import 'services/api_service.dart';
import 'widgets/product_card.dart';
import 'widgets/top_toast.dart';

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
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
    );
  }
}

class ChatMessage {
  final String role;
  final String message;
  final DateTime? createdAt;
  final List<Product> products;

  ChatMessage({
    required this.role,
    required this.message,
    this.createdAt,
    this.products = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'assistant',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      products: productsFromJson(json['products']),
    );
  }

  static List<Product> productsFromJson(dynamic value) {
    if (value is! List) return const [];
    final products = <Product>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        products.add(Product.fromJson(item));
      } else if (item is Map) {
        products.add(Product.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return products;
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _advisorTitle = 'ЖИ кеңесші';
  static const _newChatTitle = 'Жаңа чат';
  static const _advisorTitles = {'ЖИ кеңесші', 'ИИ-консультант', 'AI advisor'};
  static const _newChatTitles = {'Жаңа чат', 'Новый чат', 'New chat'};

  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _activeSessionId;
  String _activeTitle = _advisorTitle;
  bool _isDraftChatOpen = false;
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadFavorites();
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

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favorites.map((item) => item.id).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(Product product) async {
    final t = context.t;
    final isFav = _favoriteIds.contains(product.id);
    try {
      if (isFav) {
        await ApiService.removeFavorite(product.id);
      } else {
        await ApiService.addFavorite(product.id);
      }
      if (!mounted) return;
      setState(() {
        if (isFav) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id);
        }
      });
    } catch (_) {
      if (!mounted) return;
      showTopToast(
        context,
        isFav ? t.removeFavoriteFailed : t.addFavoriteFailed,
      );
    }
  }

  Future<void> _addToCart(Product product) async {
    final t = context.t;
    try {
      await ApiService.addToCart(product.id, quantity: 1);
      if (!mounted) return;
      showTopToast(context, t.addedToCart);
    } catch (_) {
      if (!mounted) return;
      showTopToast(context, t.addToCartFailed);
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
        _activeTitle = session?['title'] ?? _advisorTitle;
        _isDraftChatOpen = false;
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
    setState(() {
      _activeSessionId = null;
      _activeTitle = _newChatTitle;
      _isDraftChatOpen = true;
      _messages.clear();
    });
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
      final reply = await ApiService.sendChatMessage(
        userText,
        sessionId: sessionId,
      );
      if (!mounted) return;
      sessionId = reply['sessionId']?.toString() ?? sessionId;
      final suggestedProducts = ChatMessage.productsFromJson(reply['products']);
      setState(() {
        _activeSessionId = sessionId;
        _activeTitle = reply['title'] ?? _activeTitle;
        _isDraftChatOpen = false;
        _messages.add(
          ChatMessage(
            role: 'assistant',
            message: reply['message'] ?? '',
            products: suggestedProducts,
          ),
        );
      });
      await _loadSessions();
    } catch (e) {
      debugPrint("AI Error: $e");
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(role: 'assistant', message: context.t.aiError),
        );
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _exitToList() {
    setState(() {
      _activeSessionId = null;
      _activeTitle = _advisorTitle;
      _isDraftChatOpen = false;
      _messages.clear();
    });
    _loadSessions();
  }

  Future<void> _deleteSession(ChatSession session) async {
    try {
      await ApiService.deleteChatSession(session.id);
      if (!mounted) return;
      setState(() {
        _sessions.removeWhere((item) => item.id == session.id);
        if (_activeSessionId == session.id) {
          _activeSessionId = null;
          _activeTitle = _advisorTitle;
          _isDraftChatOpen = false;
          _messages.clear();
        }
      });
    } catch (_) {}
  }

  String _localizedTitle(AppText t, String title) {
    if (_advisorTitles.contains(title)) return t.aiAdvisor;
    if (_newChatTitles.contains(title)) return t.newChat;
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isChatOpen = _activeSessionId != null || _isDraftChatOpen;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _localizedTitle(t, _activeTitle),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                context.t.newChat,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: _sessions.isEmpty
              ? Center(
                  child: Text(
                    context.t.noChatsYet,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return ListTile(
                      title: Text(
                        _localizedTitle(context.t, session.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        session.lastMessagePreview.isEmpty
                            ? context.t.newChat
                            : session.lastMessagePreview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.black45,
                        onPressed: () => _deleteSession(session),
                      ),
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
      messages.add(
        ChatMessage(role: 'assistant', message: context.t.chatGreeting),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _isLoadingMessages
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildChatMessage(message);
                  },
                ),
        ),
        if (_isSending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              color: Colors.pink,
              backgroundColor: Colors.pink.withValues(alpha: 0.2),
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.role == 'user';
    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _buildChatBubble(message.message, isUser),
        if (!isUser && message.products.isNotEmpty)
          _buildProductSuggestions(message.products),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
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

  Widget _buildProductSuggestions(List<Product> products) {
    return SizedBox(
      height: 286,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 4, right: 4, bottom: 10),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isFav = _favoriteIds.contains(product.id);
          return ProductCard(
            product: product,
            isFavorite: isFav,
            width: 174,
            margin: const EdgeInsets.only(right: 12),
            onTap: () => showAddToCartSheet(context, product),
            onAddToCartPressed: () => _addToCart(product),
            onFavoritePressed: () => _toggleFavorite(product),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                  hintText: context.t.askQuestionHint,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
