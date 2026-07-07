part of 'purchase.dart';

class PurchaseEntryAdapter extends TypeAdapter<PurchaseEntry> {
  @override
  final int typeId = 12;

  @override
  PurchaseEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      quantity: (fields[2] as num).toDouble(),
      ratePerBag: (fields[3] as num?)?.toDouble(),
      supplierName: fields[4] as String?,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.ratePerBag)
      ..writeByte(4)
      ..write(obj.supplierName)
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
      other is PurchaseEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
