import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/coin_colors.dart';
import 'package:cv_tech/presentation/views/coin/wallet_view.dart';
import 'package:cv_tech/presentation/views/coin/missions_view.dart';
import 'package:cv_tech/presentation/views/coin/shop_view.dart';
import 'package:cv_tech/presentation/views_models/coin/coin_view_model.dart';

/// Entry point that provides its own [CoinViewModel].
class CoinMainView extends StatelessWidget {
  const CoinMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CoinViewModel()..loadData(),
      child: const _CoinMainBody(),
    );
  }
}

class _CoinMainBody extends StatefulWidget {
  const _CoinMainBody();

  @override
  State<_CoinMainBody> createState() => _CoinMainBodyState();
}

class _CoinMainBodyState extends State<_CoinMainBody> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    WalletView(),
    MissionsView(),
    ShopView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Coins'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: CoinColors.gold,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Portefeuille',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag),
              label: 'Missions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Boutique',
            ),
          ],
        ),
      ),
    );
  }
}
