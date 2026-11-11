import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/auth_local_datasource.dart';
import '../../domain/auth_service.dart';
import '../../domain/auth_session.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final box = ref.watch(authBoxProvider);
  return AuthLocalDataSourceImpl(box);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dataSource = ref.watch(authLocalDataSourceProvider);
  return AuthService(dataSource);
});

class AuthState {
  final bool isLoading;
  final AuthSession? session;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.session,
    this.errorMessage,
  });

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    bool? isLoading,
    AuthSession? session,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final session = await _authService.getCurrentSession();
      state = AuthState(session: session, isLoading: false);
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> signIn(String agentName, String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _authService.signIn(
        agentName: agentName,
        pin: pin,
      );
      state = AuthState(session: session, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthState(isLoading: false);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
