import 'package:hive_ce/hive.dart';

part 'transport.g.dart';

/// A single dispatched row - either a catalog product OR cement bags.
@HiveType(typeId: 10)
class TransportItemRow {
  @HiveField(0)
  bool isCement; // true = this row is "Cement Bags", false = catalog product

  @HiveField(1)
  String? categoryId; // null if isCement

  @HiveField(2)
  String? subcategoryId; // null if isCement

  @HiveField(3)
  double quantity;

  @HiveField(4)
  bool reduceFromStock; // default true; false = borrowed/friend-factory stock

  TransportItemRow({
    this.isCement = false,
    this.categoryId,
    this.subcategoryId,
    required this.quantity,
    this.reduceFromStock = true,
  });
}

@HiveType(typeId: 11)
class TransportEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String transporterId;

  @HiveField(3)
  String vehicleType;

  @HiveField(4)
  String vehicleNo;

  @HiveField(5)
  List<TransportItemRow> items;

  @HiveField(6)
  double transportCharge; // flat fee per trip

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  TransportEntry({
    required this.id,
    required this.date,
    required this.transporterId,
    required this.vehicleType,
    required this.vehicleNo,
    required this.items,
    this.transportCharge = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
