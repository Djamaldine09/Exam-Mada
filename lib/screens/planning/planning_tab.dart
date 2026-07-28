import 'package:flutter/material.dart';

import '../../model/candidat.dart';

class PlanningTab extends StatelessWidget {
  final Candidat? candidat;

  const PlanningTab({super.key, required this.candidat});

  @override
  Widget build(BuildContext context) {
    final planning = candidat?.planning ?? [];

    if (planning.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun planning disponible', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Votre planning apparaîtra ici une fois défini',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: planning.length,
      itemBuilder: (context, index) {
        final item = planning[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.book_outlined, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.matiere, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Épreuve', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PlanningChip(icon: Icons.calendar_today_outlined, label: item.date.toString().split(' ')[0]),
                    _PlanningChip(icon: Icons.schedule_outlined, label: '${item.heureDebut} - ${item.heureFin}'),
                    _PlanningChip(icon: Icons.timer_outlined, label: '${item.duree}h'),
                    _PlanningChip(icon: Icons.bar_chart_outlined, label: 'Coef. ${item.coefficient}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanningChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlanningChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
