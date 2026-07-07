import 'package:hive_ce/hive.dart';

part 'item_catalog.g.dart';

@HiveType(typeId: 1)
class ItemCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  DateTime createdAt;

  ItemCategory({
    required this.id,
    required this.name,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 2)
class ItemSubcategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String unit; // e.g. "Nos", "RFT", "Sqft", or custom text

  @HiveField(4)
  double defaultRate;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime createdAt;

  ItemSubcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
    this.defaultRate = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Stores custom units typed by the user (e.g. "Cum", "Kg") so they appear
/// as suggestions next time, in Item Catalog or during Production entry.
@HiveType(typeId: 3)
class CustomUnit extends HiveObject {
  @HiveField(0)
  String name;

  CustomUnit({required this.name});
}
