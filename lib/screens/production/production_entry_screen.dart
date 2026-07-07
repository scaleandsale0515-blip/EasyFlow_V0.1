import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/item_catalog.dart';
import '../../models/production.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

class ProductionEntryScreen extends StatefulWidget {
  final ProductionEntry? existing;
  const ProductionEntryScreen({super.key, this.existing});

  @override
  State<ProductionEntryScreen> createState() => _ProductionEntryScreenState();
}

class _RowData {
  String? categoryId;
  String? subcategoryId;
  String unit = '';
  double quantity = 0;
  double rate = 0;
  final qtyCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
}

class _ProductionEntryScreenState extends State<ProductionEntryScreen> {
  DateTime _date = DateTime.now();
  String? _workerId;
  final _workerSearchCtrl = TextEditingController();
  final _cementCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final List<_RowData> _rows = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _date = e.date;
      _workerId = e.workerId;
      final w = Hive.box<Worker>(HiveBoxes.workers).values.firstWhere((w) => w.id == e.workerId,
          orElse: () => Worker(id: '', name: '(deleted worker)'));
      _workerSearchCtrl.text = w.name;
      _cementCtrl.text = Fmt.qty(e.cementBagsUsed);
      _notesCtrl.text = e.notes ?? '';
      for (final r in e.items) {
        final row = _RowData()
          ..categoryId = r.categoryId
          ..subcategoryId = r.subcategoryId
          ..unit = r.unit
          ..quantity = r.quantity
          ..rate = r.rate;
        row.qtyCtrl.text = Fmt.qty(r.quantity);
        row.rateCtrl.text = r.rate.toString();
        row.unitCtrl.text = r.unit;
        _rows.add(row);
      }
    } else {
      _rows.add(_RowData());
    }
  }

  void _pickWorker() async {
    final workers = Hive.box<Worker>(HiveBoxes.workers).values.where((w) => w.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    String query = '';
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = query.isEmpty
              ? workers
              : workers.where((w) => w.name.toLowerCase().contains(query.toLowerCase())).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SizedBox(
              height: 480,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search worker...', prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(filtered[i].name),
                        onTap: () => Navigator.pop(ctx, filtered[i].id),
                      ),
                    ),
                  ),
                  if (query.trim().isNotEmpty && !workers.any((w) => w.name.toLowerCase() == query.trim().toLowerCase()))
                    ListTile(
                      leading: const Icon(Icons.add, color: AppColors.accentCyan),
                      title: Text('Add new worker "$query"'),
                      onTap: () async {
                        final newWorker = Worker(id: newId(), name: query.trim());
                        await Hive.box<Worker>(HiveBoxes.workers).add(newWorker);
                        if (ctx.mounted) Navigator.pop(ctx, newWorker.id);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      final w = Hive.box<Worker>(HiveBoxes.workers).values.firstWhere((w) => w.id == result);
      setState(() {
        _workerId = result;
        _workerSearchCtrl.text = w.name;
      });
    }
  }

  void _onSubcategoryChanged(_RowData row, ItemSubcategory sub) {
    setState(() {
      row.subcategoryId = sub.id;
      row.unit = sub.unit;
      row.unitCtrl.text = sub.unit;
      row.rate = sub.defaultRate;
      row.rateCtrl.text = sub.defaultRate.toString();
    });
  }

  double get _totalAmount => _rows.fold(0, (sum, r) => sum + (r.quantity * r.rate));

  Future<void> _save() async {
    if (_workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a worker')));
      return;
    }
    final validRows = _rows.where((r) => r.categoryId != null && r.subcategoryId != null && r.quantity > 0).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item row')));
      return;
    }
    final items = validRows
        .map((r) => ProductionItemRow(
              categoryId: r.categoryId!,
              subcategoryId: r.subcategoryId!,
              unit: r.unit,
              quantity: r.quantity,
              rate: r.rate,
            ))
        .toList();
    for (final r in validRows) {
      if (r.unit.trim().isNotEmpty) await ItemCatalogService.addCustomUnitIfNew(r.unit.trim());
    }

    final box = Hive.box<ProductionEntry>(HiveBoxes.production);
    if (widget.existing == null) {
      await box.add(ProductionEntry(
        id: newId(),
        date: _date,
        workerId: _workerId!,
        items: items,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        cementBagsUsed: double.tryParse(_cementCtrl.text.trim()) ?? 0,
      ));
    } else {
      final e = widget.existing!;
      e.date = _date;
      e.workerId = _workerId!;
      e.items = items;
      e.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      e.cementBagsUsed = double.tryParse(_cementCtrl.text.trim()) ?? 0;
      await e.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ItemCatalogService.categories.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Production' : 'Edit Production')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20),
            title: Text(Fmt.date(_date)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: const Text('Change'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _workerSearchCtrl,
            readOnly: true,
            onTap: _pickWorker,
            decoration: const InputDecoration(labelText: 'Worker', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          const Text('Items Produced', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final subs = row.categoryId == null ? <ItemSubcategory>[] : ItemCatalogService.subcategoriesFor(row.categoryId!).where((s) => s.isActive).toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: row.categoryId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            isExpanded: true,
                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() {
                              row.categoryId = v;
                              row.subcategoryId = null;
                            }),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.balanceRed),
                          onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: row.subcategoryId,
                      decoration: const InputDecoration(labelText: 'Subcategory / Size'),
                      isExpanded: true,
                      items: subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: row.categoryId == null
                          ? null
                          : (v) {
                              final sub = subs.firstWhere((s) => s.id == v);
                              _onSubcategoryChanged(row, sub);
                            },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: row.unitCtrl,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            onChanged: (v) => row.unit = v,
                            onSubmitted: (v) async {
                              if (v.trim().isNotEmpty) await ItemCatalogService.addCustomUnitIfNew(v.trim());
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: row.qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Qty'),
                            onChanged: (v) => row.quantity = double.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: row.rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Rate/pc (₹)'),
                      onChanged: (v) => setState(() => row.rate = double.tryParse(v) ?? 0),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('= ${Fmt.money(row.quantity * row.rate)}',
                          style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _rows.add(_RowData())),
            icon: const Icon(Icons.add),
            label: const Text('Add another item'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cementCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cement Bags Used (today, total)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(Fmt.money(_totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accentCyan)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Production Entry'))),
        ],
      ),
    );
  }
}
