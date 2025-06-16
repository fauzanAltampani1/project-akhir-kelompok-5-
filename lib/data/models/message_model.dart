import '../models/user_model.dart';
import '../models/mention_model.dart';

enum MessageType { text, image, file, system }
enum FileType { image, document, audio, video, other }

class MessageModel {
  final String id;
  final String threadId;
  final UserModel sender;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final List<MessageAttachment>? attachments;
  final String? replyToMessageId;
  final MessageModel? replyToMessage;
  final bool isUnread;
  final List<MentionModel> mentions;

  MessageModel({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.content,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.attachments,
    this.replyToMessageId,
    this.replyToMessage,
    this.isUnread = true,
    this.mentions = const [],
  });

  MessageModel copyWith({
    String? id,
    String? threadId,
    UserModel? sender,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    List<MessageAttachment>? attachments,
    String? replyToMessageId,
    MessageModel? replyToMessage,
    bool? isUnread,
    List<MentionModel>? mentions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      attachments: attachments ?? this.attachments,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isUnread: isUnread ?? this.isUnread,
      mentions: mentions ?? this.mentions,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      threadId: json['thread_id'],
      sender: UserModel.fromJson(json['sender']),
      content: json['content'],
      type: _getMessageTypeFromString(json['type']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isEdited: json['is_edited'] ?? false,
      attachments: (json['attachments'] as List?)
          ?.map((a) => MessageAttachment.fromJson(a))
          .toList(),
      replyToMessageId: json['reply_to_message_id'],
      replyToMessage: json['reply_to_message'] != null
          ? MessageModel.fromJson(json['reply_to_message'])
          : null,
      isUnread: json['is_unread'] ?? true,
      mentions: (json['mentions'] as List? ?? [])
          .map((m) => MentionModel.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_id': threadId,
      'sender': sender.toJson(),
      'content': content,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_edited': isEdited,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'reply_to_message_id': replyToMessageId,
      'reply_to_message': replyToMessage?.toJson(),
      'is_unread': isUnread,
      'mentions': mentions.map((m) => m.toJson()).toList(),
    };
  }

  static MessageType _getMessageTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  static List<MessageModel> getMinimalDummyMessages(String threadId) {
    final currentUser = UserModel.currentUser;
    final otherUser1 = UserModel(id: '1', name: 'Tombol', email: 'tombol@example.com');
    final otherUser2 = UserModel(id: '3', name: 'Emily', email: 'emily@example.com');

    return [
      MessageModel(
        id: 'msg-1',
        threadId: threadId,
        sender: otherUser1,
        content: "Hey team @all! How's the mobile app development going?",
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isUnread: true,
        mentions: [
          MentionModel(
            messageId: 'msg-1',
            mentionText: '@all',
          ),
        ],
      ),
      MessageModel(
        id: 'msg-2',
        threadId: threadId,
        sender: currentUser,
        content: 'Making good progress @username! Just finished the thread functionality.',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isUnread: false,
        mentions: [
          MentionModel(
            messageId: 'msg-2',
            mentionText: '@King',
            userId: '2',
          ),
        ],
      ),
      MessageModel(
        id: 'msg-3',
        threadId: 'project-1-1', // #UI thread
        sender: otherUser2,
        content: '@King, can you finish the UI prototype ASAP?',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isUnread: true,
        mentions: [
          MentionModel(
            messageId: 'msg-3',
            mentionText: '@King',
            userId: '2', // King
          ),
        ],
      ),
    ];
  }

  static List<MessageModel> getDummyMessages(String threadId) {
    return getMinimalDummyMessages(threadId);
  }
}

class MessageAttachment {
  final String id;
  final String fileName;
  final int fileSize; // Fixed: changed from file_size to fileSize
  final FileType fileType;
  final String url;
  final String? thumbnailUrl;
  final String? mimeType;

  MessageAttachment({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.url,
    this.thumbnailUrl,
    this.mimeType,
  });

  MessageAttachment copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    FileType? fileType,
    String? url,
    String? thumbnailUrl,
    String? mimeType,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      fileType: _getFileTypeFromString(json['file_type']),
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      mimeType: json['mime_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType.toString().split('.').last,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'mime_type': mimeType,
    };
  }

  static FileType _getFileTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'image':
        return FileType.image;
      case 'document':
        return FileType.document;
      case 'audio':
        return FileType.audio;
      case 'video':
        return FileType.video;
      default:
        return FileType.other;
    }
  }

  String getFormattedSize() {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1048576) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    if (fileSize < 1073741824) return '${(fileSize / 1048576).toStringAsFixed(1)}MB';
    return '${(fileSize / 1073741824).toStringAsFixed(1)}GB';
  }

  String getFileIcon() {
    switch (fileType) {
      case FileType.image:
        return '🖼️';
      case FileType.document:
        return '📄';
      case FileType.audio:
        return '🎵';
      case FileType.video:
        return '🎥';
      default:
        return '📎';
    }
  }
}