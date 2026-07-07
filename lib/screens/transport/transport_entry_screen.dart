import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/item_catalog.dart';
import '../../models/transport.dart';
import '../../models/transporter.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

class TransportEntryScreen extends StatefulWidget {
  final TransportEntry? existing;
  const TransportEntryScreen({super.key, this.existing});

  @override
  State<TransportEntryScreen> createState() => _TransportEntryScreenState();
}

class _TRowData {
  bool isCement = false;
  String? categoryId;
  String? subcategoryId;
  double quantity = 0;
  bool reduceFromStock = true;
  final qtyCtrl = TextEditingController();
}

class _TransportEntryScreenState extends State<TransportEntryScreen> {
  DateTime _date = DateTime.now();
  String? _transporterId;
  final _transporterSearchCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  final _chargeCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final List<_TRowData> _rows = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _date = e.date;
      _transporterId = e.transporterId;
      final t = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere(
          (t) => t.id == e.transporterId,
          orElse: () => Transporter(id: '', name: '(deleted transporter)'));
      _transporterSearchCtrl.text = t.name;
      _vehicleTypeCtrl.text = e.vehicleType;
      _vehicleNoCtrl.text = e.vehicleNo;
      _chargeCtrl.text = e.transportCharge.toString();
      _notesCtrl.text = e.notes ?? '';
      for (final r in e.items) {
        final row = _TRowData()
          ..isCement = r.isCement
          ..categoryId = r.categoryId
          ..subcategoryId = r.subcategoryId
          ..quantity = r.quantity
          ..reduceFromStock = r.reduceFromStock;
        row.qtyCtrl.text = Fmt.qty(r.quantity);
        _rows.add(row);
      }
    } else {
      _rows.add(_TRowData());
    }
  }

  void _pickTransporter() async {
    final transporters = Hive.box<Transporter>(HiveBoxes.transporters).values.where((t) => t.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    String query = '';
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = query.isEmpty
              ? transporters
              : transporters.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SizedBox(
              height: 480,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search transporter...', prefixIcon: Icon(Icons.search)),
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
                  if (query.trim().isNotEmpty && !transporters.any((t) => t.name.toLowerCase() == query.trim().toLowerCase()))
                    ListTile(
                      leading: const Icon(Icons.add, color: AppColors.accentCyan),
                      title: Text('Add new transporter "$query"'),
                      onTap: () async {
                        final newT = Transporter(id: newId(), name: query.trim());
                        await Hive.box<Transporter>(HiveBoxes.transporters).add(newT);
                        if (ctx.mounted) Navigator.pop(ctx, newT.id);
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
      final t = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == result);
      setState(() {
        _transporterId = result;
        _transporterSearchCtrl.text = t.name;
        if (t.lastVehicleType != null) _vehicleTypeCtrl.text = t.lastVehicleType!;
        if (t.lastVehicleNo != null) _vehicleNoCtrl.text = t.lastVehicleNo!;
      });
    }
  }

  Future<void> _save() async {
    if (_transporterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a transporter')));
      return;
    }
    final validRows = _rows.where((r) => r.quantity > 0 && (r.isCement || r.subcategoryId != null)).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item row')));
      return;
    }
    final items = validRows
        .map((r) => TransportItemRow(
              isCement: r.isCement,
              categoryId: r.isCement ? null : r.categoryId,
              subcategoryId: r.isCement ? null : r.subcategoryId,
              quantity: r.quantity,
              reduceFromStock: r.reduceFromStock,
            ))
        .toList();

    // Remember vehicle details against this transporter for next time.
    final transporter = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == _transporterId);
    transporter.lastVehicleType = _vehicleTypeCtrl.text.trim();
    transporter.lastVehicleNo = _vehicleNoCtrl.text.trim();
    await transporter.save();

    final box = Hive.box<TransportEntry>(HiveBoxes.transport);
    if (widget.existing == null) {
      await box.add(TransportEntry(
        id: newId(),
        date: _date,
        transporterId: _transporterId!,
        vehicleType: _vehicleTypeCtrl.text.trim(),
        vehicleNo: _vehicleNoCtrl.text.trim(),
        items: items,
        transportCharge: double.tryParse(_chargeCtrl.text.trim()) ?? 0,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    } else {
      final e = widget.existing!;
      e.date = _date;
      e.transporterId = _transporterId!;
      e.vehicleType = _vehicleTypeCtrl.text.trim();
      e.vehicleNo = _vehicleNoCtrl.text.trim();
      e.items = items;
      e.transportCharge = double.tryParse(_chargeCtrl.text.trim()) ?? 0;
      e.notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      await e.save();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ItemCatalogService.categories.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Transport' : 'Edit Transport')),
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
          TextField(
            controller: _transporterSearchCtrl,
            readOnly: true,
            onTap: _pickTransporter,
            decoration: const InputDecoration(labelText: 'Transporter', prefixIcon: Icon(Icons.local_shipping_outlined)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _vehicleTypeCtrl, decoration: const InputDecoration(labelText: 'Vehicle Type'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _vehicleNoCtrl, decoration: const InputDecoration(labelText: 'Vehicle No.'))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Dispatch Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final subs = (row.isCement || row.categoryId == null) ? <ItemSubcategory>[] : ItemCatalogService.subcategoriesFor(row.categoryId!);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Product')),
                              ButtonSegment(value: true, label: Text('Cement Bags')),
                            ],
                            selected: {row.isCement},
                            onSelectionChanged: (v) => setState(() {
                              row.isCement = v.first;
                              row.categoryId = null;
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
                    if (!row.isCement) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: row.categoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        isExpanded: true,
                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() {
                          row.categoryId = v;
                          row.subcategoryId = null;
                        }),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: row.subcategoryId,
                        decoration: const InputDecoration(labelText: 'Subcategory / Size'),
                        isExpanded: true,
                        items: subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: row.categoryId == null ? null : (v) => setState(() => row.subcategoryId = v),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: row.qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: row.isCement ? 'Bags Qty' : 'Qty'),
                      onChanged: (v) => row.quantity = double.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Reduce from stock?', style: TextStyle(fontSize: 14)),
                      subtitle: !row.reduceFromStock
                          ? const Text('Borrowed / friend factory stock - won\'t affect your stock', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                          : null,
                      value: row.reduceFromStock,
                      onChanged: (v) => setState(() => row.reduceFromStock = v),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _rows.add(_TRowData())),
            icon: const Icon(Icons.add),
            label: const Text('Add another item'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _chargeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Transport Charge (₹, flat per trip)'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Save Transport Entry'))),
        ],
      ),
    );
  }
}
