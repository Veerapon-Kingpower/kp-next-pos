import '../../domain/entities/nationality.dart';
import '../../domain/repositories/nationality_repository.dart';

/// Demo/dev-only nationality data — returns a small canned list filtered
/// client-side, so the Register form's Nationality field can be exercised
/// without a reachable `Register/GetNationality` backend. Wired in by
/// `nationality_injection.dart` behind `kUseMockNationalityData`; flip that
/// to `false` (and drop this class) once a real backend is wired up for
/// this environment.
class MockNationalityRepository implements NationalityRepository {
  static const _nationalities = [
    Nationality(countryCode: 'THA', countryName: 'Thailand'),
    Nationality(countryCode: 'CHN', countryName: 'China'),
    Nationality(countryCode: 'JPN', countryName: 'Japan'),
    Nationality(countryCode: 'KOR', countryName: 'South Korea'),
    Nationality(countryCode: 'USA', countryName: 'United States'),
    Nationality(countryCode: 'GBR', countryName: 'United Kingdom'),
    Nationality(countryCode: 'AUS', countryName: 'Australia'),
    Nationality(countryCode: 'SGP', countryName: 'Singapore'),
    Nationality(countryCode: 'IND', countryName: 'India'),
    Nationality(countryCode: 'FRA', countryName: 'France'),
    Nationality(countryCode: 'DEU', countryName: 'Germany'),
    Nationality(countryCode: 'RUS', countryName: 'Russia'),
  ];

  @override
  Future<List<Nationality>> search({
    String countryCode = '',
    int pageNo = 0,
    int pageSize = 50,
  }) async {
    final query = countryCode.trim().toLowerCase();
    if (query.isEmpty) return _nationalities;
    return _nationalities
        .where(
          (n) =>
              n.countryCode.toLowerCase().contains(query) ||
              n.countryName.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }
}
