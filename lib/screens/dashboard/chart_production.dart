import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/production.dart';
import '../../models/item_catalog.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProductionChart extends StatefulWidget {
  const ProductionChart({super.key});

  @override
  State<ProductionChart> createState() => _ProductionChartState();
}

class _ProductionChartState extends State<ProductionChart> {
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final entries = Hive.box<ProductionEntry>(HiveBoxes.production).values.where((e) => range.contains(e.date)).toList();

    final Map<String, double> totalsByCategory = {};
    for (final e in entries) {
      for (final row in e.items) {
        String name;
        try {
          name = ItemCatalogService.categories.values.firstWhere((c) => c.id == row.categoryId).name;
        } catch (_) {
          name = 'Unknown';
        }
        totalsByCategory[name] = (totalsByCategory[name] ?? 0) + row.quantity;
      }
    }
    final sortedEntries = totalsByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Production by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            DateFilterBar(
              initial: DateRangeFilter.thisMonth,
              options: const [DateRangeFilter.thisMonth, DateRangeFilter.thisQuarter, DateRangeFilter.thisYear, DateRangeFilter.custom],
              onRangeChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 16),
            if (sortedEntries.isEmpty)
              const SizedBox(height: 120, child: Center(child: Text('No data in this period', style: TextStyle(color: AppColors.textSecondary))))
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    barGroups: sortedEntries.take(6).toList().asMap().entries.map((entry) {
                      return BarChartGroupData(x: entry.key, barRods: [
                        BarChartRodData(toY: entry.value.value, color: AppColors.accentCyan, width: 18, borderRadius: BorderRadius.circular(4)),
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
                            if (i < 0 || i >= sortedEntries.length || i >= 6) return const SizedBox();
                            final label = sortedEntries[i].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(label.length > 8 ? '${label.substring(0, 8)}…' : label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            );
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
            ...sortedEntries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(color: AppColors.textSecondary)),
                      Text(Fmt.qty(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
