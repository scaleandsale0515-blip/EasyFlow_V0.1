import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/company_profile.dart';
import '../../services/hive_service.dart';
import '../../services/image_service.dart';
import '../../utils/app_theme.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  late CompanyProfile _profile;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    final box = Hive.box<CompanyProfile>(HiveBoxes.companyProfile);
    if (box.isEmpty) {
      box.add(CompanyProfile());
    }
    _profile = box.getAt(0)!;
    _nameCtrl.text = _profile.companyName;
    _phoneCtrl.text = _profile.phone ?? '';
    _emailCtrl.text = _profile.email ?? '';
    _addressCtrl.text = _profile.address ?? '';
    _logoPath = _profile.logoPath;
  }

  Future<void> _pickLogo() async {
    final path = await ImageService.pickAndCompress(folder: 'company_logo');
    if (path != null) setState(() => _logoPath = path);
  }

  Future<void> _save() async {
    _profile.companyName = _nameCtrl.text.trim();
    _profile.phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    _profile.email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
    _profile.address = _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();
    _profile.logoPath = _logoPath;
    await _profile.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company profile saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: _logoPath != null ? FileImage(File(_logoPath!)) : null,
                child: _logoPath == null ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 28) : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Tap to set logo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save'))),
        ],
      ),
    );
  }
}
