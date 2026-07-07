part of 'transporter.dart';

class TransporterAdapter extends TypeAdapter<Transporter> {
  @override
  final int typeId = 6;

  @override
  Transporter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transporter(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      isActive: fields[3] as bool,
      notes: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      lastVehicleType: fields[6] as String?,
      lastVehicleNo: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transporter obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastVehicleType)
      ..writeByte(7)
      ..write(obj.lastVehicleNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransporterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransporterPaymentAdapter extends TypeAdapter<TransporterPayment> {
  @override
  final int typeId = 7;

  @override
  TransporterPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransporterPayment(
      id: fields[0] as String,
      transporterId: fields[1] as String,
      date: fields[2] as DateTime,
      amount: (fields[3] as num).toDouble(),
      mode: fields[4] as String,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransporterPayment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transporterId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.mode)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransporterPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
