// Flutter imports:
import 'package:flutter/material.dart';

abstract interface class IBottomNavigationBar {
  void changeCurrentIndex(int index);
}

abstract interface class IScrollListentener {
  void initScrollListener();
  void scrollListener();
}

abstract interface class IMainViewModel {
  Widget currentView();
}

abstract interface class IAppBarDrawer {
  GlobalKey<ScaffoldState> get scaffoldKey;
  bool get isDrawerOpen;
  void toggleDrawer();
}
