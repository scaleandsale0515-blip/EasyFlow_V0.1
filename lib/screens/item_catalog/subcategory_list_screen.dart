import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/item_catalog.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../services/stock_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SubcategoryListScreen extends StatefulWidget {
  final ItemCategory category;
  const SubcategoryListScreen({super.key, required this.category});

  @override
  State<SubcategoryListScreen> createState() => _SubcategoryListScreenState();
}

class _SubcategoryListScreenState extends State<SubcategoryListScreen> {
  String _query = '';

  void _openAddEdit({ItemSubcategory? sub}) {
    final nameCtrl = TextEditingController(text: sub?.name ?? '');
    final rateCtrl = TextEditingController(text: sub?.defaultRate.toString() ?? '');
    String selectedUnit = sub?.unit ?? 'Nos';
    bool showCustom = !ItemCatalogService.unitSuggestions.contains(selectedUnit);
    final customUnitCtrl = TextEditingController(text: showCustom ? selectedUnit : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(sub == null ? 'Add Subcategory' : 'Edit Subcategory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name / Size', hintText: 'e.g. Plain (6 feet)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: showCustom ? 'Custom' : selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    ...ItemCatalogService.unitSuggestions.map((u) => DropdownMenuItem(value: u, child: Text(u))),
                    const DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
                  ],
                  onChanged: (v) {
                    setDialogState(() {
                      if (v == 'Custom') {
                        showCustom = true;
                      } else {
                        showCustom = false;
                        selectedUnit = v!;
                      }
                    });
                  },
                ),
                if (showCustom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customUnitCtrl,
                    decoration: const InputDecoration(labelText: 'Custom unit', hintText: 'e.g. Cum, Kg'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Default Rate per piece (₹)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final unit = showCustom ? customUnitCtrl.text.trim() : selectedUnit;
                if (unit.isEmpty) return;
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
                if (showCustom) await ItemCatalogService.addCustomUnitIfNew(unit);

                if (sub == null) {
                  await ItemCatalogService.subcategories.add(ItemSubcategory(
                    id: newId(),
                    categoryId: widget.category.id,
                    name: name,
                    unit: unit,
                    defaultRate: rate,
                  ));
                } else {
                  sub.name = name;
                  sub.unit = unit;
                  sub.defaultRate = rate;
                  await sub.save();
                }
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleActive(ItemSubcategory sub) async {
    sub.isActive = !sub.isActive;
    await sub.save();
    setState(() {});
  }

  void _delete(ItemSubcategory sub) async {
    final used = ItemCatalogService.subcategoryUsedInProduction(sub.id);
    if (used) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(
              'This subcategory has been used in Production entries. Historical records depend on it, so it can\'t be deleted. You can mark it Inactive instead.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toggleActive(sub);
              },
              child: const Text('Mark Inactive'),
            ),
          ],
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subcategory?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await sub.delete();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ValueListenableBuilder(
        valueListenable: ItemCatalogService.subcategories.listenable(),
        builder: (context, Box<ItemSubcategory> box, _) {
          var subs = box.values.where((s) => s.categoryId == widget.category.id).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (_query.isNotEmpty) {
            subs = subs.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBarWidget(hint: 'Search subcategory...', onChanged: (v) => setState(() => _query = v)),
              ),
              Expanded(
                child: subs.isEmpty
                    ? const EmptyState(icon: Icons.list_alt, message: 'No subcategories yet.\nTap + to add one.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: subs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final sub = subs[i];
                          final stock = StockService.subcategoryStock(sub.id);
                          return Card(
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (!sub.isActive) ...[
                                    const SizedBox(width: 8),
                                    const Text('(Inactive)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                'Unit: ${sub.unit} · Rate: ${Fmt.money(sub.defaultRate)} · Stock: ${Fmt.qty(stock)}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _openAddEdit(sub: sub);
                                  if (v == 'toggle') _toggleActive(sub);
                                  if (v == 'delete') _delete(sub);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'toggle', child: Text(sub.isActive ? 'Mark Inactive' : 'Mark Active')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
