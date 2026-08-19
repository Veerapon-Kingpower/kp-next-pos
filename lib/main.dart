import 'package:flutter/material.dart';

import 'core/app/app.dart';
import 'core/app/router.dart';
import 'core/app/session_state.dart';
import 'core/di/service_locator.dart';
import 'core/startup/startup_validator.dart';
import 'features/auth/auth_injection.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/login_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupCoreServiceLocator();
  setupAuthServiceLocator();

  final sessionState = SessionState(startupValidator: sl<StartupValidator>());
  await sessionState.refresh();

  final router = buildRouter(
    sessionState,
    loginViewModelFactory: () => sl<LoginViewModel>(),
    logoutUseCase: sl<LogoutUseCase>(),
  );

  runApp(KpPosApp(router: router));
}
