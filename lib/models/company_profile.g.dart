part of 'company_profile.dart';

class CompanyProfileAdapter extends TypeAdapter<CompanyProfile> {
  @override
  final int typeId = 0;

  @override
  CompanyProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompanyProfile(
      companyName: fields[0] as String,
      logoPath: fields[1] as String?,
      phone: fields[2] as String?,
      email: fields[3] as String?,
      address: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CompanyProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.companyName)
      ..writeByte(1)
      ..write(obj.logoPath)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
