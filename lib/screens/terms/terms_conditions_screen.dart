import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'EasyFlow is provided as a factory workflow management tool for internal use. '
            'All production, transport, worker, and stock data entered in this app is stored locally on your device. '
            'It is your responsibility to take regular backups using the Backup & Restore feature to avoid data loss.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 20),
          const Text('App & Support Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.person_outline, label: 'Developer', value: 'Mr. Rutik Parmar'),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Support Email',
            value: 'scaleandsale0515@gmail.com',
            onTap: () => launchUrl(Uri.parse('mailto:scaleandsale0515@gmail.com')),
          ),
          const SizedBox(height: 14),
          const _InfoRow(icon: Icons.location_on_outlined, label: 'Business Address', value: 'Ahmedabad, Gujarat, 382350, India'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentCyan),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: TextStyle(color: onTap != null ? AppColors.accentCyan : AppColors.textPrimary, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
