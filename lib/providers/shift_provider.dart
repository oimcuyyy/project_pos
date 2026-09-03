import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/shift_model.dart';

class ShiftProvider with ChangeNotifier {
  CashShiftModel? _currentShift;
  List<CashShiftModel> _shiftHistory = [];
  bool _isLoading = false;

  CashShiftModel? get currentShift => _currentShift;
  bool get isShiftOpen => _currentShift != null && _currentShift!.status == 'open';
  List<CashShiftModel> get shiftHistory => List.unmodifiable(_shiftHistory);
  bool get isLoading => _isLoading;

  ShiftProvider() {
    checkActiveShift();
    fetchShiftHistory();
  }

  // Cek apakah ada shift yang sedang aktif
  Future<void> checkActiveShift() async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('cash_shifts').select().eq('status', 'open').order('opened_at', ascending: false).limit(1);

      if ((res as List).isNotEmpty) {
        _currentShift = CashShiftModel.fromMap(res.first);
      } else {
        _currentShift = null;
      }
    } catch (e) {
      debugPrint('Check active shift error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ambil Riwayat Semua Shift untuk Admin
  Future<void> fetchShiftHistory() async {
    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('cash_shifts').select().order('opened_at', ascending: false).limit(20);
      _shiftHistory = (res as List).map((s) => CashShiftModel.fromMap(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch shift history error: $e');
    }
  }

  // Buka Shift Kasir Baru
  Future<bool> openShift(String cashierName, double startingCash) async {
    final newShift = CashShiftModel(
      cashierName: cashierName,
      openedAt: DateTime.now(),
      startingCash: startingCash,
      status: 'open',
    );

    _currentShift = newShift;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('cash_shifts').insert(newShift.toMap()).select().single();
      _currentShift = CashShiftModel.fromMap(res);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Open shift error (using local state): $e');
      return true;
    }
  }

  // Catat Penjualan ke Shift Aktif
  Future<void> addSale(double amount, bool isCash) async {
    if (_currentShift == null) return;

    final newCashSales = isCash ? _currentShift!.cashSales + amount : _currentShift!.cashSales;
    final newNonCashSales = !isCash ? _currentShift!.nonCashSales + amount : _currentShift!.nonCashSales;

    _currentShift = CashShiftModel(
      id: _currentShift!.id,
      cashierName: _currentShift!.cashierName,
      openedAt: _currentShift!.openedAt,
      startingCash: _currentShift!.startingCash,
      cashSales: newCashSales,
      nonCashSales: newNonCashSales,
      pettyCashOut: _currentShift!.pettyCashOut,
      status: 'open',
    );
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      if (_currentShift?.id != null) {
        await supabase.from('cash_shifts').update({
          'cash_sales': newCashSales,
          'non_cash_sales': newNonCashSales,
        }).eq('id', _currentShift!.id!);
      }
    } catch (e) {
      debugPrint('Update shift sales error: $e');
    }
  }

  // Catat Kas Keluar / Petty Cash Toko
  Future<bool> recordPettyCash(double amount, String description) async {
    if (_currentShift == null) return false;

    final newPetty = _currentShift!.pettyCashOut + amount;
    _currentShift = CashShiftModel(
      id: _currentShift!.id,
      cashierName: _currentShift!.cashierName,
      openedAt: _currentShift!.openedAt,
      startingCash: _currentShift!.startingCash,
      cashSales: _currentShift!.cashSales,
      nonCashSales: _currentShift!.nonCashSales,
      pettyCashOut: newPetty,
      status: 'open',
    );
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      if (_currentShift?.id != null) {
        await supabase.from('cash_shifts').update({'petty_cash_out': newPetty}).eq('id', _currentShift!.id!);
        // Insert detail ke tabel expenses
        await supabase.from('expenses').insert({
          'shift_id': _currentShift!.id,
          'cashier_name': _currentShift!.cashierName,
          'description': description,
          'amount': amount,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Record petty cash error: $e');
      return true;
    }
  }

  // Tutup Shift / Rekapan Kasir
  Future<bool> closeShift(double actualCashEnd) async {
    if (_currentShift == null) return false;

    final expectedCash = _currentShift!.expectedCashEnd;
    final diff = actualCashEnd - expectedCash;
    final now = DateTime.now();

    final closedShift = CashShiftModel(
      id: _currentShift!.id,
      cashierName: _currentShift!.cashierName,
      openedAt: _currentShift!.openedAt,
      closedAt: now,
      startingCash: _currentShift!.startingCash,
      cashSales: _currentShift!.cashSales,
      nonCashSales: _currentShift!.nonCashSales,
      pettyCashOut: _currentShift!.pettyCashOut,
      actualCashEnd: actualCashEnd,
      difference: diff,
      status: 'closed',
    );

    final prevShift = _currentShift;
    _currentShift = null;
    _shiftHistory.insert(0, closedShift);
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      if (prevShift?.id != null) {
        await supabase.from('cash_shifts').update({
          'closed_at': now.toIso8601String(),
          'cash_sales': closedShift.cashSales,
          'non_cash_sales': closedShift.nonCashSales,
          'petty_cash_out': closedShift.pettyCashOut,
          'actual_cash_end': actualCashEnd,
          'difference': diff,
          'status': 'closed',
        }).eq('id', prevShift!.id!);
      }
      return true;
    } catch (e) {
      debugPrint('Close shift error (fallback local): $e');
      return true;
    }
  }
}
