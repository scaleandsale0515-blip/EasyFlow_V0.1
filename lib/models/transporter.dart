import 'package:hive_ce/hive.dart';

part 'transporter.g.dart';

@HiveType(typeId: 6)
class Transporter extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  DateTime createdAt;

  // Remembered from past trips, used to auto-fill next time this
  // transporter is selected in a Transport entry.
  @HiveField(6)
  String? lastVehicleType;

  @HiveField(7)
  String? lastVehicleNo;

  Transporter({
    required this.id,
    required this.name,
    this.phone,
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
    this.lastVehicleType,
    this.lastVehicleNo,
  }) : createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 7)
class TransporterPayment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String transporterId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String mode;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  TransporterPayment({
    required this.id,
    required this.transporterId,
    required this.date,
    required this.amount,
    this.mode = 'Cash',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
