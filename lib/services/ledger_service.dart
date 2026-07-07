import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/production.dart';
import '../models/transport.dart';
import '../models/worker.dart';
import '../models/transporter.dart';
import 'hive_service.dart';

/// A single line in a Worker or Transporter ledger view - either an
/// auto-pulled earning entry (read-only) or a manual payment (editable).
class LedgerLine {
  final DateTime date;
  final String description;
  final double amount; // positive = earned, negative = paid
  final bool isPayment;
  final String? sourceId; // id of the WorkerPayment/TransporterPayment for edit/delete

  LedgerLine({
    required this.date,
    required this.description,
    required this.amount,
    required this.isPayment,
    this.sourceId,
  });
}

class LedgerService {
  static Box<ProductionEntry> get _production =>
      Hive.box<ProductionEntry>(HiveBoxes.production);
  static Box<TransportEntry> get _transport =>
      Hive.box<TransportEntry>(HiveBoxes.transport);
  static Box<WorkerPayment> get _workerPayments =>
      Hive.box<WorkerPayment>(HiveBoxes.workerPayments);
  static Box<TransporterPayment> get _transporterPayments =>
      Hive.box<TransporterPayment>(HiveBoxes.transporterPayments);

  // ---------------- Worker ----------------

  static double totalEarnedByWorker(String workerId) {
    return _production.values
        .where((p) => p.workerId == workerId)
        .fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  static double totalPaidToWorker(String workerId) {
    return _workerPayments.values
        .where((p) => p.workerId == workerId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Positive = factory owes worker (shown green).
  /// Negative = worker owes back / advance given (shown red/orange).
  static double workerBalance(String workerId) {
    return totalEarnedByWorker(workerId) - totalPaidToWorker(workerId);
  }

  static List<LedgerLine> workerLedgerLines(String workerId) {
    final lines = <LedgerLine>[];
    for (final p in _production.values.where((p) => p.workerId == workerId)) {
      lines.add(LedgerLine(
        date: p.date,
        description: 'Production (${p.items.length} item${p.items.length > 1 ? 's' : ''})',
        amount: p.totalAmount,
        isPayment: false,
      ));
    }
    for (final pay in _workerPayments.values.where((p) => p.workerId == workerId)) {
      lines.add(LedgerLine(
        date: pay.date,
        description: 'Payment (${pay.mode})',
        amount: -pay.amount,
        isPayment: true,
        sourceId: pay.id,
      ));
    }
    lines.sort((a, b) => b.date.compareTo(a.date));
    return lines;
  }

  // ---------------- Transporter ----------------

  static double totalChargedByTransporter(String transporterId) {
    return _transport.values
        .where((t) => t.transporterId == transporterId)
        .fold(0.0, (sum, t) => sum + t.transportCharge);
  }

  static double totalPaidToTransporter(String transporterId) {
    return _transporterPayments.values
        .where((p) => p.transporterId == transporterId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  static double transporterBalance(String transporterId) {
    return totalChargedByTransporter(transporterId) -
        totalPaidToTransporter(transporterId);
  }

  static List<LedgerLine> transporterLedgerLines(String transporterId) {
    final lines = <LedgerLine>[];
    for (final t in _transport.values.where((t) => t.transporterId == transporterId)) {
      lines.add(LedgerLine(
        date: t.date,
        description: 'Trip - ${t.vehicleNo}',
        amount: t.transportCharge,
        isPayment: false,
      ));
    }
    for (final pay in _transporterPayments.values
        .where((p) => p.transporterId == transporterId)) {
      lines.add(LedgerLine(
        date: pay.date,
        description: 'Payment (${pay.mode})',
        amount: -pay.amount,
        isPayment: true,
        sourceId: pay.id,
      ));
    }
    lines.sort((a, b) => b.date.compareTo(a.date));
    return lines;
  }
}
