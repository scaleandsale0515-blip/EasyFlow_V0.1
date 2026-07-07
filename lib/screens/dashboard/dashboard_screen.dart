import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/company_profile.dart';
import '../../models/item_catalog.dart';
import '../../models/production.dart';
import '../../models/transport.dart';
import '../../models/worker.dart';
import '../../models/transporter.dart';
import '../../models/app_settings.dart';
import '../../services/hive_service.dart';
import '../../services/item_catalog_service.dart';
import '../../services/stock_service.dart';
import '../../services/ledger_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../purchase/purchase_list_screen.dart';
import '../purchase/opening_stock_dialog.dart';
import '../worker/worker_list_screen.dart';
import '../worker/worker_ledger_screen.dart';
import '../transporter/transporter_list_screen.dart';
import '../transporter/transporter_ledger_screen.dart';
import 'chart_production.dart';
import 'chart_workers.dart';
import 'chart_trends.dart';
import 'chart_purchase.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OpeningStockDialog.showIfNeeded(context);
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final companyBox = Hive.box<CompanyProfile>(HiveBoxes.companyProfile);
    final companyName = companyBox.isNotEmpty && companyBox.getAt(0)!.companyName.isNotEmpty ? companyBox.getAt(0)!.companyName : 'your factory';

    return Scaffold(
      appBar: AppBar(title: const Text('EasyFlow')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ProductionEntry>(HiveBoxes.production).listenable(),
        builder: (context, Box<ProductionEntry> pBox, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('$_greeting,', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              Text(companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              ..._alertBanners(),

              const SectionHeader(title: 'Inventory'),
              ..._inventoryCards(),
              const SizedBox(height: 8),

              const SectionHeader(title: "Today's Summary"),
              _todaySummary(),
              const SizedBox(height: 8),

              _cementStockCards(),
              const SizedBox(height: 16),

              const SectionHeader(title: 'Charts'),
              const ProductionChart(),
              const SizedBox(height: 12),
              const WorkerChart(),
              const SizedBox(height: 12),
              const TrendsChart(),
              const SizedBox(height: 12),
              const PurchaseUsageChart(),
              const SizedBox(height: 16),

              const SectionHeader(title: 'Recent Activity'),
              ..._recentActivity(),
              const SizedBox(height: 16),

              const SectionHeader(title: 'Pending Dues'),
              ..._pendingDues(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _alertBanners() {
    final banners = <Widget>[];
    if (StockService.isLowStock()) {
      banners.add(_banner(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warningAmber,
        text: 'Cement stock is low (${Fmt.qty(StockService.currentCementStock())} bags left).',
      ));
    }
    final settingsBox = Hive.box<AppSettings>(HiveBoxes.appSettings);
    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0);
      final lastBackup = settings?.lastBackupDate;
      final daysSince = lastBackup == null ? 999 : DateTime.now().difference(lastBackup).inDays;
      if (daysSince >= 30) {
        banners.add(_banner(
          icon: Icons.backup_outlined,
          color: AppColors.accentCyan,
          text: lastBackup == null ? "You haven't taken a backup yet. Back up your data regularly." : "It's been $daysSince days since your last backup.",
        ));
      }
    }
    if (banners.isEmpty) return [];
    return [...banners, const SizedBox(height: 8)];
  }

  Widget _banner({required IconData icon, required Color color, required String text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  List<Widget> _inventoryCards() {
    final categories = ItemCatalogService.categories.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    if (categories.isEmpty) {
      return [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No items in catalog yet.', style: TextStyle(color: AppColors.textSecondary))))];
    }
    return categories.map((cat) {
      final subs = ItemCatalogService.subcategoriesFor(cat.id);
      final subIds = subs.map((s) => s.id).toList();
      final total = StockService.categoryStock(cat.id, subIds);
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Total Stock: ${Fmt.qty(total)} pc', style: const TextStyle(color: AppColors.accentCyan)),
          children: subs.map((s) {
            final stock = StockService.subcategoryStock(s.id);
            return ListTile(
              dense: true,
              title: Text(s.name),
              trailing: Text('${Fmt.qty(stock)} ${s.unit}'),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _todaySummary() {
    final today = DateTime.now();
    final productions = Hive.box<ProductionEntry>(HiveBoxes.production).values.where((e) => _isSameDay(e.date, today)).toList();
    final transports = Hive.box<TransportEntry>(HiveBoxes.transport).values.where((e) => _isSameDay(e.date, today)).toList();
    final wageTotal = productions.fold(0.0, (sum, e) => sum + e.totalAmount);

    return Row(
      children: [
        Expanded(child: _statCard('Production', '${productions.length}', Icons.precision_manufacturing_outlined, () => _showTodayProduction(productions))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Transport', '${transports.length}', Icons.local_shipping_outlined, () => _showTodayTransport(transports))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Wages', Fmt.money(wageTotal), Icons.currency_rupee, () => _showTodayProduction(productions))),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentCyan, size: 20),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodayProduction(List<ProductionEntry> productions) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          const Text("Today's Production", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (productions.isEmpty) const Text('No production logged today yet.', style: TextStyle(color: AppColors.textSecondary)),
          ...productions.map((e) {
            String workerName;
            try {
              workerName = Hive.box<Worker>(HiveBoxes.workers).values.firstWhere((w) => w.id == e.workerId).name;
            } catch (_) {
              workerName = '(deleted)';
            }
            return ListTile(
              title: Text(workerName),
              subtitle: Text('${e.items.length} item(s)'),
              trailing: Text(Fmt.money(e.totalAmount)),
            );
          }),
        ],
      ),
    );
  }

  void _showTodayTransport(List<TransportEntry> transports) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          const Text("Today's Transport", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (transports.isEmpty) const Text('No dispatches logged today yet.', style: TextStyle(color: AppColors.textSecondary)),
          ...transports.map((e) {
            String tName;
            try {
              tName = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == e.transporterId).name;
            } catch (_) {
              tName = '(deleted)';
            }
            return ListTile(
              title: Text(tName),
              subtitle: Text('${e.vehicleType} ${e.vehicleNo}'),
              trailing: Text(Fmt.money(e.transportCharge)),
            );
          }),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _cementStockCards() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen())),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Stock', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${Fmt.qty(StockService.currentCementStock())} bags', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen())),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Usage", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${Fmt.qty(StockService.todayCementUsage())} bags', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _recentActivity() {
    final productions = Hive.box<ProductionEntry>(HiveBoxes.production).values.map((e) => _Activity(e.date, 'production', e)).toList();
    final transports = Hive.box<TransportEntry>(HiveBoxes.transport).values.map((e) => _Activity(e.date, 'transport', e)).toList();
    final all = [...productions, ...transports]..sort((a, b) => b.date.compareTo(a.date));
    final recent = all.take(5).toList();

    if (recent.isEmpty) {
      return [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No activity yet.', style: TextStyle(color: AppColors.textSecondary))))];
    }

    return recent.map((a) {
      if (a.type == 'production') {
        final e = a.data as ProductionEntry;
        String workerName;
        try {
          workerName = Hive.box<Worker>(HiveBoxes.workers).values.firstWhere((w) => w.id == e.workerId).name;
        } catch (_) {
          workerName = '(deleted)';
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.accentCyan),
            title: Text('Production - $workerName'),
            subtitle: Text(Fmt.date(e.date)),
            trailing: Text(Fmt.money(e.totalAmount)),
          ),
        );
      } else {
        final e = a.data as TransportEntry;
        String tName;
        try {
          tName = Hive.box<Transporter>(HiveBoxes.transporters).values.firstWhere((t) => t.id == e.transporterId).name;
        } catch (_) {
          tName = '(deleted)';
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryBlue),
            title: Text('Transport - $tName'),
            subtitle: Text(Fmt.date(e.date)),
            trailing: Text(Fmt.money(e.transportCharge)),
          ),
        );
      }
    }).toList();
  }

  List<Widget> _pendingDues() {
    final workers = Hive.box<Worker>(HiveBoxes.workers).values.toList();
    final transporters = Hive.box<Transporter>(HiveBoxes.transporters).values.toList();

    final totalWorkerDue = workers.fold(0.0, (sum, w) => sum + LedgerService.workerBalance(w.id));
    final totalTransporterDue = transporters.fold(0.0, (sum, t) => sum + LedgerService.transporterBalance(t.id));

    final negativeWorkers = workers.where((w) => LedgerService.workerBalance(w.id) < 0).toList();
    final negativeTransporters = transporters.where((t) => LedgerService.transporterBalance(t.id) < 0).toList();

    return [
      Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerListScreen())),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Worker Dues', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(Fmt.money(totalWorkerDue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransporterListScreen())),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Transporter Dues', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(Fmt.money(totalTransporterDue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      if (negativeWorkers.isNotEmpty || negativeTransporters.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...negativeWorkers.map((w) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(w.name),
                trailing: Text(Fmt.money(LedgerService.workerBalance(w.id)), style: const TextStyle(color: AppColors.balanceRed, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerLedgerScreen(worker: w))),
              ),
            )),
        ...negativeTransporters.map((t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(t.name),
                trailing: Text(Fmt.money(LedgerService.transporterBalance(t.id)), style: const TextStyle(color: AppColors.balanceRed, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransporterLedgerScreen(transporter: t))),
              ),
            )),
      ],
    ];
  }
}

class _Activity {
  final DateTime date;
  final String type;
  final dynamic data;
  _Activity(this.date, this.type, this.data);
}
