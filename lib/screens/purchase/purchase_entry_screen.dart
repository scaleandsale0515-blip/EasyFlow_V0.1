import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/purchase.dart';
import '../../services/hive_service.dart';
import '../../utils/helpers.dart';

class PurchaseEntryScreen extends StatefulWidget {
  final PurchaseEntry? existing;
  const PurchaseEntryScreen({super.key, this.existing});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  DateTime _date = DateTime.now();
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _date = e.date;
      _qtyCtrl.text = Fmt.qty(e.quantity);
      _rateCtrl.text = e.ratePerBag?.toString() ?? '';
      _supplierCtrl.text = e.supplierName ?? '';
      _notesCtrl.text = e.notes ?? '';
    }
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    final box = Hive.box<PurchaseEntry>(HiveBoxes.purchase);
    final rate = double.tryParse(_rateCtrl.text.trim());
    if (widget.existing == null) {
      await box.add(PurchaseEntry(
        id: newId(),
        date: _date,
        quantity: qty,
        ratePerBag: rate,
        supplierName: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    } else {
      final e = widget.existing!;
      e.date = _date;
      e.quantity = qty;
      e.ratePerBag = rate;
      e.supplierName = _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim();
      e.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      await e.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Purchase' : 'Edit Purchase')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20),
            title: Text(Fmt.date(_date)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (picked != null) setState(() => _date = picked);
              },
              child: const Text('Change'),
            ),
          ),
          const Text('Item: Cement Bags', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: _qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantity Purchased (bags) *')),
          const SizedBox(height: 12),
          TextField(controller: _rateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Rate per bag (₹, optional - for your reference)')),
          const SizedBox(height: 12),
          TextField(controller: _supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier / Vendor Name')),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Purchase Entry'))),
        ],
      ),
    );
  }
}
