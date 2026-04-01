import 'package:flutter/foundation.dart';

/// Base class that safely guards [notifyListeners] after [dispose].
///
/// Extend this instead of [ChangeNotifier] in any ViewModel that may
/// receive async callbacks after the widget tree drops its reference.
abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
