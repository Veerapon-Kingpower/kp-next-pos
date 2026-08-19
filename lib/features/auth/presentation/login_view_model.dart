import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../domain/entities/user_session.dart';
import '../domain/usecases/login_usecase.dart';

enum LoginStatus { idle, submitting, success, failure }

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;

  LoginViewModel({required LoginUseCase loginUseCase})
    : _loginUseCase = loginUseCase;

  LoginStatus status = LoginStatus.idle;
  String? errorMessage;
  UserSession? session;

  Future<void> submit({
    required String userCode,
    required String userPassword,
  }) async {
    status = LoginStatus.submitting;
    errorMessage = null;
    notifyListeners();

    try {
      session = await _loginUseCase(
        userCode: userCode,
        userPassword: userPassword,
      );
      status = LoginStatus.success;
    } on ApiException catch (e) {
      status = LoginStatus.failure;
      errorMessage = e.messageDesc;
    } catch (_) {
      status = LoginStatus.failure;
      errorMessage = 'Could not sign in. Check your connection and try again.';
    }
    notifyListeners();
  }
}
