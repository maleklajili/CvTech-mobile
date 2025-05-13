// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

abstract class BasePreference<T> {
  String get key;

  Future<T?> load() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    if (T == String) return sharedPreferences.getString(key) as T?;
    if (T == bool) return sharedPreferences.getBool(key) as T?;

    throw UnimplementedError('The type ${T.runtimeType} is not supported');
  }

  Future<bool> save(T value) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    if (value is String) return sharedPreferences.setString(key, value);
    if (value is bool) return sharedPreferences.setBool(key, value);

    throw UnimplementedError('The type ${value.runtimeType} is not supported');
  }

  Future<void> reset() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final success = await sharedPreferences.remove(key);
    if (success) {
      debugPrint('SharedPreferences remove key => $key');
    } else {
      debugPrint('Failed to remove shared => $key');
    }
  }

  Future<void> clear() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final success = await sharedPreferences.clear();
    if (success) {
      debugPrint('Shared cleared key => $key');
    } else {
      debugPrint('Failed to clear shared => $key');
    }
  }
}
