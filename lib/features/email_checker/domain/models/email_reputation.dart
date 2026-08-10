class EmailReputation {
  final String id;
  final String emailAddress;
  final String domain;
  final int trustScore;
  final bool isVerifiedOfficial;
  final DateTime updatedAt;

  EmailReputation({
    required this.id,
    required this.emailAddress,
    required this.domain,
    required this.trustScore,
    required this.isVerifiedOfficial,
    required this.updatedAt,
  });

  factory EmailReputation.fromJson(Map<String, dynamic> json) {
    return EmailReputation(
      id: json['id'],
      emailAddress: json['email_address'],
      domain: json['domain'],
      trustScore: json['trust_score'],
      isVerifiedOfficial: json['is_verified_official'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
