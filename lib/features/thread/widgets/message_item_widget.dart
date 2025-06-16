import 'package:flutter/material.dart';
import '../../../config/themes/app_colors.dart';
import '../../../data/models/message_model.dart';
import '../providers/thread_provider.dart';
import 'thread_dialogs.dart';

class MessageItemWidget extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final bool showSenderInfo;
  final ThreadProvider threadProvider;
  final String? searchQuery; // ADDED: For search highlighting

  const MessageItemWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.showSenderInfo,
    required this.threadProvider,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (hanya tampil jika showSenderInfo dan bukan current user)
          if (showSenderInfo && !isCurrentUser)
            CircleAvatar(
              radius: 20,
              backgroundColor: _getAvatarColor(message.sender.name),
              child: Text(
                message.sender.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          else if (!isCurrentUser)
            const SizedBox(width: 40),
          
          const SizedBox(width: 12),
          
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: isCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Sender info (hanya tampil jika showSenderInfo dan bukan current user)
                if (showSenderInfo && !isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        // FIXED: Search highlighting for sender name
                        _buildHighlightedText(
                          message.sender.name,
                          searchQuery,
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.getFormattedTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Message bubble
                GestureDetector(
                  onLongPress: () => ThreadDialogs.showMessageOptions(context, message, threadProvider),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? AppColors.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Attachments (images/files) - FIXED: Better display
                        if (message.attachments?.isNotEmpty ?? false)
                          ...message.attachments!.map((attachment) => 
                              _buildAttachment(context, attachment)),
                        
                        // Text content - FIXED: Search highlighting
                        if (message.content.isNotEmpty)
                          _buildHighlightedText(
                            message.content,
                            searchQuery,
                            TextStyle(
                              color: isCurrentUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        
                        // Edited indicator
                        if (message.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '(edited)',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isCurrentUser 
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Time for current user messages
                if (isCurrentUser && showSenderInfo)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message.getFormattedTime(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ADDED: Widget untuk highlighting search terms
  Widget _buildHighlightedText(String text, String? searchQuery, TextStyle style) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    
    if (!lowerText.contains(lowerQuery)) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    int start = 0;
    
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        // Add remaining text
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }
      
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
          color: style.color,
        ),
      ));
      
      start = index + searchQuery.length;
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: spans,
      ),
    );
  }

  // FIXED: Better attachment display dengan error handling
  Widget _buildAttachment(BuildContext context, MessageAttachment attachment) {
    switch (attachment.fileType) {
      case FileType.image:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              attachment.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrentUser 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentUser 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 48,
                      color: isCurrentUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image failed to load',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentUser 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      
      default:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentUser 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            onTap: () {
              // ADDED: Show file options when tapped
              _showFileOptions(context, attachment);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(attachment.fileType),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getFileTypeIcon(attachment.fileType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            attachment.getFormattedSize(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrentUser 
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            attachment.fileType.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser 
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.download,
                  size: 16,
                  color: isCurrentUser 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
                ),
              ],
            ),
          ),
        );
    }
  }

  // ADDED: Show file options dialog
  void _showFileOptions(BuildContext context, MessageAttachment attachment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attachment.fileName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${attachment.getFormattedSize()} • ${attachment.fileType.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              subtitle: const Text('Save to device'),
              onTap: () {
                Navigator.pop(context);
                // Implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download functionality - needs backend integration')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              subtitle: const Text('Share with other apps'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality - needs backend integration')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: Get file type specific color
  Color _getFileTypeColor(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return Colors.green;
      case FileType.document:
        return Colors.blue;
      case FileType.audio:
        return Colors.purple;
      case FileType.video:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ADDED: Get file type specific icon
  IconData _getFileTypeIcon(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return Icons.image;
      case FileType.document:
        return Icons.description;
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.video:
        return Icons.videocam;
      default:
        return Icons.attach_file;
    }
  }

  // Generate consistent avatar colors based on name
  Color _getAvatarColor(String name) {
    // Simple hash function for consistent color
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }
}