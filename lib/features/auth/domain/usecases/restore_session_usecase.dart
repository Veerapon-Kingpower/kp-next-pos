import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  final AuthRepository _repository;

  const RestoreSessionUseCase(this._repository);

  Future<UserSession?> call() => _repository.currentSession();
}
