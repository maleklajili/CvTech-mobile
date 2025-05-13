// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../base/base_view_model.dart';
import 'interfaces/main_interfaces.dart';

class ScrollListener extends BaseViewModel implements IScrollListentener {
  late ScrollController scrollController;
  double lastOffset = 0;
  bool isNavVisibile = true;

  ScrollListener(super.context);

  @override
  void initScrollListener() {
    scrollController = ScrollController();
    scrollController.addListener(scrollListener);
  }

  @override
  void scrollListener() {
    final offset = scrollController.offset;
    final isAtEnd = scrollController.position.pixels >=
        scrollController.position.maxScrollExtent;
    final shouldHide = offset > lastOffset || isAtEnd;

    if (shouldHide != !isNavVisibile) {
      isNavVisibile = !shouldHide;
      update();
    }
    lastOffset = offset;
  }
}
