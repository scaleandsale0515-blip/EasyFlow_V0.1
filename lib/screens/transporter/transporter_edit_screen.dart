import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/transporter.dart';
import '../../services/hive_service.dart';
import '../../utils/helpers.dart';

class TransporterEditScreen extends StatefulWidget {
  final Transporter? existing;
  const TransporterEditScreen({super.key, this.existing});

  @override
  State<TransporterEditScreen> createState() => _TransporterEditScreenState();
}

class _TransporterEditScreenState extends State<TransporterEditScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _nameCtrl.text = t.name;
      _phoneCtrl.text = t.phone ?? '';
      _notesCtrl.text = t.notes ?? '';
      _isActive = t.isActive;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final box = Hive.box<Transporter>(HiveBoxes.transporters);
    if (widget.existing == null) {
      await box.add(Transporter(
        id: newId(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        isActive: _isActive,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    } else {
      final t = widget.existing!;
      t.name = _nameCtrl.text.trim();
      t.phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
      t.isActive = _isActive;
      t.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      await t.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Transporter' : 'Edit Transporter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: const Text('Inactive transporters are hidden from new Transport entries', style: TextStyle(fontSize: 12)),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Transporter'))),
        ],
      ),
    );
  }
}
