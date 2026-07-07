import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/image_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

class WorkerEditScreen extends StatefulWidget {
  final Worker? existing;
  const WorkerEditScreen({super.key, this.existing});

  @override
  State<WorkerEditScreen> createState() => _WorkerEditScreenState();
}

class _WorkerEditScreenState extends State<WorkerEditScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _photoPath;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    if (w != null) {
      _nameCtrl.text = w.name;
      _phoneCtrl.text = w.phone ?? '';
      _addressCtrl.text = w.address ?? '';
      _notesCtrl.text = w.notes ?? '';
      _photoPath = w.photoPath;
      _isActive = w.isActive;
    }
  }

  Future<void> _pickPhoto() async {
    final path = await ImageService.pickAndCompress(folder: 'worker_photos');
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final box = Hive.box<Worker>(HiveBoxes.workers);
    if (widget.existing == null) {
      await box.add(Worker(
        id: newId(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        photoPath: _photoPath,
        isActive: _isActive,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    } else {
      final w = widget.existing!;
      w.name = _nameCtrl.text.trim();
      w.phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
      w.address = _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();
      w.photoPath = _photoPath;
      w.isActive = _isActive;
      w.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      await w.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Worker' : 'Edit Worker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                child: _photoPath == null ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary) : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: const Text('Inactive workers are hidden from new Production entries', style: TextStyle(fontSize: 12)),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Worker'))),
        ],
      ),
    );
  }
}
