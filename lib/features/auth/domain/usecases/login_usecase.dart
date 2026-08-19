import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<UserSession> call({
    required String userCode,
    required String userPassword,
  }) {
    return _repository.login(userCode: userCode, userPassword: userPassword);
  }
}
