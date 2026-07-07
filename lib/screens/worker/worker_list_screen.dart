import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/ledger_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'worker_ledger_screen.dart';
import 'worker_edit_screen.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String _query = '';
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);

  /// Matches name, phone, any ledger entry date (e.g. "5 Jul"), or any
  /// ledger entry amount for this worker within the selected period.
  bool _matchesQuery(Worker w, List<LedgerLine> lines) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (w.name.toLowerCase().contains(q)) return true;
    if ((w.phone ?? '').contains(q)) return true;
    for (final l in lines) {
      if (Fmt.date(l.date).toLowerCase().contains(q)) return true;
      if (l.amount.abs().toStringAsFixed(0).contains(q)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workers')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Worker>(HiveBoxes.workers).listenable(),
        builder: (context, Box<Worker> box, _) {
          var workers = box.values.toList()..sort((a, b) => a.name.compareTo(b.name));

          workers = workers.where((w) {
            final linesInRange = LedgerService.workerLedgerLines(w.id).where((l) => _range.contains(l.date)).toList();
            return _matchesQuery(w, linesInRange);
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
                child: workers.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, message: 'No workers found.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: workers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final w = workers[i];
                          final balance = LedgerService.workerBalance(w.id);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceLight,
                                backgroundImage: w.photoPath != null ? FileImage(File(w.photoPath!)) : null,
                                child: w.photoPath == null ? Text(w.name.isNotEmpty ? w.name[0].toUpperCase() : '?') : null,
                              ),
                              title: Row(
                                children: [
                                  Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (!w.isActive) ...[
                                    const SizedBox(width: 8),
                                    const Text('(Inactive)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ],
                              ),
                              subtitle: BalanceChip(balance: balance),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'toggle') {
                                    w.isActive = !w.isActive;
                                    await w.save();
                                    setState(() {});
                                  } else if (v == 'open') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerLedgerScreen(worker: w)));
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'open', child: Text('Open Ledger')),
                                  PopupMenuItem(value: 'toggle', child: Text(w.isActive ? 'Mark Inactive' : 'Mark Active')),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerLedgerScreen(worker: w))),
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerEditScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
