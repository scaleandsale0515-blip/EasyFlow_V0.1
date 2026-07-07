import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/production.dart';
import '../models/transport.dart';
import '../models/purchase.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';
import 'auth_service.dart';

class StockService {
  static Box<ProductionEntry> get _production =>
      Hive.box<ProductionEntry>(HiveBoxes.production);
  static Box<TransportEntry> get _transport =>
      Hive.box<TransportEntry>(HiveBoxes.transport);
  static Box<PurchaseEntry> get _purchase =>
      Hive.box<PurchaseEntry>(HiveBoxes.purchase);

  // ---------------- Item-wise product stock ----------------

  /// Current stock for a given subcategory =
  /// total produced - total dispatched (where reduceFromStock == true)
  static double subcategoryStock(String subcategoryId) {
    double produced = 0;
    for (final entry in _production.values) {
      for (final row in entry.items) {
        if (row.subcategoryId == subcategoryId) produced += row.quantity;
      }
    }
    double dispatched = 0;
    for (final entry in _transport.values) {
      for (final row in entry.items) {
        if (!row.isCement &&
            row.subcategoryId == subcategoryId &&
            row.reduceFromStock) {
          dispatched += row.quantity;
        }
      }
    }
    return produced - dispatched;
  }

  /// Total stock across all subcategories under one category.
  static double categoryStock(String categoryId, List<String> subcategoryIds) {
    return subcategoryIds.fold(0.0, (sum, id) => sum + subcategoryStock(id));
  }

  // ---------------- Cement stock (live running ledger) ----------------

  static double get openingCementStock => AuthService.settings.openingCementStock;

  static double totalCementPurchased() {
    return _purchase.values.fold(0.0, (sum, p) => sum + p.quantity);
  }

  static double totalCementUsed() {
    return _production.values.fold(0.0, (sum, p) => sum + p.cementBagsUsed);
  }

  /// Also accounts for cement bags dispatched via Transport (if toggled to
  /// reduce stock), since a trip can carry cement bags out too.
  static double totalCementDispatched() {
    double dispatched = 0;
    for (final entry in _transport.values) {
      for (final row in entry.items) {
        if (row.isCement && row.reduceFromStock) {
          dispatched += row.quantity;
        }
      }
    }
    return dispatched;
  }

  static double currentCementStock() {
    return openingCementStock +
        totalCementPurchased() -
        totalCementUsed() -
        totalCementDispatched();
  }

  static double todayCementUsage() {
    final today = DateTime.now();
    return _production.values
        .where((p) =>
            p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day)
        .fold(0.0, (sum, p) => sum + p.cementBagsUsed);
  }

  static bool isLowStock() {
    return currentCementStock() <= AuthService.settings.lowStockThreshold;
  }

  static Future<void> setOpeningStock(double qty) async {
    final s = AuthService.settings;
    s.openingCementStock = qty;
    s.openingStockSet = true;
    await s.save();
  }

  static bool get openingStockConfigured => AuthService.settings.openingStockSet;
}
