class EmailTag {
  final String id;
  final String emailId;
  final String tagName;
  final int upvotes;
  final int downvotes;

  EmailTag({
    required this.id,
    required this.emailId,
    required this.tagName,
    required this.upvotes,
    required this.downvotes,
  });

  factory EmailTag.fromJson(Map<String, dynamic> json) {
    return EmailTag(
      id: json['id'],
      emailId: json['email_id'],
      tagName: json['tag_name'],
      upvotes: json['upvotes'],
      downvotes: json['downvotes'],
    );
  }
}
