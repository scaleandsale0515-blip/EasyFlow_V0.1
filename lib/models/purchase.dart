import 'package:hive_ce/hive.dart';

part 'purchase.g.dart';

/// Purely a stock-quantity tracker for Cement Bags (the only raw material
/// tracked in EasyFlow). Rate/Total are optional, informational only.
@HiveType(typeId: 12)
class PurchaseEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double quantity; // bags purchased

  @HiveField(3)
  double? ratePerBag; // optional, informational only

  @HiveField(4)
  String? supplierName;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  double? get totalAmount =>
      ratePerBag == null ? null : ratePerBag! * quantity;

  PurchaseEntry({
    required this.id,
    required this.date,
    required this.quantity,
    this.ratePerBag,
    this.supplierName,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
