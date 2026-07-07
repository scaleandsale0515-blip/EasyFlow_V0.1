import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/transporter.dart';
import '../../services/hive_service.dart';
import '../../services/ledger_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'transporter_ledger_screen.dart';
import 'transporter_edit_screen.dart';

class TransporterListScreen extends StatefulWidget {
  const TransporterListScreen({super.key});

  @override
  State<TransporterListScreen> createState() => _TransporterListScreenState();
}

class _TransporterListScreenState extends State<TransporterListScreen> {
  String _query = '';
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);

  bool _matchesQuery(Transporter t, List<LedgerLine> lines) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (t.name.toLowerCase().contains(q)) return true;
    if ((t.phone ?? '').contains(q)) return true;
    for (final l in lines) {
      if (Fmt.date(l.date).toLowerCase().contains(q)) return true;
      if (l.amount.abs().toStringAsFixed(0).contains(q)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transporters')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Transporter>(HiveBoxes.transporters).listenable(),
        builder: (context, Box<Transporter> box, _) {
          final range = _range;
          var transporters = box.values.toList()..sort((a, b) => a.name.compareTo(b.name));

          transporters = transporters.where((t) {
            final linesInRange = LedgerService.transporterLedgerLines(t.id).where((l) => range.contains(l.date)).toList();
            return _matchesQuery(t, linesInRange);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchBarWidget(hint: 'Search by name, phone, date, or amount...', onChanged: (v) => setState(() => _query = v)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: transporters.isEmpty
                    ? const EmptyState(icon: Icons.local_shipping_outlined, message: 'No transporters found.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transporters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final t = transporters[i];
                          final balance = LedgerService.transporterBalance(t.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceLight,
                                child: Text(t.name.isNotEmpty ? t.name[0].toUpperCase() : '?'),
                              ),
                              title: Row(
                                children: [
                                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (!t.isActive) ...[
                                    const SizedBox(width: 8),
                                    const Text('(Inactive)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ],
                              ),
                              subtitle: BalanceChip(balance: balance),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'toggle') {
                                    t.isActive = !t.isActive;
                                    await t.save();
                                    setState(() {});
                                  } else if (v == 'open') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => TransporterLedgerScreen(transporter: t)));
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'open', child: Text('Open Ledger')),
                                  PopupMenuItem(value: 'toggle', child: Text(t.isActive ? 'Mark Inactive' : 'Mark Active')),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransporterLedgerScreen(transporter: t))),
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransporterEditScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
