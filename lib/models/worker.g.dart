part of 'worker.dart';

class WorkerAdapter extends TypeAdapter<Worker> {
  @override
  final int typeId = 4;

  @override
  Worker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Worker(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      address: fields[3] as String?,
      photoPath: fields[4] as String?,
      isActive: fields[5] as bool,
      notes: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Worker obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.photoPath)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkerPaymentAdapter extends TypeAdapter<WorkerPayment> {
  @override
  final int typeId = 5;

  @override
  WorkerPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkerPayment(
      id: fields[0] as String,
      workerId: fields[1] as String,
      date: fields[2] as DateTime,
      amount: (fields[3] as num).toDouble(),
      mode: fields[4] as String,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkerPayment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workerId)
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
      other is WorkerPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
