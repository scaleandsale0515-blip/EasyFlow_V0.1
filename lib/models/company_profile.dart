import 'package:hive_ce/hive.dart';

part 'company_profile.g.dart';

@HiveType(typeId: 0)
class CompanyProfile extends HiveObject {
  @HiveField(0)
  String companyName;

  @HiveField(1)
  String? logoPath; // stored as compressed base64 or file path

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? address;

  CompanyProfile({
    this.companyName = '',
    this.logoPath,
    this.phone,
    this.email,
    this.address,
  });
}
