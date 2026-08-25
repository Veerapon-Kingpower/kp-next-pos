import '../entities/nationality.dart';

abstract class NationalityRepository {
  /// Ports `SaleEngineProvider.getNationality` (`Register/GetNationality`).
  /// [countryCode] doubles as the free-text search query in the legacy
  /// nationality picker (`nationality.ts`), not an exact-match filter.
  Future<List<Nationality>> search({
    String countryCode = '',
    int pageNo = 0,
    int pageSize = 50,
  });
}
