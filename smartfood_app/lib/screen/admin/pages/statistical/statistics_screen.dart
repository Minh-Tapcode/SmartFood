import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartfood_app/screen/admin/services/admin_order_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _service = AdminOrderService();
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _daily = [];
  List<Map<String, dynamic>> _monthly = [];
  List<Map<String, dynamic>> _yearly = [];
  List<Map<String, dynamic>> _orders = [];
  late DateTime _summaryStart;
  late DateTime _summaryEnd;
  late DateTime _pieStart;
  late DateTime _pieEnd;
  late DateTime _dailyStart;
  late DateTime _dailyEnd;
  int _monthlyYear = DateTime.now().year;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    final monthStart = DateTime(today.year, today.month, 1);
    _summaryStart = monthStart;
    _summaryEnd = today;
    _pieStart = monthStart;
    _pieEnd = today;
    _dailyStart = monthStart;
    _dailyEnd = today;
    _reloadData();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _reloadData() async {
    if (!mounted) return;
    if (!_loading) {
      setState(() => _loading = true);
    }
    try {
      final results = await Future.wait([
        _service.getSummary(startDate: _summaryStart, endDate: _summaryEnd),
        _service.getRevenueByDayRange(
            startDate: _dailyStart, endDate: _dailyEnd),
        _service.getRevenueByMonth(year: _monthlyYear),
        _service.getOrders(),
        _service.getRevenueByYear(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _daily = results[1] as List<Map<String, dynamic>>;
        _monthly = results[2] as List<Map<String, dynamic>>;
        _orders = results[3] as List<Map<String, dynamic>>;
        _yearly = results[4] as List<Map<String, dynamic>>;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime? _orderCreatedDay(Map<String, dynamic> o) {
    final raw = (o['createdAt'] ?? o['CreatedAt'])?.toString();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return _dateOnly(parsed);
  }

  List<Map<String, dynamic>> get _ordersForPie {
    return _orders.where((o) {
      final day = _orderCreatedDay(o);
      if (day == null) return false;
      return !day.isBefore(_pieStart) && !day.isAfter(_pieEnd);
    }).toList();
  }

  Future<void> _pickStart(
    DateTime currentStart,
    DateTime currentEnd,
    void Function(DateTime start, DateTime end) apply,
  ) async {
    final d = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final picked = _dateOnly(d);
    final end = currentEnd.isBefore(picked) ? picked : currentEnd;
    apply(picked, end);
  }

  Future<void> _pickEnd(
    DateTime currentStart,
    DateTime currentEnd,
    void Function(DateTime start, DateTime end) apply,
  ) async {
    final d = await showDatePicker(
      context: context,
      initialDate: currentEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final picked = _dateOnly(d);
    final start = picked.isBefore(currentStart) ? picked : currentStart;
    apply(start, picked);
  }

  Widget _sectionDateRangeBar({
    required DateTime start,
    required DateTime end,
    required void Function(DateTime start, DateTime end) onRangeChanged,
    bool reloadOnChange = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await _pickStart(start, end, (s, e) {
                setState(() {
                  onRangeChanged(s, e);
                });
              });
              if (reloadOnChange) await _reloadData();
            },
            child: Text('Từ: ${_formatDate(start)}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await _pickEnd(start, end, (s, e) {
                setState(() {
                  onRangeChanged(s, e);
                });
              });
              if (reloadOnChange) await _reloadData();
            },
            child: Text('Đến: ${_formatDate(end)}'),
          ),
        ),
      ],
    );
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _statusLabelVi(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'completed':
        return 'Hoàn thành';
      case 'picking':
        return 'Đang lấy hàng';
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'processing':
        return 'Đang xử lý';
      case 'packed':
        return 'Đã đóng gói';
      case 'shipping':
        return 'Đang giao';
      case 'in_delivery':
      case 'in_transit':
        return 'Đang vận chuyển';
      case 'delivered':
        return 'Đã giao';
      case 'shipped':
        return 'Đã gửi hàng';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'failed':
        return 'Thất bại';
      case 'returned':
        return 'Đã hoàn trả';
      case 'shipperassigned':
      case 'shipper_assigned':
      case 'assigned_to_shipper':
        return 'Đã phân công shipper';
      case 'waitingforshipper':
      case 'waiting_for_shipper':
        return 'Chờ shipper nhận đơn';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _reloadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tổng quan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _exportCsv,
                        icon: const Icon(Icons.download_outlined),
                        tooltip: 'Xuất CSV mở bằng Excel',
                      ),
                    ],
                  ),
                  const Text(
                    'Khoảng thời gian áp dụng cho các ô tổng hợp bên dưới',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  _sectionDateRangeBar(
                    start: _summaryStart,
                    end: _summaryEnd,
                    onRangeChanged: (s, e) {
                      _summaryStart = s;
                      _summaryEnd = e;
                    },
                  ),
                  const SizedBox(height: 8),
                  _tile('Tổng đơn hàng', '${_summary['totalOrders'] ?? 0}',
                      Icons.receipt_long_outlined, Colors.green),
                  _tile('Tổng khách hàng', '${_summary['totalUsers'] ?? 0}',
                      Icons.people_outline, Colors.purple),
                  _tile(
                      'Doanh thu tạm tính',
                      '${_toNum(_summary['totalRevenue']).toStringAsFixed(0)} VND',
                      Icons.monetization_on_outlined,
                      Colors.teal),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: const Text('Không tải được đầy đủ dữ liệu thống kê'),
                subtitle: Text(_error!),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildOrderStatusPieChart(),
          const SizedBox(height: 8),
          _buildRevenueLineChart(),
          const SizedBox(height: 8),
          _buildRevenueBarChart(),
          const SizedBox(height: 8),
          _buildYearlyRevenueCard(),
        ],
      ),
    );
  }

  Widget _buildOrderStatusPieChart() {
    final orders = _ordersForPie;
    final map = <String, int>{};
    for (final o in orders) {
      final status = (o['status'] ?? o['Status'] ?? 'unknown').toString();
      map[status] = (map[status] ?? 0) + 1;
    }
    final entries = map.entries.toList();
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biểu đồ tròn - Cơ cấu trạng thái đơn hàng',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Chỉ tính các đơn được tạo trong khoảng:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _sectionDateRangeBar(
              start: _pieStart,
              end: _pieEnd,
              reloadOnChange: false,
              onRangeChanged: (s, e) {
                _pieStart = s;
                _pieEnd = e;
              },
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Không có đơn hàng trong khoảng thời gian đã chọn.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: List.generate(entries.length, (i) {
                      final e = entries[i];
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: e.value.toDouble(),
                        title: '${e.value}',
                        radius: 75,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: List.generate(entries.length, (i) {
                  final e = entries[i];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${_statusLabelVi(e.key)}: ${e.value}'),
                    ],
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart() {
    final data = _daily
        .map((e) => (
              label: '${e['date']}'.split('-').last,
              value: _toNum(e['revenue']).toDouble(),
            ))
        .toList();
    final rangeTitle =
        'Biểu đồ đường - Doanh thu theo ngày (${_formatDate(_dailyStart)} → ${_formatDate(_dailyEnd)})';
    if (data.isEmpty) return _emptyChartCard(rangeTitle);
    final labelStep =
        data.length > 18 ? ((data.length + 7) ~/ 8).clamp(1, data.length) : 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rangeTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Chọn khoảng thời gian (tối đa ~366 ngày mỗi lần tải)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _sectionDateRangeBar(
              start: _dailyStart,
              end: _dailyEnd,
              onRangeChanged: (s, e) {
                _dailyStart = s;
                _dailyEnd = e;
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          if (idx % labelStep != 0 && idx != data.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Text(data[idx].label,
                              style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), data[i].value),
                      ),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBarChart() {
    final data = _monthly
        .map((e) => (
              label: 'T${e['month']}',
              value: _toNum(e['revenue']).toDouble(),
            ))
        .toList();
    final title = 'Biểu đồ cột - Doanh thu theo tháng (năm $_monthlyYear)';
    if (data.isEmpty) return _emptyChartCard(title);
    final labelStep = data.length > 8 ? 2 : 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Năm:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _monthlyYear,
                  items: [
                    for (var y = 2020; y <= DateTime.now().year + 1; y++)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (y) async {
                    if (y == null) return;
                    setState(() => _monthlyYear = y);
                    await _reloadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          if (idx % labelStep != 0 && idx != data.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Text(data[idx].label,
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    data.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].value,
                          color: Colors.blue,
                          width: 14,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyRevenueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doanh thu theo năm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tổng hợp theo năm dương lịch (tất cả đơn trong hệ thống)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            if (_yearly.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Chưa có dữ liệu'),
              )
            else
              ..._yearly.map((e) {
                final y = e['year'] ?? e['Year'] ?? '--';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Năm $y'),
                  subtitle: Text(
                      'Đơn: ${e['orderCount'] ?? e['OrderCount'] ?? 0}'),
                  trailing: Text(
                    '${_toNum(e['revenue'] ?? e['Revenue']).toStringAsFixed(0)} VND',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _emptyChartCard(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Không có dữ liệu biểu đồ'),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final rows = <String>[
        'TONG_QUAN',
        'KhoangThoiGian,TongDonHang,TongKhachHang,TongDoanhThu',
        '"${_formatDate(_summaryStart)} - ${_formatDate(_summaryEnd)}",${_summary['totalOrders'] ?? 0},${_summary['totalUsers'] ?? 0},${_toNum(_summary['totalRevenue']).toStringAsFixed(0)}',
        '',
        'DOANH_THU_THEO_NGAY',
        'Khoang,"${_formatDate(_dailyStart)} - ${_formatDate(_dailyEnd)}"',
        'Ngay,SoDon,DoanhThu',
        ..._daily.map((e) {
          final date = _csv(e['date']);
          final count = _csv(e['orderCount']);
          final revenue = _toNum(e['revenue']).toStringAsFixed(0);
          return '$date,$count,$revenue';
        }),
        '',
        'DOANH_THU_THEO_NAM',
        'Nam,SoDon,DoanhThu',
        ..._yearly.map((e) {
          final year = _csv(e['year'] ?? e['Year']);
          final count = _csv(e['orderCount'] ?? e['OrderCount']);
          final revenue = _toNum(e['revenue'] ?? e['Revenue']).toStringAsFixed(0);
          return '$year,$count,$revenue';
        }),
      ];

      Directory? targetDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          final winDownload = Directory(
            '$userProfile${Platform.pathSeparator}Downloads',
          );
          if (await winDownload.exists()) {
            targetDir = winDownload;
          }
        }
      } else if (Platform.isAndroid) {
        final androidDownload = Directory('/storage/emulated/0/Download');
        if (await androidDownload.exists()) {
          targetDir = androidDownload;
        }
      }
      targetDir ??= await getDownloadsDirectory();
      targetDir ??= await getApplicationDocumentsDirectory();
      final path =
          '${targetDir.path}${Platform.pathSeparator}thong_ke_$stamp.csv';
      final file = File(path);
      await file.writeAsString(rows.join('\n'));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Xuất CSV thành công: $path'),
          action: SnackBarAction(
            label: 'Mở file',
            onPressed: () async {
              final result = await OpenFilex.open(path);
              if (!mounted) return;
              if (result.type != ResultType.done) {
                _showCsvPreview(path, result.message);
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Xuất CSV thất bại: $e'),
        ),
      );
    }
  }

  String _csv(dynamic v) {
    final s = (v ?? '').toString();
    final escaped = s.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _showCsvPreview(String path, String? openError) async {
    try {
      final file = File(path);
      final lines = await file.readAsLines();
      final preview = lines.take(40).join('\n');
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không có app để mở CSV',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('Lý do: ${openError ?? 'No app found'}'),
                const SizedBox(height: 6),
                Text('File đã lưu tại: $path'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: path));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã copy đường dẫn file')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy đường dẫn'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Xem nhanh nội dung CSV:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        preview.isEmpty ? '(file rỗng)' : preview,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Không đọc được file CSV: $e'),
        ),
      );
    }
  }

  Widget _tile(String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color)),
        title: Text(title),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
