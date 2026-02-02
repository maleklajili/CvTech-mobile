// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:cv_tech/data/models/auth/login_request.dart';
import 'package:cv_tech/data/models/auth/register_request.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with credentials
class AuthLoginRequested extends AuthEvent {
  final LoginRequest request;

  const AuthLoginRequested({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Request OTP for registration
class AuthSendOtpRequested extends AuthEvent {
  final String email;

  const AuthSendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Verify OTP and complete registration
class AuthVerifyOtpRequested extends AuthEvent {
  final String otp;
  final RegisterRequest userData;

  const AuthVerifyOtpRequested({
    required this.otp,
    required this.userData,
  });

  @override
  List<Object?> get props => [otp, userData];
}

/// Logout the current user
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Request password reset
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Change password with reset token
class AuthChangePasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthChangePasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
}

/// Reset auth state to initial/unauthenticated
class AuthResetState extends AuthEvent {
  const AuthResetState();
}
