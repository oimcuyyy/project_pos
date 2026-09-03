import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _exportToCsv(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diekspor')));
      return;
    }

    // Manual CSV generation
    final buffer = StringBuffer();
    // Header
    buffer.writeln('ID Transaksi;Tanggal;Waktu;Kasir;Pelanggan;Metode Bayar;Total Omzet;Laba Kotor');
    
    for (var tx in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(tx.dateTime);
      final time = DateFormat('HH:mm').format(tx.dateTime);
      buffer.writeln('${tx.id};$date;$time;${tx.cashierName};${tx.customerName ?? "Umum"};${tx.paymentMethod.name};${tx.totalAmount};${tx.grossProfit}');
    }

    final csvString = buffer.toString();
    final bytes = utf8.encode(csvString);

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'Laporan_Penjualan_${DateFormat('yyyyMMdd').format(_startDate)}.csv';
      html.document.body!.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      // Fallback for desktop/mobile
      Clipboard.setData(ClipboardData(text: csvString));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data CSV disalin ke Clipboard! (Bisa dipaste di Excel)')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil didownload!')));
  }

  @override
  Widget build(BuildContext context) {
    final txProv = context.watch<TransactionProvider>();
    
    // Filter transactions by date range
    final filteredTx = txProv.transactions.where((t) {
      // normalize dates to start of day and end of day
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59, 999);
      return !t.dateTime.isBefore(start) && !t.dateTime.isAfter(end);
    }).toList();

    final totalRevenue = filteredTx.fold(0.0, (sum, t) => sum + t.totalAmount);
    final totalProfit = filteredTx.fold(0.0, (sum, t) => sum + t.grossProfit);

    return RefreshIndicator(
      onRefresh: () => txProv.fetchTransactions(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Periode Laporan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Ubah Tanggal'),
                  onPressed: _pickDateRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Omzet (Kotor)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        _currency.format(totalRevenue),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Laba (Bersih)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        _currency.format(totalProfit),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.table_view_rounded),
              label: const Text('Download Laporan Excel (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _exportToCsv(filteredTx),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Rincian Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          
          ...filteredTx.map((tx) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                child: const Icon(Icons.receipt_long, color: Color(0xFF4F46E5), size: 20),
              ),
              title: Text(tx.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(tx.dateTime), style: const TextStyle(fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currency.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(tx.paymentMethod.name.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          )),
          
          if (filteredTx.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Tidak ada transaksi di rentang tanggal ini.', style: TextStyle(color: Colors.grey)),
              ),
            )
        ],
      ),
    );
  }
}
