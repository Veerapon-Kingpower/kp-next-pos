import '../../domain/entities/nationality.dart';

class NationalityModel extends Nationality {
  const NationalityModel({
    required super.countryCode,
    required super.countryName,
  });

  factory NationalityModel.fromJson(Map<String, dynamic> json) =>
      NationalityModel(
        countryCode: json['CountryCode'] as String? ?? '',
        countryName: json['CountryName'] as String? ?? '',
      );
}
