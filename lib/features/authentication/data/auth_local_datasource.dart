import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/auth_session.dart';

abstract class AuthLocalDataSource {
  Future<AuthSession?> getSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box _box;

  AuthLocalDataSourceImpl(this._box);

  @override
  Future<AuthSession?> getSession() async {
    final raw = _box.get(AppConstants.authSessionKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> data =
          raw is String ? jsonDecode(raw) : Map<String, dynamic>.from(raw as Map);
      return AuthSession.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _box.put(
      AppConstants.authSessionKey,
      jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clearSession() async {
    await _box.delete(AppConstants.authSessionKey);
  }
}
