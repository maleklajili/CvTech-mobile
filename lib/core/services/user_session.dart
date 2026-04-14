// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';

/// Lightweight helper to read the current authenticated user from [AuthBloc].
///
/// Usage:
/// ```dart
/// final user = UserSession.of(context);       // nullable
/// final user = UserSession.require(context);   // throws if not auth
/// if (UserSession.isAdmin(context)) { ... }
/// if (UserSession.isPremium(context)) { ... }
/// ```
class UserSession {
  UserSession._();

  /// Current [UserModel] or `null` if not authenticated.
  static UserModel? of(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    return null;
  }

  /// Current [UserModel]; throws if not authenticated.
  static UserModel require(BuildContext context) {
    final user = of(context);
    assert(user != null, 'UserSession.require called when not authenticated');
    return user!;
  }

  /// `true` when the authenticated user has `isAdmin == true`.
  static bool isAdmin(BuildContext context) {
    return of(context)?.isAdmin == true;
  }

  /// `true` when the authenticated user has an active premium plan (pro or gold).
  static bool isPremium(BuildContext context) {
    return of(context)?.isPremium == true;
  }

  /// `true` when the authenticated user has an active gold plan.
  static bool isGold(BuildContext context) {
    return of(context)?.isGold == true;
  }

  /// The current plan id ('free', 'pro', 'gold'). Defaults to 'free'.
  static String currentPlan(BuildContext context) {
    return of(context)?.plan ?? 'free';
  }
}
