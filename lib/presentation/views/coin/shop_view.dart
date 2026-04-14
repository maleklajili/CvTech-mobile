import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/coin_colors.dart';
import 'package:cv_tech/presentation/views/coin/purchase_confirmation_dialog.dart';
import 'package:cv_tech/presentation/views_models/coin/coin_view_model.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // Balance banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CoinColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CoinColors.border),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${vm.balance} coins disponibles',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CoinColors.dark,
                    ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: CoinColors.dark,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '🤖 Outils IA'),
                  Tab(text: '📄 Templates'),
                  Tab(text: '🚀 Boosts'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid(vm, vm.getShopItems(0)),
                  _buildGrid(vm, vm.getShopItems(1)),
                  _buildGrid(vm, vm.getShopItems(2)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(CoinViewModel vm, List<ShopItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildShopCard(context, vm, items[index]);
      },
    );
  }

  Widget _buildShopCard(BuildContext context, CoinViewModel vm, ShopItem item) {
    final canAfford = vm.canAfford(item.price);

    return GestureDetector(
      onTap: () => _showPurchaseDialog(context, item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isPopular ? CoinColors.border : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CoinColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _iconEmoji(item.icon),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                if (item.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CoinColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Populaire',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: canAfford ? CoinColors.gold : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${item.price}',
                    style: TextStyle(
                      color: canAfford ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, ShopItem item) {
    final vm = context.read<CoinViewModel>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: PurchaseConfirmationDialog(item: item),
      ),
    );
  }

  String _iconEmoji(IconLabel icon) {
    switch (icon) {
      case IconLabel.sparkle: return '✨';
      case IconLabel.fileText: return '📝';
      case IconLabel.palette: return '🎨';
      case IconLabel.search: return '🔍';
      case IconLabel.rocket: return '🚀';
      case IconLabel.star: return '⭐';
      case IconLabel.clock: return '⏰';
      case IconLabel.zap: return '⚡';
    }
  }
}
