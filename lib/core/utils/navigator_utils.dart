import 'package:flutter/material.dart';

import '../../app.dart';

Future navigateTo(BuildContext? context, Widget view) {
  return Navigator.of(context ?? mainContext).push(
    MaterialPageRoute(builder: (context) => view),
  );
}

Future navigateToDeleteTree(BuildContext? context, Widget view) {
  return Navigator.of(context ?? mainContext).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => PopScope(canPop: false, child: view),
    ),
    (route) => false,
  );
}
