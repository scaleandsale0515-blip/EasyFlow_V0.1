part of 'transport.dart';

class TransportItemRowAdapter extends TypeAdapter<TransportItemRow> {
  @override
  final int typeId = 10;

  @override
  TransportItemRow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransportItemRow(
      isCement: fields[0] as bool,
      categoryId: fields[1] as String?,
      subcategoryId: fields[2] as String?,
      quantity: (fields[3] as num).toDouble(),
      reduceFromStock: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransportItemRow obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.isCement)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.subcategoryId)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.reduceFromStock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportItemRowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransportEntryAdapter extends TypeAdapter<TransportEntry> {
  @override
  final int typeId = 11;

  @override
  TransportEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransportEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      transporterId: fields[2] as String,
      vehicleType: fields[3] as String,
      vehicleNo: fields[4] as String,
      items: (fields[5] as List).cast<TransportItemRow>(),
      transportCharge: (fields[6] as num).toDouble(),
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransportEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.transporterId)
      ..writeByte(3)
      ..write(obj.vehicleType)
      ..writeByte(4)
      ..write(obj.vehicleNo)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.transportCharge)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
