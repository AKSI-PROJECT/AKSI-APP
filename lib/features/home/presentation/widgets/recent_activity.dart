import 'package:flutter/material.dart';
import '../../../../features/history/domain/models/history_item.dart';
import '../../../../features/history/domain/services/history_service.dart';

class RecentActivity extends StatelessWidget {
  final VoidCallback? onViewAll;

  const RecentActivity({super.key, this.onViewAll});

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 1) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  IconData _getIconForType(HistoryType type) {
    switch (type) {
      case HistoryType.link: return Icons.link_rounded;
      case HistoryType.document: return Icons.document_scanner_rounded;
      case HistoryType.apk: return Icons.android_rounded;
      case HistoryType.email: return Icons.email_rounded;
    }
  }

  Color _getColorForType(HistoryType type) {
    switch (type) {
      case HistoryType.link: return const Color(0xFFE0E7FF);
      case HistoryType.document: return const Color(0xFFF3F4F6);
      case HistoryType.apk: return const Color(0xFFF1F5F9);
      case HistoryType.email: return const Color(0xFFF3E8FF);
    }
  }
  
  Color _getIconColorForType(HistoryType type) {
    switch (type) {
      case HistoryType.link: return const Color(0xFF4F46E5);
      case HistoryType.document: return const Color(0xFF6B7280);
      case HistoryType.apk: return const Color(0xFF64748B);
      case HistoryType.email: return const Color(0xFF9333EA);
    }
  }

  IconData _getTrailingIcon(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.safe: return Icons.check_circle_outline_rounded;
      case HistoryStatus.info: return Icons.info_outline_rounded;
      case HistoryStatus.suspicious:
      case HistoryStatus.dangerous: return Icons.warning_amber_rounded;
    }
  }

  Color _getTrailingColor(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.safe: return const Color(0xFF10B981);
      case HistoryStatus.info: return const Color(0xFF3B82F6);
      case HistoryStatus.suspicious:
      case HistoryStatus.dangerous: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<HistoryItem>>(
          valueListenable: HistoryService().historyNotifier,
          builder: (context, items, _) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history_rounded, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text('Belum ada riwayat aktivitas', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final topItems = items.take(2).toList();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                children: List.generate(topItems.length, (index) {
                  final item = topItems[index];
                  return _buildActivityItem(
                    title: item.title,
                    subtitle: '${_formatTimeAgo(item.timestamp)} • ${item.description}',
                    icon: _getIconForType(item.type),
                    iconBgColor: _getColorForType(item.type),
                    iconColor: _getIconColorForType(item.type),
                    statusIcon: _getTrailingIcon(item.status),
                    statusColor: _getTrailingColor(item.status),
                    showBorder: index != topItems.length - 1,
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required IconData statusIcon,
    required Color statusColor,
    required bool showBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ],
      ),
    );
  }
}

