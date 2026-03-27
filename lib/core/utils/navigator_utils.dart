import 'package:flutter/material.dart';

import '../../app.dart';

Future navigateTo(BuildContext? context, Widget view) {
  if (context != null) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => view),
    );
  }

  final navigator = mainState;
  if (navigator != null) {
    return navigator.push(
      MaterialPageRoute(builder: (context) => view),
    );
  }

  return Future.error(StateError('Navigator is not ready yet'));
}

Future navigateToDeleteTree(BuildContext? context, Widget view) {
  if (context != null) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => PopScope(canPop: false, child: view),
      ),
      (route) => false,
    );
  }

  final navigator = mainState;
  if (navigator != null) {
    return navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => PopScope(canPop: false, child: view),
      ),
      (route) => false,
    );
  }

  return Future.error(StateError('Navigator is not ready yet'));
}
