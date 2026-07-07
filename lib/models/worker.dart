import 'package:hive_ce/hive.dart';

part 'worker.g.dart';

@HiveType(typeId: 4)
class Worker extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? address;

  @HiveField(4)
  String? photoPath; // compressed image stored on disk, path saved here

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  Worker({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.photoPath,
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 5)
class WorkerPayment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String workerId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String mode; // Cash / Bank / UPI / Other

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  WorkerPayment({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.mode = 'Cash',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
