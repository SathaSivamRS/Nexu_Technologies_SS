import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../data/auth_local_datasource.dart';
import 'auth_session.dart';

class AuthService {
  final AuthLocalDataSource _dataSource;

  AuthService(this._dataSource);

  Future<AuthSession?> getCurrentSession() async {
    return await _dataSource.getSession();
  }

  Future<AuthSession> signIn({
    required String agentName,
    required String pin,
  }) async {
    final trimmedName = agentName.trim();
    final trimmedPin = pin.trim();

    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Agent name is mandatory.');
    }

    if (trimmedPin.isEmpty) {
      throw const ValidationFailure('Four-digit PIN is mandatory.');
    }

    final pinRegex = RegExp(r'^\d{4}$');
    if (!pinRegex.hasMatch(trimmedPin)) {
      throw const ValidationFailure('PIN must contain exactly four digits.');
    }

    if (trimmedName.toLowerCase() != AppConstants.demoAgentName.toLowerCase() ||
        trimmedPin != AppConstants.demoPin) {
      throw const ValidationFailure(
        'Invalid credentials. For demo: Agent Name "${AppConstants.demoAgentName}", PIN "${AppConstants.demoPin}".',
      );
    }

    final session = AuthSession(
      agentName: AppConstants.demoAgentName,
      signedInAt: DateTime.now(),
    );

    await _dataSource.saveSession(session);
    return session;
  }

  Future<void> signOut() async {
    await _dataSource.clearSession();
  }
}
