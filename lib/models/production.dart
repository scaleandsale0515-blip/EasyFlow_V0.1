import 'package:hive_ce/hive.dart';

part 'production.g.dart';

/// A single item row inside a Production session.
/// Not a HiveObject itself - it's embedded inside ProductionEntry.
@HiveType(typeId: 8)
class ProductionItemRow {
  @HiveField(0)
  String categoryId;

  @HiveField(1)
  String subcategoryId;

  @HiveField(2)
  String unit; // auto-filled from subcategory, but editable per row

  @HiveField(3)
  double quantity;

  @HiveField(4)
  double rate; // auto-filled from subcategory default, editable

  double get amount => quantity * rate;

  ProductionItemRow({
    required this.categoryId,
    required this.subcategoryId,
    required this.unit,
    required this.quantity,
    required this.rate,
  });
}

@HiveType(typeId: 9)
class ProductionEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String workerId;

  @HiveField(3)
  List<ProductionItemRow> items;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  double cementBagsUsed; // entered once per session, total for the day

  @HiveField(6)
  DateTime createdAt;

  double get totalAmount => items.fold(0, (sum, r) => sum + r.amount);

  ProductionEntry({
    required this.id,
    required this.date,
    required this.workerId,
    required this.items,
    this.notes,
    this.cementBagsUsed = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
