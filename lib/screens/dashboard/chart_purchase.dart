import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/production.dart';
import '../../models/purchase.dart';
import '../../services/hive_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PurchaseUsageChart extends StatefulWidget {
  const PurchaseUsageChart({super.key});

  @override
  State<PurchaseUsageChart> createState() => _PurchaseUsageChartState();
}

class _PurchaseUsageChartState extends State<PurchaseUsageChart> {
  DateRange _range = DateRange.forFilter(DateRangeFilter.thisMonth);

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final purchased = Hive.box<PurchaseEntry>(HiveBoxes.purchase).values
        .where((p) => range.contains(p.date))
        .fold(0.0, (sum, p) => sum + p.quantity);
    final used = Hive.box<ProductionEntry>(HiveBoxes.production).values
        .where((p) => range.contains(p.date))
        .fold(0.0, (sum, p) => sum + p.cementBagsUsed);
    final maxVal = (purchased > used ? purchased : used) * 1.2 + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cement: Purchased vs Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            DateFilterBar(
              initial: DateRangeFilter.thisMonth,
              options: const [DateRangeFilter.thisMonth, DateRangeFilter.thisQuarter, DateRangeFilter.thisYear, DateRangeFilter.custom],
              onRangeChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxVal,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: purchased, color: AppColors.balanceGreen, width: 40, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: used, color: AppColors.warningAmber, width: 40, borderRadius: BorderRadius.circular(4))]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final label = v.toInt() == 0 ? 'Purchased' : 'Used';
                          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)));
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Purchased: ${Fmt.qty(purchased)} bags', style: const TextStyle(color: AppColors.balanceGreen, fontWeight: FontWeight.w600)),
                Text('Used: ${Fmt.qty(used)} bags', style: const TextStyle(color: AppColors.warningAmber, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
