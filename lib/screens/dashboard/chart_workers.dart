import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/production.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class WorkerChart extends StatefulWidget {
  const WorkerChart({super.key});

  @override
  State<WorkerChart> createState() => _WorkerChartState();
}

class _WorkerChartState extends State<WorkerChart> {
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);
  String? _workerId;
  int? _selectedDayIndex;

  String _itemLabel(ProductionItemRow row) {
    try {
      final sub = ItemCatalogService.subcategories.values.firstWhere((s) => s.id == row.subcategoryId);
      final cat = ItemCatalogService.categories.values.firstWhere((c) => c.id == row.categoryId);
      return '${cat.name} - ${sub.name} (${Fmt.qty(row.quantity)} ${row.unit})';
    } catch (_) {
      return 'Item (${Fmt.qty(row.quantity)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = Hive.box<Worker>(HiveBoxes.workers).values.toList()..sort((a, b) => a.name.compareTo(b.name));
    if (workers.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('No workers added yet.', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    _workerId ??= workers.first.id;
    final range = _range;
    final entries = Hive.box<ProductionEntry>(HiveBoxes.production).values
        .where((e) => e.workerId == _workerId && range.contains(e.date))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final Map<String, List<ProductionEntry>> byDay = {};
    for (final e in entries) {
      final key = Fmt.dateShort(e.date);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final dayKeys = byDay.keys.toList();
    final dayTotals = dayKeys.map((k) => byDay[k]!.fold(0.0, (sum, e) => sum + e.totalAmount)).toList();

    final displayIndex = _selectedDayIndex != null && _selectedDayIndex! < dayKeys.length ? _selectedDayIndex! : null;
    final entriesToShow = displayIndex != null ? byDay[dayKeys[displayIndex]]! : entries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Worker Production', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _workerId,
              decoration: const InputDecoration(labelText: 'Worker', isDense: true),
              items: workers.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
              onChanged: (v) => setState(() {
                _workerId = v;
                _selectedDayIndex = null;
              }),
            ),
            const SizedBox(height: 10),
            DateFilterBar(
              initial: DateRangeFilter.thisMonth,
              options: const [DateRangeFilter.thisMonth, DateRangeFilter.thisQuarter, DateRangeFilter.thisYear, DateRangeFilter.custom],
              onRangeChanged: (r) => setState(() {
                _range = r;
                _selectedDayIndex = null;
              }),
            ),
            const SizedBox(height: 16),
            if (dayKeys.isEmpty)
              const SizedBox(height: 120, child: Center(child: Text('No production in this period', style: TextStyle(color: AppColors.textSecondary))))
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      touchCallback: (event, response) {
                        if (event.isInterestedForInteractions && response?.spot != null) {
                          setState(() => _selectedDayIndex = response!.spot!.touchedBarGroupIndex);
                        }
                      },
                    ),
                    barGroups: dayTotals.asMap().entries.map((entry) {
                      final isSelected = entry.key == displayIndex;
                      return BarChartGroupData(x: entry.key, barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: isSelected ? AppColors.warningAmber : AppColors.primaryBlue,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ]);
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= dayKeys.length) return const SizedBox();
                            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(dayKeys[i], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (displayIndex != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dayKeys[displayIndex], style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentCyan)),
                  TextButton(onPressed: () => setState(() => _selectedDayIndex = null), child: const Text('Show all')),
                ],
              ),
              const SizedBox(height: 4),
            ],
            ...entriesToShow.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayIndex == null)
                        Text(Fmt.dateShort(e.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ...e.items.map((r) => Padding(
                            padding: const EdgeInsets.only(left: 4, top: 2),
                            child: Text('• ${_itemLabel(r)}', style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
