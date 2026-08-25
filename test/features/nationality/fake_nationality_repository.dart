import 'package:kp_pos/features/nationality/domain/entities/nationality.dart';
import 'package:kp_pos/features/nationality/domain/repositories/nationality_repository.dart';

/// Shared test double for [NationalityRepository].
class FakeNationalityRepository implements NationalityRepository {
  final List<Nationality> searchResult;

  String? lastCountryCode;

  FakeNationalityRepository({this.searchResult = const []});

  @override
  Future<List<Nationality>> search({
    String countryCode = '',
    int pageNo = 0,
    int pageSize = 50,
  }) async {
    lastCountryCode = countryCode;
    return searchResult;
  }
}
