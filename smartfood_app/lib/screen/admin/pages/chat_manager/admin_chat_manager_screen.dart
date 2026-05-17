import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_chat_detail_screen.dart';
import '../../../../services/api/chat_api.dart';

class AdminChatManagerScreen extends StatefulWidget {
  const AdminChatManagerScreen({super.key});

  @override
  State<AdminChatManagerScreen> createState() => _AdminChatManagerScreenState();
}

class _AdminChatManagerScreenState extends State<AdminChatManagerScreen> {
  final ChatApi _api = ChatApi();

  List<ChatThread> _threads = [];
  final Map<int, DateTime> _seenAtByThread = {};
  bool _loadingThreads = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loadingThreads = true;
    });

    try {
      final threads = await _api.getAdminThreads();
      if (!mounted) return;

      setState(() {
        _threads = threads;
        _loadingThreads = false;
      });

      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingThreads = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final threads = await _api.getAdminThreads();
        if (!mounted) return;
        setState(() {
          _threads = threads;
        });
      } catch (_) {}
    });
  }

  bool _isUnread(ChatThread t) {
    final lastAt = _lastCustomerTimeOf(t);
    if (lastAt == null) return false;
    final seenAt = _seenAtByThread[t.id];
    if (seenAt == null) return true;
    return lastAt.isAfter(seenAt);
  }

  DateTime? _lastCustomerTimeOf(ChatThread t) {
    if (t.lastCustomerMessageAt != null) return t.lastCustomerMessageAt!;
    if ((t.lastSenderType ?? '') == 'customer') {
      return t.lastMessageAt ?? t.updatedAt;
    }
    // Fallback cho backend cu: van coi theo tin nhan gan nhat.
    return t.lastMessageAt ?? t.updatedAt;
  }

  Future<void> _openThread(ChatThread thread) async {
    final seenAt = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => AdminChatDetailScreen(thread: thread),
      ),
    );
    if (!mounted) return;
    setState(() {
      _seenAtByThread[thread.id] = seenAt ?? DateTime.now();
    });
    await _loadThreads();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingThreads) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 34, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'Chua co hoi thoai nao.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loadThreads,
                icon: const Icon(Icons.refresh),
                label: const Text('Tai lai'),
              ),
            ],
          ),
        ),
      );
    }

    final sortedThreads = [..._threads]
      ..sort((a, b) {
        final aUnread = _isUnread(a);
        final bUnread = _isUnread(b);
        if (aUnread != bUnread) return bUnread ? 1 : -1;
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.separated(
        itemCount: sortedThreads.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = sortedThreads[index];
          final unread = _isUnread(t);
          final time = t.lastMessageAt ?? t.updatedAt;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: CircleAvatar(
              backgroundColor:
                  unread ? Colors.red.shade50 : Colors.blueGrey.shade50,
              child: Icon(
                Icons.person,
                color: unread ? Colors.red : Colors.blueGrey,
              ),
            ),
            title: Text(
              t.customerName,
              style: TextStyle(
                fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              t.lastMessage?.isNotEmpty == true
                  ? t.lastMessage!
                  : 'Chua co tin nhan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                if (unread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onTap: () => _openThread(t),
          );
        },
      ),
    );
  }
}
