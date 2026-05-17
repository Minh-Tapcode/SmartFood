import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../ApiService.dart';

class ChatActionProduct {
  final int productId;
  final String name;
  final int quantity;

  ChatActionProduct({
    required this.productId,
    required this.name,
    required this.quantity,
  });

  factory ChatActionProduct.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is num ? value.toInt() : 0;
    return ChatActionProduct(
      productId: asInt(json['productId']),
      name: (json['name'] ?? '').toString(),
      quantity: asInt(json['quantity']) > 0 ? asInt(json['quantity']) : 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
      };
}

class ChatAction {
  final String type;
  final String label;
  final List<ChatActionProduct> products;

  ChatAction({
    required this.type,
    required this.label,
    required this.products,
  });

  factory ChatAction.fromJson(Map<String, dynamic> json) {
    final raw = json['products'];
    final list = raw is List
        ? raw
            .map((e) => ChatActionProduct.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ChatActionProduct>[];
    return ChatAction(
      type: (json['type'] ?? 'add_to_cart').toString(),
      label: (json['label'] ?? 'Thêm vào giỏ').toString(),
      products: list,
    );
  }
}

class ChatMessage {
  final int id;
  final int chatId;
  final String senderType;
  final int? senderUserId;
  final String content;
  final DateTime sentAt;
  final List<ChatAction> actions;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderType,
    required this.senderUserId,
    required this.content,
    required this.sentAt,
    this.actions = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is num ? value.toInt() : 0;
    final rawActions = json['actions'];
    List<ChatAction> actions = [];
    if (rawActions is List) {
      actions = rawActions
          .map((e) => ChatAction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return ChatMessage(
      id: asInt(json['id']),
      chatId: asInt(json['chatId']),
      senderType: (json['senderType'] ?? '').toString(),
      senderUserId:
          json['senderUserId'] is num ? (json['senderUserId'] as num).toInt() : null,
      content: (json['content'] ?? '').toString(),
      sentAt: DateTime.tryParse((json['sentAt'] ?? '').toString()) ??
          DateTime.now(),
      actions: actions,
    );
  }
}

class ChatThread {
  final int id;
  final int customerUserId;
  final String customerName;
  final int? agentUserId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderType;
  final DateTime? lastCustomerMessageAt;

  ChatThread({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.agentUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderType,
    required this.lastCustomerMessageAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is num ? value.toInt() : 0;
    return ChatThread(
      id: asInt(json['id']),
      customerUserId: asInt(json['customerUserId']),
      customerName: (json['customerName'] ?? 'Khach ${asInt(json['customerUserId'])}')
          .toString(),
      agentUserId:
          json['agentUserId'] is num ? (json['agentUserId'] as num).toInt() : null,
      status: (json['status'] ?? 'open').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      lastSenderType: json['lastSenderType']?.toString(),
      lastCustomerMessageAt: json['lastCustomerMessageAt'] != null
          ? DateTime.tryParse(json['lastCustomerMessageAt'].toString())
          : null,
    );
  }
}

class ChatApi {
  String get _base => '${Constant().baseUrl}/chat';
  static const _userSeenAtKey = 'chat_user_last_seen_at';
  static const _inboxBaselineKey = 'chat_inbox_baseline_done';

  Future<ChatThread> createOrGetThread() async {
    final res = await http.post(
      Uri.parse('$_base/threads'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({}),
    );

    if (res.statusCode != 200) {
      throw Exception('Không thể tạo cuộc trò chuyện: ${res.statusCode}');
    }

    return ChatThread.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getMessages(int chatId, {int take = 100}) async {
    final uri = Uri.parse('$_base/threads/$chatId/messages')
        .replace(queryParameters: {'take': '$take'});
    final res = await http.get(uri, headers: await ApiService().getHeaders());

    if (res.statusCode != 200) {
      throw Exception('Không thể lấy tin nhắn: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatThread>> getMyThreads() async {
    final res = await http.get(
      Uri.parse('$_base/threads'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Không thể lấy danh sách chat: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => ChatThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatThread>> getAllThreads() async {
    final res = await http.get(
      Uri.parse('$_base/threads/all'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode == 404) {
      // Backward-compatible fallback khi backend chưa có endpoint admin.
      return getMyThreads();
    }
    if (res.statusCode != 200) {
      throw Exception('Không thể lấy tất cả chat: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => ChatThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatThread>> getAdminThreads() async {
    return getAllThreads();
  }

  Future<void> markUserInboxSeenNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userSeenAtKey, DateTime.now().toIso8601String());
  }

  /// Lần đầu cài app: chốt baseline để không báo tin bot cũ. Các lần sau giữ lastSeen khi thoát app.
  Future<void> ensureInboxBaselineOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_inboxBaselineKey) == true) return;
    await syncUserInboxSeenToLatest();
    await prefs.setBool(_inboxBaselineKey, true);
  }

  /// Đánh dấu đã đọc tới tin mới nhất hiện có.
  Future<void> syncUserInboxSeenToLatest() async {
    try {
      final threads = await getMyThreads();
      var latest = DateTime.fromMillisecondsSinceEpoch(0);
      for (final t in threads) {
        final at = t.lastMessageAt;
        if (at != null && at.isAfter(latest)) latest = at;
      }
      final prefs = await SharedPreferences.getInstance();
      final markAt = latest.millisecondsSinceEpoch > 0
          ? latest
          : DateTime.now();
      await prefs.setString(_userSeenAtKey, markAt.toIso8601String());
    } catch (_) {
      await markUserInboxSeenNow();
    }
  }

  Future<DateTime> getUserLastSeenAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userSeenAtKey);
    return DateTime.tryParse(raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<int> getUserUnreadCount() async {
    final threads = await getMyThreads();
    final seenAt = await getUserLastSeenAt();
    return threads.where((t) {
      final lastAt = t.lastMessageAt;
      if (lastAt == null) return false;
      return (t.lastSenderType ?? '') != 'customer' && lastAt.isAfter(seenAt);
    }).length;
  }

  Future<List<ChatMessage>> sendMessage(int chatId, String content) async {
    final res = await http.post(
      Uri.parse('$_base/threads/$chatId/messages'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({'content': content}),
    );

    if (res.statusCode != 200) {
      throw Exception('Gửi tin nhắn thất bại: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final sent = data['sent'] != null
        ? ChatMessage.fromJson(data['sent'] as Map<String, dynamic>)
        : null;
    final bot = data['bot'] != null
        ? ChatMessage.fromJson(data['bot'] as Map<String, dynamic>)
        : null;

    final result = <ChatMessage>[];
    if (sent != null) result.add(sent);
    if (bot != null) result.add(bot);
    return result;
  }

  Future<String> addSuggestedToCart(List<ChatActionProduct> products) async {
    final res = await http.post(
      Uri.parse('$_base/add-to-cart'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({
        'products': products.map((p) => p.toJson()).toList(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Không thêm được vào giỏ: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['message'] ?? 'Đã thêm vào giỏ').toString();
  }
}
