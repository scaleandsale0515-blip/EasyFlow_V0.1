import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/production.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'production_entry_screen.dart';

enum _GroupMode { byDate, byWorker }

class ProductionListScreen extends StatefulWidget {
  const ProductionListScreen({super.key});

  @override
  State<ProductionListScreen> createState() => _ProductionListScreenState();
}

class _ProductionListScreenState extends State<ProductionListScreen> {
  _GroupMode _mode = _GroupMode.byDate;
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String _query = '';

  String _workerName(String id) {
    final box = Hive.box<Worker>(HiveBoxes.workers);
    try {
      return box.values.firstWhere((w) => w.id == id).name;
    } catch (_) {
      return '(deleted worker)';
    }
  }

  String _itemLabel(ProductionItemRow row) {
    try {
      final sub = ItemCatalogService.subcategories.values.firstWhere((s) => s.id == row.subcategoryId);
      final cat = ItemCatalogService.categories.values.firstWhere((c) => c.id == row.categoryId);
      return '${cat.name} - ${sub.name}';
    } catch (_) {
      return 'Item';
    }
  }

  void _delete(ProductionEntry e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) await e.delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production'),
        actions: [
          IconButton(
            icon: Icon(_mode == _GroupMode.byDate ? Icons.person_outline : Icons.calendar_today_outlined),
            tooltip: _mode == _GroupMode.byDate ? 'Group by Worker' : 'Group by Date',
            onPressed: () => setState(() => _mode = _mode == _GroupMode.byDate ? _GroupMode.byWorker : _GroupMode.byDate),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ProductionEntry>(HiveBoxes.production).listenable(),
        builder: (context, Box<ProductionEntry> box, _) {
          final range = _range;
          var entries = box.values.where((e) => range.contains(e.date)).toList();
          if (_query.isNotEmpty) {
            entries = entries.where((e) {
              final worker = _workerName(e.workerId).toLowerCase();
              return worker.contains(_query.toLowerCase());
            }).toList();
          }
          entries.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchBarWidget(hint: 'Search worker...', onChanged: (v) => setState(() => _query = v)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: entries.isEmpty
                    ? const EmptyState(icon: Icons.precision_manufacturing_outlined, message: 'No production entries in this period.')
                    : _mode == _GroupMode.byDate
                        ? _buildByDate(entries)
                        : _buildByWorker(entries),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductionEntryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildByDate(List<ProductionEntry> entries) {
    final Map<String, List<ProductionEntry>> grouped = {};
    for (final e in entries) {
      final key = Fmt.dayHeader(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.entries.map((g) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(g.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
            ),
            ...g.value.map((e) => _entryCard(e, showWorker: true)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildByWorker(List<ProductionEntry> entries) {
    final Map<String, List<ProductionEntry>> grouped = {};
    for (final e in entries) {
      final key = _workerName(e.workerId);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.entries.map((g) {
        final total = g.value.fold(0.0, (sum, e) => sum + e.totalAmount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(g.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                  Text(Fmt.money(total), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            ...g.value.map((e) => _entryCard(e, showWorker: false)),
          ],
        );
      }).toList(),
    );
  }

  Widget _entryCard(ProductionEntry e, {required bool showWorker}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(showWorker ? _workerName(e.workerId) : Fmt.dateShort(e.date)),
        subtitle: Text(
          e.items.map(_itemLabel).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.money(e.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductionEntryScreen(existing: e))),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.balanceRed),
                  onPressed: () => _delete(e),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
