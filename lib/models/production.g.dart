part of 'production.dart';

class ProductionItemRowAdapter extends TypeAdapter<ProductionItemRow> {
  @override
  final int typeId = 8;

  @override
  ProductionItemRow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionItemRow(
      categoryId: fields[0] as String,
      subcategoryId: fields[1] as String,
      unit: fields[2] as String,
      quantity: (fields[3] as num).toDouble(),
      rate: (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductionItemRow obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.categoryId)
      ..writeByte(1)
      ..write(obj.subcategoryId)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.rate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionItemRowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductionEntryAdapter extends TypeAdapter<ProductionEntry> {
  @override
  final int typeId = 9;

  @override
  ProductionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      workerId: fields[2] as String,
      items: (fields[3] as List).cast<ProductionItemRow>(),
      notes: fields[4] as String?,
      cementBagsUsed: (fields[5] as num).toDouble(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProductionEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.workerId)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.cementBagsUsed)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
