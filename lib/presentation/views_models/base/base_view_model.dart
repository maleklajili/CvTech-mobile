// Flutter imports:
import 'package:flutter/material.dart';

abstract class BaseViewModel extends ChangeNotifier {
  BuildContext context;

  BaseViewModel(this.context);

  void update() {
    notifyListeners();
  }
}
