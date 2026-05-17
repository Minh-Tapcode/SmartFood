import 'package:flutter/material.dart';
import 'package:smartfood_app/services/api/promotion_api.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final PromotionApi _api = PromotionApi();
  late Future<List<Map<String, dynamic>>> _future;
  Set<int> _savedIds = {};
  Set<int> _usedIds = {};

  @override
  void initState() {
    super.initState();
    _loadSavedIds();
    _future = _load();
  }

  @override
  void activate() {
    super.activate();
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    await _api.syncUsedVouchersFromServer();
    final ids = await _api.getSavedVoucherIds();
    final usedIds = await _api.getUsedVoucherIds();
    if (!mounted) return;
    setState(() {
      _savedIds = ids;
      _usedIds = usedIds;
    });
  }

  Future<List<Map<String, dynamic>>> _load() => _api.fetchActive();

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
    await _loadSavedIds();
  }

  String _titleOf(Map<String, dynamic> p) =>
      (p['title'] ?? p['Title'] ?? 'Khuyến mãi').toString();

  String _percentOf(Map<String, dynamic> p) {
    final v = p['discountPercent'] ?? p['DiscountPercent'];
    if (v == null) return '';
    return 'Giảm $v%';
  }

  String _dateRange(Map<String, dynamic> p) {
    final s = p['startDate'] ?? p['StartDate'];
    final e = p['endDate'] ?? p['EndDate'];
    if (s == null && e == null) return '';
    return '${s ?? '—'} → ${e ?? '—'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Phiếu giảm giá',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Hiện chưa có chương trình giảm giá.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final p = list[index];
                final idRaw = p['id'] ?? p['Id'];
                final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
                final title = _titleOf(p);
                final pct = _percentOf(p);
                final range = _dateRange(p);
                final isSaved = _savedIds.contains(id);
                final isUsed = _usedIds.contains(id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_offer, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (pct.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                pct,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (range.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                range,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: id <= 0 || isUsed
                            ? null
                            : () async {
                                if (isSaved) {
                                  await _api.unsaveVoucherId(id);
                                } else {
                                  try {
                                    await _api.saveVoucherId(id);
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                    return;
                                  }
                                }
                                await _loadSavedIds();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isSaved
                                          ? 'Đã bỏ lưu voucher'
                                          : 'Đã lưu voucher',
                                    ),
                                  ),
                                );
                              },
                        child: Text(isUsed ? 'Đã dùng' : (isSaved ? 'Đã lưu' : 'Lưu')),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
