class CommunityReport {
  final String id;
  final String? reporterId;
  final String emailId;
  final String categoryTag;
  final String evidenceUrl;
  final String? description;
  final String status;
  final DateTime createdAt;

  CommunityReport({
    required this.id,
    this.reporterId,
    required this.emailId,
    required this.categoryTag,
    required this.evidenceUrl,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    return CommunityReport(
      id: json['id'],
      reporterId: json['reporter_id'],
      emailId: json['email_id'],
      categoryTag: json['category_tag'],
      evidenceUrl: json['evidence_url'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
