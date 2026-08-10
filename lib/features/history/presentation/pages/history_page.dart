import 'package:flutter/material.dart';
import '../../domain/models/history_item.dart';
import '../../domain/services/history_service.dart';
import '../../../../core/widgets/fade_in_slide.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Dokumen', 'APK', 'Email', 'Tautan'];

  List<HistoryItem> _getFilteredItems(List<HistoryItem> allItems) {
    return allItems.where((item) {
      // Search filter
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Type filter
      bool matchesType = true;
      if (_selectedFilter == 'Dokumen') matchesType = item.type == HistoryType.document;
      if (_selectedFilter == 'APK') matchesType = item.type == HistoryType.apk;
      if (_selectedFilter == 'Email') matchesType = item.type == HistoryType.email;
      if (_selectedFilter == 'Tautan') matchesType = item.type == HistoryType.link;

      return matchesSearch && matchesType;
    }).toList();
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 1) {
      return '${timestamp.day} ${_getMonthName(timestamp.month)}';
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
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

  Widget _getTrailingIcon(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.safe:
        return const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981));
      case HistoryStatus.info:
        return const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6));
      case HistoryStatus.suspicious:
      case HistoryStatus.dangerous:
        return const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Aktivitas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lihat seluruh aktivitas pemeriksaan keamanan yang telah Anda lakukan.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Cari aktivitas...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ValueListenableBuilder<List<HistoryItem>>(
                valueListenable: _historyService.historyNotifier,
                builder: (context, allItems, _) {
                  final filteredItems = _getFilteredItems(allItems);

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            allItems.isEmpty ? 'Belum ada riwayat aktivitas' : 'Aktivitas tidak ditemukan',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // padding for bottom nav
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      
                      // Check if we need to show a date header
                      bool showHeader = false;
                      if (index == 0) {
                        showHeader = true;
                      } else {
                        final previousItem = filteredItems[index - 1];
                        final currentDay = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
                        final previousDay = DateTime(previousItem.timestamp.year, previousItem.timestamp.month, previousItem.timestamp.day);
                        if (currentDay != previousDay) {
                          showHeader = true;
                        }
                      }

                      return FadeInSlide(
                        delay: Duration(milliseconds: 100 + (index * 50).clamp(0, 500)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                                child: Text(
                                  _formatDateHeader(item.timestamp),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getColorForType(item.type),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconForType(item.type),
                                    color: _getIconColorForType(item.type),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${_formatTimeAgo(item.timestamp)} • ${item.description}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                trailing: _getTrailingIcon(item.status),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (itemDate == today) return 'Hari Ini';
    if (itemDate == yesterday) return 'Kemarin';
    return '${timestamp.day} ${_getMonthName(timestamp.month)} ${timestamp.year}';
  }
}

