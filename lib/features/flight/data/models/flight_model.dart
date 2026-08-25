import '../../domain/entities/flight.dart';

class FlightModel extends Flight {
  const FlightModel({
    required super.flightCode,
    required super.flightDescription,
    required super.arrDepAirportName,
    required super.destAirportName,
    required super.flightType,
    required super.airlineCode,
    required super.flightNo,
    required super.flightDate,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) => FlightModel(
    flightCode: json['flightCode'] as String? ?? '',
    flightDescription: json['flightDescription'] as String? ?? '',
    arrDepAirportName: json['ArrDepAirportName'] as String? ?? '',
    destAirportName: json['DestAirportName'] as String? ?? '',
    flightType: json['flightType'] as String? ?? '',
    airlineCode: json['airlineCode'] as String? ?? '',
    flightNo: json['flightNo'] as String? ?? '',
    flightDate: json['flightDate']?.toString() ?? '',
  );
}
