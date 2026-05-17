import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../services/api/chat_api.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _api = ChatApi();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [];
  int? _chatId;
  int _lastMessageId = 0;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _api.markUserInboxSeenNow();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final thread = await _api.createOrGetThread();
      final messages = await _api.getMessages(thread.id);
      if (!mounted) return;

      setState(() {
        _chatId = thread.id;
        _messages
          ..clear()
          ..addAll(messages.map(_fromApi));
        _lastMessageId = messages.isNotEmpty ? messages.last.id : 0;
        _loading = false;
      });
      await _api.markUserInboxSeenNow();

      _startPolling();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final chatId = _chatId;
      if (chatId == null || !mounted) return;
      try {
        final messages = await _api.getMessages(chatId);
        if (!mounted) return;
        final latestId = messages.isNotEmpty ? messages.last.id : _lastMessageId;
        final hasNewIncoming = messages.isNotEmpty &&
            latestId > _lastMessageId &&
            messages.last.senderType != 'customer';
        setState(() {
          _messages
            ..clear()
            ..addAll(messages.map(_fromApi));
          _lastMessageId = latestId;
        });
        if (hasNewIncoming) _scrollToBottom();
      } catch (_) {
        // Bỏ qua lỗi poll để không làm gián đoạn chat.
      }
    });
  }

  _ChatMsg _fromApi(ChatMessage m) {
    return _ChatMsg(
      m.senderType == 'customer',
      m.content,
      senderType: m.senderType,
      sentAt: m.sentAt,
      actions: m.actions,
    );
  }

  Future<void> _addActionToCart(ChatAction action) async {
    if (action.products.isEmpty) return;
    try {
      final msg = await _api.addSuggestedToCart(action.products);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final chatId = _chatId;
    if (text.isEmpty || chatId == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final draft = text;
    _controller.clear();
    try {
      await _api.sendMessage(chatId, draft);
      final messages = await _api.getMessages(chatId);
      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(messages.map(_fromApi));
        _lastMessageId = messages.isNotEmpty ? messages.last.id : _lastMessageId;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      setState(() {
        _error = msg;
      });
      _controller.text = draft;
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (_isSameDate(d, today)) return 'Hôm nay';
    if (_isSameDate(d, today.subtract(const Duration(days: 1)))) return 'Hôm qua';
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Chat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final prev = i > 0 ? _messages[i - 1] : null;
                      final showDateDivider =
                          prev == null || !_isSameDate(prev.sentAt, m.sentAt);
                      final align = m.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft;
                      final isBot = m.senderType == 'bot';
                      final color = m.fromUser
                          ? Colors.green.shade700
                          : isBot
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey.shade200;
                      final fg = m.fromUser ? Colors.white : Colors.black87;
                      return Column(
                        children: [
                          if (showDateDivider)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _dateLabel(m.sentAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: align,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.sizeOf(context).width * 0.85),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.text,
                                      style: TextStyle(color: fg, height: 1.35)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          m.fromUser ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  if (isBot && m.actions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...m.actions.map(
                                      (action) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.tonal(
                                            onPressed: () => _addActionToCart(action),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.green.shade100,
                                              foregroundColor: Colors.green.shade900,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                            ),
                                            child: Text(
                                              action.label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final bool fromUser;
  final String text;
  final String senderType;
  final DateTime sentAt;
  final List<ChatAction> actions;
  _ChatMsg(this.fromUser, this.text,
      {this.senderType = 'customer',
      DateTime? sentAt,
      this.actions = const []})
      : sentAt = sentAt ?? DateTime.now();
}
