import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/firebase_repository.dart';
import '../domain/models.dart';

class AuthState extends ChangeNotifier {
  AuthState(this.repository) {
    _authSubscription = repository.auth.userChanges().listen(
      _onUser,
      onError: (Object error) {
        this.error = friendlyError(error);
        _waitingForAuth = false;
        _notify();
      },
    );
  }
  final FirebaseRepository repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  User? user;
  UserProfile? profile;
  String? error;
  bool _waitingForAuth = true;
  bool _busy = false;
  bool _disposed = false;
  String? _watchedUid;
  bool get isLoading => _waitingForAuth || _busy;
  bool get isAuthenticated => user != null && profile?.active == true;

  void _onUser(User? value) {
    user = value;
    if (_watchedUid == value?.uid && value != null) {
      _notify();
      return;
    }
    _watchedUid = value?.uid;
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    profile = null;
    _waitingForAuth = value != null;
    if (value != null) {
      _profileSubscription = repository
          .watchProfile(value.uid)
          .listen(
            (next) {
              profile = next;
              _waitingForAuth = false;
              if (next != null && !next.active) {
                error =
                    'Tu cuenta está desactivada. Contacta al administrador.';
                unawaited(repository.logout());
              }
              _notify();
            },
            onError: (Object error) {
              this.error = friendlyError(error);
              _waitingForAuth = false;
              _notify();
            },
          );
    }
    _notify();
  }

  Future<bool> login(String email, String password) =>
      _run(() => repository.login(email, password));
  Future<bool> register(String name, String email, String password) =>
      _run(() => repository.register(name, email, password));
  Future<bool> resetPassword(String email) =>
      _run(() => repository.resetPassword(email));
  Future<bool> sendVerificationEmail() =>
      _run(repository.sendVerificationEmail);
  Future<bool> reloadUser() => _run(repository.reloadUser);
  Future<bool> updateProfile(String name) =>
      _run(() => repository.updateProfile(name));
  Future<bool> logout() => _run(repository.logout);
  void clearError() {
    error = null;
    _notify();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    error = null;
    _notify();
    try {
      await action();
      return true;
    } catch (exception) {
      error = friendlyError(exception);
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    unawaited(_profileSubscription?.cancel());
    super.dispose();
  }
}
