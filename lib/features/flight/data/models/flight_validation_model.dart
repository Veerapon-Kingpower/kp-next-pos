import '../../domain/entities/flight_validation.dart';

class FlightValidationModel extends FlightValidation {
  const FlightValidationModel({
    required super.flightValidate,
    required super.pickupCode,
    required super.pickupName,
    required super.puImageUrl,
  });

  factory FlightValidationModel.fromJson(Map<String, dynamic> json) =>
      FlightValidationModel(
        flightValidate: json['flightValidate'] as bool? ?? false,
        pickupCode: json['pickupCode'] as String? ?? '',
        pickupName: json['pickupName'] as String? ?? '',
        puImageUrl: json['puImageUrl'] as String? ?? '',
      );
}
