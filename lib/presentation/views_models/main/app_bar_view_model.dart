// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../base/base_view_model.dart';
import 'interfaces/main_interfaces.dart';

class AppBarViewModel extends BaseViewModel implements IAppBarDrawer {
  late GlobalKey<ScaffoldState> _scaffoldKey;

  AppBarViewModel(super.context) {
    _scaffoldKey = GlobalKey<ScaffoldState>();
  }

  @override
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  @override
  bool get isDrawerOpen => scaffoldKey.currentState?.isDrawerOpen ?? false;

  @override
  void toggleDrawer() {
    if (isDrawerOpen) {
      scaffoldKey.currentState?.closeDrawer();
    } else {
      scaffoldKey.currentState?.openDrawer();
    }
    update();
  }
}
