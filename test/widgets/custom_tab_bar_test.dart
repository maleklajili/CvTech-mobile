import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/presentation/widgets/custom_tab_bar.dart';

void main() {
  group('CustomTabBar Tests', () {
    testWidgets('CustomTabBar displays all tabs', (WidgetTester tester) async {
      final tabController = TabController(length: 3, vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: CustomTabBar(
                controller: tabController,
                tabs: const [
                  Tab(text: 'Tab 1'),
                  Tab(text: 'Tab 2'),
                  Tab(text: 'Tab 3'),
                ],
              ),
            ),
            body: TabBarView(
              controller: tabController,
              children: const [
                Center(child: Text('Content 1')),
                Center(child: Text('Content 2')),
                Center(child: Text('Content 3')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
      expect(find.text('Tab 3'), findsOneWidget);
    });

    testWidgets('CustomTabBar switches tabs on tap', (WidgetTester tester) async {
      final tabController = TabController(length: 3, vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: CustomTabBar(
                controller: tabController,
                tabs: const [
                  Tab(text: 'Tab 1'),
                  Tab(text: 'Tab 2'),
                  Tab(text: 'Tab 3'),
                ],
              ),
            ),
            body: TabBarView(
              controller: tabController,
              children: const [
                Center(child: Text('Content 1')),
                Center(child: Text('Content 2')),
                Center(child: Text('Content 3')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Content 1'), findsOneWidget);

      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(tabController.index, equals(1));
    });

    testWidgets('CustomTabBar supports scrollable tabs',
        (WidgetTester tester) async {
      final tabController = TabController(length: 5, vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: CustomTabBar(
                controller: tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Tab 1'),
                  Tab(text: 'Tab 2'),
                  Tab(text: 'Tab 3'),
                  Tab(text: 'Tab 4'),
                  Tab(text: 'Tab 5'),
                ],
              ),
            ),
            body: TabBarView(
              controller: tabController,
              children: const [
                Center(child: Text('Content 1')),
                Center(child: Text('Content 2')),
                Center(child: Text('Content 3')),
                Center(child: Text('Content 4')),
                Center(child: Text('Content 5')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 5'), findsOneWidget);
    });

    testWidgets('CustomTabBar calls onTap callback',
        (WidgetTester tester) async {
      final tabController = TabController(length: 3, vsync: tester);
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: CustomTabBar(
                controller: tabController,
                tabs: const [
                  Tab(text: 'Tab 1'),
                  Tab(text: 'Tab 2'),
                  Tab(text: 'Tab 3'),
                ],
                onTap: (index) {
                  tappedIndex = index;
                },
              ),
            ),
            body: TabBarView(
              controller: tabController,
              children: const [
                Center(child: Text('Content 1')),
                Center(child: Text('Content 2')),
                Center(child: Text('Content 3')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(1));
    });
  });
}
