class MentionModel {
  final String messageId;
  final String mentionText; // e.g., "@all" atau "@Sinister"
  final String? userId; // Opsional, hanya untuk mention user tertentu (bukan @all)

  MentionModel({
    required this.messageId,
    required this.mentionText,
    this.userId,
  });

  factory MentionModel.fromJson(Map<String, dynamic> json) {
    return MentionModel(
      messageId: json['message_id'],
      mentionText: json['mention_text'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'mention_text': mentionText,
      'user_id': userId,
    };
  }

  MentionModel copyWith({
    String? messageId,
    String? mentionText,
    String? userId,
  }) {
    return MentionModel(
      messageId: messageId ?? this.messageId,
      mentionText: mentionText ?? this.mentionText,
      userId: userId ?? this.userId,
    );
  }
}