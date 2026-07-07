import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/item_catalog.dart';
import '../models/production.dart';
import 'hive_service.dart';

class ItemCatalogService {
  static Box<ItemCategory> get categories => Hive.box<ItemCategory>(HiveBoxes.categories);
  static Box<ItemSubcategory> get subcategories => Hive.box<ItemSubcategory>(HiveBoxes.subcategories);
  static Box<CustomUnit> get customUnits => Hive.box<CustomUnit>(HiveBoxes.customUnits);
  static Box<ProductionEntry> get _production => Hive.box<ProductionEntry>(HiveBoxes.production);

  static List<ItemSubcategory> subcategoriesFor(String categoryId) {
    return subcategories.values.where((s) => s.categoryId == categoryId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static bool categoryUsedInProduction(String categoryId) {
    return _production.values.any((p) => p.items.any((r) => r.categoryId == categoryId));
  }

  static bool subcategoryUsedInProduction(String subcategoryId) {
    return _production.values.any((p) => p.items.any((r) => r.subcategoryId == subcategoryId));
  }

  static Future<void> addCustomUnitIfNew(String unit) async {
    final exists = customUnits.values.any((u) => u.name.toLowerCase() == unit.toLowerCase());
    if (!exists && unit.trim().isNotEmpty) {
      await customUnits.add(CustomUnit(name: unit.trim()));
    }
  }

  static List<String> get unitSuggestions {
    const base = ['Nos', 'RFT', 'Sqft'];
    final custom = customUnits.values.map((u) => u.name).toList();
    return [...base, ...custom];
  }
}
