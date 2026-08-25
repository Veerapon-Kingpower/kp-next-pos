import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/error/app_exception.dart';
import '../domain/entities/user_session.dart';
import '../domain/usecases/login_usecase.dart';

enum LoginStatus { idle, submitting, success, failure }

class LoginViewModel extends GetxController {
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
    update();
    if (kDebugMode) {
      // Never log userPassword.
      debugPrint('[LoginViewModel.submit] userCode=$userCode');
    }

    try {
      session = await _loginUseCase(
        userCode: userCode,
        userPassword: userPassword,
      );
      status = LoginStatus.success;
      if (kDebugMode) {
        debugPrint(
          '[LoginViewModel.submit] success sessionKey=${session?.sessionKey}',
        );
      }
    } on ApiException catch (e) {
      status = LoginStatus.failure;
      errorMessage = e.messageDesc;
      if (kDebugMode) {
        debugPrint('[LoginViewModel.submit] failed: $e');
      }
    } catch (e) {
      status = LoginStatus.failure;
      errorMessage = 'Could not sign in. Check your connection and try again.';
      if (kDebugMode) {
        debugPrint('[LoginViewModel.submit] failed: $e');
      }
    }
    update();
  }
}
