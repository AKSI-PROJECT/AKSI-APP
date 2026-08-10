import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService {
  static const String _key = 'aksi_history_items';

  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final ValueNotifier<List<HistoryItem>> historyNotifier = ValueNotifier([]);

  Future<void> init() async {
    final items = await getHistories();
    historyNotifier.value = items;
  }

  Future<void> saveHistory(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyStrings = prefs.getStringList(_key) ?? [];

    historyStrings.insert(0, item.toJson());

    if (historyStrings.length > 100) {
      historyStrings = historyStrings.sublist(0, 100);
    }

    await prefs.setStringList(_key, historyStrings);

    historyNotifier.value = [item, ...historyNotifier.value].take(100).toList();
  }

  Future<List<HistoryItem>> getHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings = prefs.getStringList(_key) ?? [];

    return historyStrings.map((str) => HistoryItem.fromJson(str)).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    historyNotifier.value = [];
  }
}
