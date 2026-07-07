import 'package:flutter/material.dart';
import '../../services/stock_service.dart';
import '../../utils/app_theme.dart';

class OpeningStockDialog extends StatelessWidget {
  const OpeningStockDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    if (StockService.openingStockConfigured) return;
    await Future.delayed(const Duration(seconds: 5));
    if (context.mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const OpeningStockDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return AlertDialog(
      title: const Text('Set Opening Cement Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your current Cement Stock to get started.\n\nExample: If you have 500 bags in stock today, enter 500 — the app will track all future usage and purchases from here.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Current stock (bags)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip for now')),
        ElevatedButton(
          onPressed: () async {
            final qty = double.tryParse(ctrl.text.trim()) ?? 0;
            await StockService.setOpeningStock(qty);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save & Continue'),
        ),
      ],
    );
  }
}
