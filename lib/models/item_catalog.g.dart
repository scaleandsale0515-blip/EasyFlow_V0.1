part of 'item_catalog.dart';

class ItemCategoryAdapter extends TypeAdapter<ItemCategory> {
  @override
  final int typeId = 1;

  @override
  ItemCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      isActive: fields[2] as bool,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ItemCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemSubcategoryAdapter extends TypeAdapter<ItemSubcategory> {
  @override
  final int typeId = 2;

  @override
  ItemSubcategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemSubcategory(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      name: fields[2] as String,
      unit: fields[3] as String,
      defaultRate: (fields[4] as num).toDouble(),
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ItemSubcategory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.defaultRate)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSubcategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomUnitAdapter extends TypeAdapter<CustomUnit> {
  @override
  final int typeId = 3;

  @override
  CustomUnit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomUnit(name: fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, CustomUnit obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
