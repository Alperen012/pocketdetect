import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/publisher_profile.dart';

/// Handles authentication state and user profile management via Supabase Auth.
class AuthService extends ChangeNotifier {
  AuthService() {
    _client = Supabase.instance.client;
    _subscription = _client.auth.onAuthStateChange.listen(_onAuthStateChange);
    _currentUser = _client.auth.currentUser;
  }

  late final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;
  User? _currentUser;
  PublisherProfile? _profile;
  bool _isLoading = false;
  bool _pendingVerification = false;

  User? get currentUser => _currentUser;
  PublisherProfile? get profile => _profile;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isEmailVerified => _currentUser?.emailConfirmedAt != null;

  /// True when sign-up succeeded but email is not yet confirmed.
  bool get pendingEmailVerification => _pendingVerification;

  String? get userId => _currentUser?.id;
  String get displayName =>
      _profile?.displayName ??
      _profile?.username ??
      _currentUser?.email?.split('@').first ??
      'User';

  void _onAuthStateChange(AuthState state) {
    _currentUser = state.session?.user;
    if (_currentUser != null && _profile == null) {
      _loadProfile();
    } else if (_currentUser == null) {
      _profile = null;
    }
    notifyListeners();
  }

  /// Sign in with email and password.
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _client.auth.signInWithPassword(email: email, password: password);
      await _loadProfile();
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register with email and password. Creates a profile row automatically.
  Future<String?> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create profile row
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'username': username,
          'display_name': username,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });

        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          _pendingVerification = true;
          notifyListeners();
        } else {
          await _loadProfile();
        }
      }

      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a password-reset email to the user.
  Future<String?> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _client.auth.resetPasswordForEmail(email);
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
    _profile = null;
    _pendingVerification = false;
    notifyListeners();
  }

  /// Load the user's marketplace profile.
  Future<void> _loadProfile() async {
    if (_currentUser == null) return;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      if (data != null) {
        _profile = PublisherProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  /// Update the user's username.
  Future<void> updateUsername(String username) async {
    if (_currentUser == null) return;
    await _client
        .from('profiles')
        .update({'username': username})
        .eq('id', _currentUser!.id);
    await _loadProfile();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
