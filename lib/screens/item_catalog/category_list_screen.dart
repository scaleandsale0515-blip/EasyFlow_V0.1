import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/item_catalog.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../services/stock_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'subcategory_list_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String _query = '';

  void _openAddEdit({ItemCategory? category}) {
    final ctrl = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name', hintText: 'e.g. Precast Panel'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              if (category == null) {
                await ItemCatalogService.categories.add(ItemCategory(id: newId(), name: name));
              } else {
                category.name = name;
                await category.save();
              }
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleActive(ItemCategory category) async {
    category.isActive = !category.isActive;
    await category.save();
    setState(() {});
  }

  void _delete(ItemCategory category) async {
    final used = ItemCatalogService.categoryUsedInProduction(category.id);
    if (used) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(
              'This category has been used in Production entries. Historical records depend on it, so it can\'t be deleted. You can mark it Inactive instead to hide it from new entries.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toggleActive(category);
              },
              child: const Text('Mark Inactive'),
            ),
          ],
        ),
      );
      return;
    }
    final subs = ItemCatalogService.subcategoriesFor(category.id);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('This will also delete ${subs.length} subcategor${subs.length == 1 ? 'y' : 'ies'} under it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      for (final s in subs) {
        await s.delete();
      }
      await category.delete();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Catalog')),
      body: ValueListenableBuilder(
        valueListenable: ItemCatalogService.categories.listenable(),
        builder: (context, Box<ItemCategory> box, _) {
          var categories = box.values.toList()..sort((a, b) => a.name.compareTo(b.name));
          if (_query.isNotEmpty) {
            categories = categories.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBarWidget(hint: 'Search category...', onChanged: (v) => setState(() => _query = v)),
              ),
              Expanded(
                child: categories.isEmpty
                    ? const EmptyState(icon: Icons.category_outlined, message: 'No categories yet.\nTap + to add one.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final cat = categories[i];
                          final subs = ItemCatalogService.subcategoriesFor(cat.id);
                          final subIds = subs.map((s) => s.id).toList();
                          final stock = StockService.categoryStock(cat.id, subIds);
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              title: Row(
                                children: [
                                  Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (!cat.isActive) ...[
                                    const SizedBox(width: 8),
                                    const Text('(Inactive)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ],
                              ),
                              subtitle: Text('${subs.length} subcategories · Stock: ${Fmt.qty(stock)}',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _openAddEdit(category: cat);
                                  if (v == 'toggle') _toggleActive(cat);
                                  if (v == 'delete') _delete(cat);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'toggle', child: Text(cat.isActive ? 'Mark Inactive' : 'Mark Active')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SubcategoryListScreen(category: cat)),
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
