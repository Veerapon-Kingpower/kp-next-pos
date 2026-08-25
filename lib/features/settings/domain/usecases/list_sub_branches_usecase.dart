import '../entities/sub_branch.dart';
import '../repositories/settings_repository.dart';

class ListSubBranchesUseCase {
  final SettingsRepository _repository;

  const ListSubBranchesUseCase(this._repository);

  Future<List<SubBranch>> call({required String baseUrl, String key = ''}) =>
      _repository.listSubBranches(baseUrl: baseUrl, key: key);
}
