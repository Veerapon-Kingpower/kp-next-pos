import '../entities/nationality.dart';
import '../repositories/nationality_repository.dart';

class ListNationalitiesUseCase {
  final NationalityRepository _repository;

  const ListNationalitiesUseCase(this._repository);

  Future<List<Nationality>> call({
    String countryCode = '',
    int pageNo = 0,
    int pageSize = 50,
  }) {
    return _repository.search(
      countryCode: countryCode,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }
}
