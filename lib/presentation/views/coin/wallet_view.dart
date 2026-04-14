import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/coin_colors.dart';
import 'package:cv_tech/data/models/transaction_model.dart';
import 'package:cv_tech/presentation/views_models/coin/coin_view_model.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinViewModel>(
      builder: (context, vm, _) {
        if (vm.state == CoinState.loading && vm.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.state == CoinState.error && vm.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vm.errorMessage ?? 'Erreur'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: vm.loadData,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBalanceCard(vm),
              const SizedBox(height: 16),
              _buildLevelCard(vm),
              const SizedBox(height: 24),
              _buildActivitySection(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(CoinViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CoinColors.gold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Solde Total',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🪙', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Text(
                '${vm.balance}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'coins',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBalanceStat('Gagnés', _sumByType(vm, TransactionType.earned)),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildBalanceStat('Dépensés', _sumByType(vm, TransactionType.spent)),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildBalanceStat('Ce mois', _monthlyEarnings(vm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLevelCard(CoinViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoinColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoinColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${vm.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Niveau ${vm.level} — ${vm.levelName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: CoinColors.dark,
                      ),
                    ),
                    Text(
                      '${(vm.levelProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CoinColors.mid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.levelProgress,
                    minHeight: 8,
                    backgroundColor: CoinColors.progressBg,
                    valueColor: const AlwaysStoppedAnimation(CoinColors.gold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.level >= 5
                      ? 'Niveau maximum atteint !'
                      : '${vm.nextLevelThreshold - vm.balance} coins pour le niveau ${vm.level + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CoinColors.mid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(CoinViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (vm.transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune activité pour le moment',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...vm.transactions.map((t) => _buildTransactionTile(t)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isEarned = tx.type == TransactionType.earned;
    final color = isEarned ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final sign = isEarned ? '+' : '-';

    IconData icon;
    Color bgColor;
    if (isEarned) {
      icon = Icons.arrow_downward;
      bgColor = const Color(0xFFDCFCE7);
    } else {
      icon = Icons.arrow_upward;
      bgColor = const Color(0xFFFEE2E2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tx.createdAt != null)
                  Text(
                    _formatDate(tx.createdAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$sign${tx.amount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _sumByType(CoinViewModel vm, TransactionType type) {
    return vm.transactions
        .where((t) => t.type == type)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int _monthlyEarnings(CoinViewModel vm) {
    final now = DateTime.now();
    return vm.transactions
        .where((t) =>
            t.type == TransactionType.earned &&
            t.createdAt != null &&
            t.createdAt!.month == now.month &&
            t.createdAt!.year == now.year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}
