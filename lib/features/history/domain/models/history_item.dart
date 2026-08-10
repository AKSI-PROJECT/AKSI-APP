import 'dart:convert';

enum HistoryType { link, document, apk, email }

enum HistoryStatus { safe, suspicious, dangerous, info }

class HistoryItem {
  final String id;
  final HistoryType type;
  final String title;
  final String description;
  final HistoryStatus status;
  final DateTime timestamp;

  HistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'description': description,
      'status': status.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      type: HistoryType.values[map['type']],
      title: map['title'],
      description: map['description'],
      status: HistoryStatus.values[map['status']],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryItem.fromJson(String source) =>
      HistoryItem.fromMap(json.decode(source));
}
