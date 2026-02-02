// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:cv_tech/data/models/auth/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during authentication operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Submitting login/register form (doesn't trigger page refresh)
class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authentication error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// OTP sent successfully
class AuthOtpSent extends AuthState {
  final String email;
  final String? devOtp; // OTP disponible uniquement en mode DEV

  const AuthOtpSent({required this.email, this.devOtp});

  @override
  List<Object?> get props => [email, devOtp];
}

/// OTP verification in progress
class AuthOtpVerifying extends AuthState {
  const AuthOtpVerifying();
}

/// Password reset email sent
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Password changed successfully
class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged();
}
