import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/coin_colors.dart';
import 'package:cv_tech/presentation/views_models/coin/coin_view_model.dart';

class MissionsView extends StatelessWidget {
  const MissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinViewModel>(
      builder: (context, vm, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStreakCard(vm),
            const SizedBox(height: 24),
            _buildSectionTitle('Missions quotidiennes'),
            const SizedBox(height: 12),
            ...vm.dailyMissions.map((m) => _buildMissionTile(m)),
            const SizedBox(height: 24),
            _buildSectionTitle('Missions verrouillées'),
            const SizedBox(height: 12),
            ...vm.lockedMissions.map((m) => _buildLockedMissionTile(m, vm)),
          ],
        );
      },
    );
  }

  Widget _buildStreakCard(CoinViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoinColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                'Série de ${vm.streakDays} jours',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CoinColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '+50 bonus à 7 jours consécutifs !',
            style: TextStyle(fontSize: 13, color: CoinColors.mid),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final active = vm.streakWeek[i];
              final dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
              return _buildDayCircle(dayLabels[i], active, i == vm.streakDays);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(String label, bool active, bool isNext) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? CoinColors.gold
                : isNext
                    ? Colors.white
                    : CoinColors.progressBg,
            border: isNext
                ? Border.all(color: CoinColors.border, width: 2)
                : null,
          ),
          child: Center(
            child: active
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isNext ? CoinColors.mid : Colors.grey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? CoinColors.gold : Colors.grey,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMissionTile(Mission mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mission.completed ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mission.completed
              ? const Color(0xFFBBF7D0)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mission.completed
                  ? CoinColors.greenCheck
                  : CoinColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              mission.completed ? Icons.check : _missionIcon(mission.id),
              color: mission.completed ? Colors.white : CoinColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration:
                        mission.completed ? TextDecoration.lineThrough : null,
                    color: mission.completed ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!mission.completed) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mission.progress,
                      minHeight: 6,
                      backgroundColor: CoinColors.progressBg,
                      valueColor:
                          const AlwaysStoppedAnimation(CoinColors.gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mission.completed
                  ? CoinColors.greenCheck.withValues(alpha: 0.1)
                  : CoinColors.cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mission.completed ? '✓ Fait' : '+${mission.reward}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: mission.completed ? CoinColors.greenCheck : CoinColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedMissionTile(Mission mission, CoinViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock, color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Niv. ${mission.requiredLevel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _missionIcon(String id) {
    switch (id) {
      case 'login': return Icons.login;
      case 'swipe': return Icons.swipe;
      case 'apply': return Icons.send;
      case 'cv_improve': return Icons.trending_up;
      case 'share': return Icons.share;
      default: return Icons.star;
    }
  }
}
