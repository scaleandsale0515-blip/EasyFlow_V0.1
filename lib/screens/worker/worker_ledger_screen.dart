import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/ledger_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'worker_edit_screen.dart';

class WorkerLedgerScreen extends StatefulWidget {
  final Worker worker;
  const WorkerLedgerScreen({super.key, required this.worker});

  @override
  State<WorkerLedgerScreen> createState() => _WorkerLedgerScreenState();
}

class _WorkerLedgerScreenState extends State<WorkerLedgerScreen> {
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String _query = '';

  void _addPayment({WorkerPayment? existing}) {
    DateTime date = existing?.date ?? DateTime.now();
    final amountCtrl = TextEditingController(text: existing?.amount.toString() ?? '');
    String mode = existing?.mode ?? 'Cash';
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'Add Payment' : 'Edit Payment', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Fmt.date(date)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setModalState(() => date = picked);
                  },
                  child: const Text('Change'),
                ),
              ),
              TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: ['Cash', 'Bank', 'UPI', 'Other'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setModalState(() => mode = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    final box = Hive.box<WorkerPayment>(HiveBoxes.workerPayments);
                    if (existing == null) {
                      await box.add(WorkerPayment(
                        id: newId(),
                        workerId: widget.worker.id,
                        date: date,
                        amount: amount,
                        mode: mode,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      ));
                    } else {
                      existing.date = date;
                      existing.amount = amount;
                      existing.mode = mode;
                      existing.notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                      await existing.save();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Payment')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _deletePayment(String paymentId) async {
    final box = Hive.box<WorkerPayment>(HiveBoxes.workerPayments);
    final payment = box.values.firstWhere((p) => p.id == paymentId);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await payment.delete();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = LedgerService.workerBalance(widget.worker.id);
    final range = _range;
    var lines = LedgerService.workerLedgerLines(widget.worker.id).where((l) => range.contains(l.date)).toList();
    if (_query.isNotEmpty) {
      lines = lines.where((l) => l.description.toLowerCase().contains(_query.toLowerCase())).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerEditScreen(existing: widget.worker)))),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: widget.worker.photoPath != null ? FileImage(File(widget.worker.photoPath!)) : null,
                  child: widget.worker.photoPath == null ? Text(widget.worker.name.isNotEmpty ? widget.worker.name[0].toUpperCase() : '?') : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.worker.phone != null) Text(widget.worker.phone!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      BalanceChip(balance: balance, fontSize: 17),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBarWidget(hint: 'Search entries...', onChanged: (v) => setState(() => _query = v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DateFilterBar(onRangeChanged: (r) => setState(() => _range = r)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: lines.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, message: 'No ledger entries in this period.')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final l = lines[i];
                      final isPositive = l.amount >= 0;
                      return Card(
                        child: ListTile(
                          title: Text(l.description),
                          subtitle: Text(Fmt.date(l.date), style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: l.isPayment
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(Fmt.money(l.amount.abs()), style: const TextStyle(color: AppColors.balanceRed, fontWeight: FontWeight.w600)),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () {
                                        final p = Hive.box<WorkerPayment>(HiveBoxes.workerPayments).values.firstWhere((p) => p.id == l.sourceId);
                                        _addPayment(existing: p);
                                      },
                                    ),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.balanceRed), onPressed: () => _deletePayment(l.sourceId!)),
                                  ],
                                )
                              : Text('+${Fmt.money(l.amount)}', style: TextStyle(color: isPositive ? AppColors.balanceGreen : AppColors.balanceRed, fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPayment(),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
    );
  }
}
