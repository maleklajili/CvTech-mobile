// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:cv_tech/data/models/auth/auth_response.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSendOtpRequested>(_onAuthSendOtpRequested);
    on<AuthVerifyOtpRequested>(_onAuthVerifyOtpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
    on<AuthResetState>(_onAuthResetState);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AuthBloc: _onAuthLoginRequested started');
    // Émettre AuthSubmitting au lieu de AuthLoading pour éviter le refresh de la page
    emit(const AuthSubmitting());
    
    try {
      print('🔵 AuthBloc: Calling login API...');
      final authResponse = await _authRepository.login(event.request);
      print('🔵 AuthBloc: Login API success - tokens saved');
      
      // Essayer de récupérer le profil utilisateur
      UserModel? user;
      try {
        user = await _authRepository.getCurrentUser();
      } catch (_) {
        // Si getCurrentUser échoue, utiliser les données basiques
      }
      
      print('🟢 AuthBloc: Emitting AuthAuthenticated');
      emit(AuthAuthenticated(
        user: user ?? UserModel(
          id: authResponse.userId,
          firstName: '',
          lastName: '',
          userName: '',
          email: event.request.identifier,
        ),
      ));
    } catch (e) {
      print('🔴 AuthBloc: Login error: $e');
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onAuthSendOtpRequested(
    AuthSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final response = await _authRepository.sendOtp(event.email);
      // En mode DEV, l'OTP est retourné dans la réponse
      emit(AuthOtpSent(email: event.email, devOtp: response.otp));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onAuthVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOtpVerifying());
    
    try {
      await _authRepository.verifyOtpAndRegister(event.otp, event.userData);
      
      // Émettre AuthAuthenticated avec les données du formulaire
      // (Ne pas appeler getCurrentUser car l'utilisateur n'est pas encore créé dans la DB)
      emit(AuthAuthenticated(
        user: UserModel(
          id: '',
          firstName: event.userData.firstName,
          lastName: event.userData.lastName,
          userName: event.userData.userName,
          email: event.userData.email,
        ),
      ));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      await _authRepository.forgetPassword(event.email);
      emit(AuthPasswordResetSent(email: event.email));
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      await _authRepository.changePassword(event.token, event.newPassword);
      emit(const AuthPasswordChanged());
    } catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    }
  }

  void _onAuthResetState(
    AuthResetState event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthUnauthenticated());
  }

  /// Extract clean error message from exception
  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    
    // Remove "Exception: " prefix
    message = message.replaceAll('Exception: ', '');
    
    // Remove curly braces and clean up JSON-like error messages
    if (message.startsWith('{') && message.endsWith('}')) {
      try {
        // Try to extract message from JSON-like string
        final messageMatch = RegExp(r'message["\s:]+([^,"}]+)').firstMatch(message);
        if (messageMatch != null) {
          return messageMatch.group(1)?.trim() ?? message;
        }
      } catch (_) {
        // If parsing fails, continue with cleanup
      }
    }
    
    // Remove extra quotes and braces
    message = message.replaceAll(RegExp(r'[{}"]'), '').trim();
    
    // If message is empty or too technical, provide a friendly default
    if (message.isEmpty || message.length < 3) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
    
    return message;
  }
}
