class EmailReputationModel {
  final String id;
  final String emailAddress;
  final String domain;
  final int trustScore;
  final bool isVerifiedOfficial;
  final DateTime updatedAt;

  EmailReputationModel({
    required this.id,
    required this.emailAddress,
    required this.domain,
    required this.trustScore,
    required this.isVerifiedOfficial,
    required this.updatedAt,
  });

  factory EmailReputationModel.fromJson(Map<String, dynamic> json) {
    return EmailReputationModel(
      id: json['id'] as String,
      emailAddress: json['email_address'] as String,
      domain: json['domain'] as String,
      trustScore: json['trust_score'] as int? ?? 50,
      isVerifiedOfficial: json['is_verified_official'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email_address': emailAddress,
      'domain': domain,
      'trust_score': trustScore,
      'is_verified_official': isVerifiedOfficial,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class EmailTagModel {
  final String id;
  final String emailId;
  final String tagName;
  final int upvotes;
  final int downvotes;
  final bool isModerated;

  EmailTagModel({
    required this.id,
    required this.emailId,
    required this.tagName,
    required this.upvotes,
    required this.downvotes,
    required this.isModerated,
  });

  factory EmailTagModel.fromJson(Map<String, dynamic> json) {
    return EmailTagModel(
      id: json['id'] as String,
      emailId: json['email_id'] as String,
      tagName: json['tag_name'] as String,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      isModerated: json['is_moderated'] as bool? ?? false,
    );
  }
}
