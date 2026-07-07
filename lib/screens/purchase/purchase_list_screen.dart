import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/purchase.dart';
import '../../models/app_settings.dart';
import '../../services/hive_service.dart';
import '../../services/stock_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'purchase_entry_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String _query = '';

  void _editThreshold() {
    final settings = Hive.box<AppSettings>(HiveBoxes.appSettings).getAt(0)!;
    final ctrl = TextEditingController(text: Fmt.qty(settings.lowStockThreshold));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Low Stock Alert Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You\'ll see a warning on the Dashboard when cement stock falls to or below this number.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bags')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val >= 0) {
                settings.lowStockThreshold = val;
                await settings.save();
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

  void _delete(PurchaseEntry e) async {
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
        title: const Text('Purchase / Raw Material'),
        actions: [
          IconButton(icon: const Icon(Icons.tune), tooltip: 'Low stock threshold', onPressed: _editThreshold),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<PurchaseEntry>(HiveBoxes.purchase).listenable(),
        builder: (context, Box<PurchaseEntry> box, _) {
          final range = _range;
          var entries = box.values.where((e) => range.contains(e.date)).toList();
          if (_query.isNotEmpty) {
            entries = entries.where((e) => (e.supplierName ?? '').toLowerCase().contains(_query.toLowerCase())).toList();
          }
          entries.sort((a, b) => b.date.compareTo(a.date));
          final currentStock = StockService.currentCementStock();

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Cement Stock', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${Fmt.qty(currentStock)} bags', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Today\'s Usage', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${Fmt.qty(StockService.todayCementUsage())} bags', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBarWidget(hint: 'Search supplier...', onChanged: (v) => setState(() => _query = v)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: entries.isEmpty
                    ? const EmptyState(icon: Icons.inventory_2_outlined, message: 'No purchase entries in this period.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          return Card(
                            child: ListTile(
                              title: Text('${Fmt.qty(e.quantity)} bags purchased'),
                              subtitle: Text(
                                [
                                  Fmt.date(e.date),
                                  if (e.supplierName != null) e.supplierName!,
                                  if (e.ratePerBag != null) '@ ${Fmt.money(e.ratePerBag!)}/bag',
                                ].join(' · '),
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseEntryScreen(existing: e)))),
                                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.balanceRed), onPressed: () => _delete(e)),
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseEntryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
