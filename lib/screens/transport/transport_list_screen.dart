import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/transport.dart';
import '../../models/transporter.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'transport_entry_screen.dart';

enum _GroupMode { byDate, byTransporter }

class TransportListScreen extends StatefulWidget {
  const TransportListScreen({super.key});

  @override
  State<TransportListScreen> createState() => _TransportListScreenState();
}

class _TransportListScreenState extends State<TransportListScreen> {
  _GroupMode _mode = _GroupMode.byDate;
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String _query = '';

  String _transporterName(String id) {
    try {
      return Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == id).name;
    } catch (_) {
      return '(deleted transporter)';
    }
  }

  String _rowLabel(TransportItemRow r) {
    if (r.isCement) return 'Cement Bags';
    try {
      final sub = ItemCatalogService.subcategories.values.firstWhere((s) => s.id == r.subcategoryId);
      return sub.name;
    } catch (_) {
      return 'Item';
    }
  }

  void _delete(TransportEntry e) async {
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
        title: const Text('Transport'),
        actions: [
          IconButton(
            icon: Icon(_mode == _GroupMode.byDate ? Icons.local_shipping_outlined : Icons.calendar_today_outlined),
            tooltip: _mode == _GroupMode.byDate ? 'Group by Transporter' : 'Group by Date',
            onPressed: () => setState(() => _mode = _mode == _GroupMode.byDate ? _GroupMode.byTransporter : _GroupMode.byDate),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TransportEntry>(HiveBoxes.transport).listenable(),
        builder: (context, Box<TransportEntry> box, _) {
          final range = _range;
          var entries = box.values.where((e) => range.contains(e.date)).toList();
          if (_query.isNotEmpty) {
            entries = entries.where((e) => _transporterName(e.transporterId).toLowerCase().contains(_query.toLowerCase())).toList();
          }
          entries.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchBarWidget(hint: 'Search transporter...', onChanged: (v) => setState(() => _query = v)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: entries.isEmpty
                    ? const EmptyState(icon: Icons.local_shipping_outlined, message: 'No transport entries in this period.')
                    : _mode == _GroupMode.byDate
                        ? _buildByDate(entries)
                        : _buildByTransporter(entries),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportEntryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildByDate(List<TransportEntry> entries) {
    final Map<String, List<TransportEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(Fmt.dayHeader(e.date), () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.entries.map((g) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(g.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan))),
            ...g.value.map((e) => _entryCard(e, showTransporter: true)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildByTransporter(List<TransportEntry> entries) {
    final Map<String, List<TransportEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(_transporterName(e.transporterId), () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.entries.map((g) {
        final total = g.value.fold(0.0, (sum, e) => sum + e.transportCharge);
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
            ...g.value.map((e) => _entryCard(e, showTransporter: false)),
          ],
        );
      }).toList(),
    );
  }

  Widget _entryCard(TransportEntry e, {required bool showTransporter}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(showTransporter ? _transporterName(e.transporterId) : Fmt.dateShort(e.date)),
        subtitle: Text(
          '${e.vehicleType} ${e.vehicleNo} · ${e.items.map(_rowLabel).join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.money(e.transportCharge), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransportEntryScreen(existing: e)))),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.balanceRed), onPressed: () => _delete(e)),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
