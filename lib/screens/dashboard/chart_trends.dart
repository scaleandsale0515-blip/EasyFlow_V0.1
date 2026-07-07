import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/production.dart';
import '../../models/worker.dart';
import '../../services/hive_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TrendsChart extends StatefulWidget {
  const TrendsChart({super.key});

  @override
  State<TrendsChart> createState() => _TrendsChartState();
}

class _TrendsChartState extends State<TrendsChart> {
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);

  String _workerName(String id) {
    try {
      return Hive.box<Worker>(HiveBoxes.workers).values.firstWhere((w) => w.id == id).name;
    } catch (_) {
      return '(deleted)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final entries = Hive.box<ProductionEntry>(HiveBoxes.production).values.where((e) => range.contains(e.date)).toList();

    final Map<String, double> totalsByWorker = {};
    for (final e in entries) {
      totalsByWorker[e.workerId] = (totalsByWorker[e.workerId] ?? 0) + e.totalAmount;
    }
    final ranked = totalsByWorker.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3 = ranked.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 3 Workers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            DateFilterBar(
              initial: DateRangeFilter.thisMonth,
              options: const [DateRangeFilter.thisMonth, DateRangeFilter.thisQuarter, DateRangeFilter.thisYear, DateRangeFilter.custom],
              onRangeChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 16),
            if (top3.isEmpty)
              const SizedBox(height: 120, child: Center(child: Text('No data in this period', style: TextStyle(color: AppColors.textSecondary))))
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    barGroups: top3.asMap().entries.map((entry) {
                      final colors = [AppColors.warningAmber, AppColors.accentCyan, AppColors.primaryBlue];
                      return BarChartGroupData(x: entry.key, barRods: [
                        BarChartRodData(toY: entry.value.value, color: colors[entry.key], width: 32, borderRadius: BorderRadius.circular(4)),
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
                            if (i < 0 || i >= top3.length) return const SizedBox();
                            final name = _workerName(top3[i].key);
                            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(name.length > 10 ? '${name.substring(0, 10)}…' : name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)));
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
            ...top3.asMap().entries.map((entry) {
              final medal = ['🥇', '🥈', '🥉'][entry.key];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$medal ${_workerName(entry.value.key)}', style: const TextStyle(color: AppColors.textSecondary)),
                    Text(Fmt.money(entry.value.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
