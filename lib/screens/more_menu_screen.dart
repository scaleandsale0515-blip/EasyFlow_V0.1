import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'item_catalog/category_list_screen.dart';
import 'worker/worker_list_screen.dart';
import 'transporter/transporter_list_screen.dart';
import 'purchase/purchase_list_screen.dart';
import 'company/company_profile_screen.dart';
import 'backup/backup_restore_screen.dart';
import 'terms/terms_conditions_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(Icons.people_outline, 'Worker', 'Ledger + payments', const WorkerListScreen()),
      _MoreItem(Icons.category_outlined, 'Item Catalog', 'Category & Subcategory', const CategoryListScreen()),
      _MoreItem(Icons.local_shipping_outlined, 'Transporters', 'Ledger + payments', const TransporterListScreen()),
      _MoreItem(Icons.inventory_2_outlined, 'Purchase / Raw Material', 'Cement stock-in', const PurchaseListScreen()),
      _MoreItem(Icons.apartment_outlined, 'Company Profile', 'Business details', const CompanyProfileScreen()),
      _MoreItem(Icons.backup_outlined, 'Backup & Restore', 'Save / load app data', const BackupRestoreScreen()),
      _MoreItem(Icons.description_outlined, 'Terms & Conditions', 'App & support info', const TermsConditionsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              leading: Icon(item.icon, color: AppColors.accentCyan),
              title: Text(item.title),
              subtitle: Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
            ),
          );
        },
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
  _MoreItem(this.icon, this.title, this.subtitle, this.screen);
}
