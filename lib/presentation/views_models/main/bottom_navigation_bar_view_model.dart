// Project imports:
import 'package:cv_tech/presentation/views_models/main/interfaces/main_interfaces.dart';
import 'scroll_listener.dart';

class BottomNavigationBarViewModel extends ScrollListener
    implements IBottomNavigationBar {
  BottomNavigationBarViewModel(super.context) {
    initScrollListener();
  }
  int currentIndex = 0;

  int get bottomnavItemLenght => 6;
  @override
  void changeCurrentIndex(int index) {
    currentIndex = index;
    update();
  }
}
