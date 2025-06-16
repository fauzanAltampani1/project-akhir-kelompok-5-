import 'package:flutter/material.dart';
import '../../../data/models/thread_model.dart';
import '../../../data/models/thread_member_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/mention_model.dart';
import 'dart:io';

class ThreadProvider with ChangeNotifier {
  String _selectedThreadId = 'hq-1-1';
  bool _showMembersSidebar = false;
  List<ThreadModel> _threads = ThreadModel.dummyThreads;
  final Map<String, List<MessageModel>> _threadMessages = {};
  
  int _subThreadCounter = 0;
  
  String _searchQuery = '';
  final List<MessageModel> _filteredMessages = [];
  
  String get selectedThreadId => _selectedThreadId;
  bool get showMembersSidebar => _showMembersSidebar;
  List<ThreadModel> get threads => _threads;
  Map<String, List<MessageModel>> get threadMessages => _threadMessages;
  String get searchQuery => _searchQuery;
  
  List<MessageModel> get selectedThreadMessages {
    final messages = _threadMessages[_selectedThreadId] ?? [];
    if (_searchQuery.isEmpty) {
      return messages;
    }
    return messages.where((message) => 
      message.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      message.sender.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }
  
  List<ThreadModel> get hqThreads {
    return _threads.where((thread) => thread.type == ThreadType.hq).toList();
  }
  
  List<ThreadModel> get projectThreads {
    return _threads.where((thread) => thread.type == ThreadType.project).toList();
  }
  
  List<ThreadModel> get rootHqThreads {
    return hqThreads.where((thread) => thread.parentThreadId == null).toList();
  }
  
  List<ThreadModel> get rootProjectThreads {
    return projectThreads.where((thread) => thread.parentThreadId == null).toList();
  }
  
  List<ThreadModel> getSubThreads(String parentThreadId) {
    return _threads.where((thread) => thread.parentThreadId == parentThreadId).toList();
  }
  
  ThreadModel? get selectedThread {
    try {
      return _threads.firstWhere((t) => t.id == _selectedThreadId);
    } catch (e) {
      return null;
    }
  }
  
  String getParentThreadName(String threadId) {
    final thread = _threads.firstWhere((t) => t.id == threadId, orElse: () => ThreadModel.dummyThreads[0]);
    if (thread.parentThreadId != null) {
      final parentThread = _threads.firstWhere(
        (t) => t.id == thread.parentThreadId, 
        orElse: () => ThreadModel.dummyThreads[0]
      );
      return parentThread.name;
    }
    return thread.name;
  }
  
  String getRootThreadId(String threadId) {
    final thread = _threads.firstWhere((t) => t.id == threadId, orElse: () => ThreadModel.dummyThreads[0]);
    
    print('🔍 DEBUG getRootThreadId: thread=${thread.name}, parentId=${thread.parentThreadId}');
    
    if (thread.parentThreadId != null) {
      final rootId = getRootThreadId(thread.parentThreadId!);
      print('🔍 DEBUG getRootThreadId: recursively found rootId=$rootId');
      return rootId;
    }
    
    print('🔍 DEBUG getRootThreadId: this is root thread: ${thread.id}');
    return thread.id;
  }
  
  ThreadModel? getRootThread(String threadId) {
    final rootId = getRootThreadId(threadId);
    print('🔍 DEBUG getRootThread: looking for rootId=$rootId');
    
    try {
      final rootThread = _threads.firstWhere((t) => t.id == rootId);
      print('🔍 DEBUG getRootThread: found root thread=${rootThread.name} (${rootThread.id})');
      return rootThread;
    } catch (e) {
      print('🔍 DEBUG getRootThread: ERROR finding root thread: $e');
      return null;
    }
  }
  
  String getThreadPath(String threadId) {
    final thread = _threads.firstWhere((t) => t.id == threadId, orElse: () => ThreadModel.dummyThreads[0]);
    if (thread.parentThreadId != null) {
      final parentName = getParentThreadName(threadId);
      return '$parentName > ${thread.name}';
    }
    return thread.name;
  }
  
  List<ThreadMemberModel> get activeMembers {
    return selectedThread?.members ?? [];
  }
  
  Map<MemberRole, List<ThreadMemberModel>> get groupedMembers {
    final members = activeMembers;
    return {
      MemberRole.admin: members.where((m) => m.role == MemberRole.admin).toList(),
      MemberRole.custom: members.where((m) => m.role == MemberRole.custom).toList(),
      MemberRole.member: members.where((m) => m.role == MemberRole.member).toList(),
    };
  }

  MessageModel? getThreadSummaryMessage(String threadId) {
    final threadMessages = _threadMessages[threadId] ?? [];
    if (threadMessages.isEmpty) return null;

    // Urutkan berdasarkan waktu (ascending: pesan lama di awal, pesan baru di akhir)
    threadMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Cari mention yang belum dibaca untuk current user atau @all
    final unreadMention = threadMessages.lastWhere(
      (msg) =>
          msg.isUnread &&
          msg.mentions.any((mention) =>
              mention.mentionText == '@all' ||
              mention.userId == UserModel.currentUser.id),
      orElse: () => threadMessages.last,
    );

    return unreadMention;
  }

  ({MessageModel? message, String? subThreadName}) getLatestSubThreadMessage(String parentThreadId) {
    final subThreads = getSubThreads(parentThreadId);
    if (subThreads.isEmpty) return (message: null, subThreadName: null);

    MessageModel? latestMessage;
    String? latestSubThreadName;
    DateTime? latestTime;

    for (final subThread in subThreads) {
      final messages = _threadMessages[subThread.id] ?? [];
      if (messages.isEmpty) continue;

      // Urutkan pesan ascending (pesan terbaru di akhir)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Cari pesan dengan mention yang belum dibaca dulu
      MessageModel? messageWithMention;
      try {
        messageWithMention = messages.lastWhere(
          (msg) =>
              msg.isUnread &&
              msg.mentions.any((mention) =>
                  mention.mentionText == '@all' ||
                  mention.userId == UserModel.currentUser.id),
        );
      } catch (e) {
        messageWithMention = null;
      }

      // Ambil pesan terbaru (dengan atau tanpa mention)
      final candidateMessage = messageWithMention ?? messages.last;

      // Bandingkan dengan pesan terbaru sejauh ini
      if (latestTime == null || candidateMessage.createdAt.isAfter(latestTime)) {
        latestMessage = candidateMessage;
        latestSubThreadName = subThread.name;
        latestTime = candidateMessage.createdAt;
      }
    }

    return (message: latestMessage, subThreadName: latestSubThreadName);
  }
  
  void toggleMembersSidebar() {
    _showMembersSidebar = !_showMembersSidebar;
    notifyListeners();
  }
  
  void searchMessages(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
  
  void selectThread(String threadId) {
    _selectedThreadId = threadId;
    _searchQuery = '';
    
    if (!_threadMessages.containsKey(threadId)) {
      _threadMessages[threadId] = MessageModel.getMinimalDummyMessages(threadId);
    }

    // Tandai semua pesan sebagai dibaca
    _threadMessages[threadId] = _threadMessages[threadId]!.map((msg) {
      return msg.copyWith(isUnread: false);
    }).toList();
    
    notifyListeners();
  }

  Future<void> sendMessage({
    required String content,
    MessageType type = MessageType.text,
    List<MessageAttachment>? attachments,
    String? replyToMessageId,
  }) async {
    if (content.trim().isEmpty && (attachments?.isEmpty ?? true)) return;
    
    final messageId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = UserModel.currentUser;
    
    final newMessage = MessageModel(
      id: messageId,
      threadId: _selectedThreadId,
      sender: currentUser,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      attachments: attachments,
      replyToMessageId: replyToMessageId,
      isUnread: true,
      mentions: _extractMentions(content, messageId),
    );
    
    if (!_threadMessages.containsKey(_selectedThreadId)) {
      _threadMessages[_selectedThreadId] = [];
    }
    _threadMessages[_selectedThreadId]!.add(newMessage);
    
    // Urutkan pesan berdasarkan createdAt (ascending: pesan lama di awal, pesan baru di akhir)
    _threadMessages[_selectedThreadId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    notifyListeners();
  }

  List<MentionModel> _extractMentions(String content, String messageId) {
    final mentions = <MentionModel>[];
    final words = content.split(' ');

    for (var word in words) {
      if (word.startsWith('@')) {
        final mentionText = word;
        String? userId;

        if (mentionText == '@all') {
          mentions.add(MentionModel(
            messageId: messageId,
            mentionText: mentionText,
          ));
        } else {
          final mentionedUser = ThreadMemberModel.dummyMembers.firstWhere(
            (member) => '@${member.user.name}' == mentionText,
            orElse: () => ThreadMemberModel(
              user: UserModel(id: '', name: '', email: ''),
              role: MemberRole.member,
              status: MemberStatus.offline,
              lastActive: DateTime.now(),
            ),
          );
          if (mentionedUser.user.id.isNotEmpty) {
            userId = mentionedUser.user.id;
            mentions.add(MentionModel(
              messageId: messageId,
              mentionText: mentionText,
              userId: userId,
            ));
          }
        }
      }
    }

    return mentions;
  }
  
  Future<void> sendImageMessage({
    required File imageFile,
    String? caption,
  }) async {
    final attachment = MessageAttachment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      fileName: imageFile.path.split('/').last,
      fileSize: await imageFile.length(),
      fileType: FileType.image,
      url: '/api/placeholder/300/200',
      mimeType: 'image/${imageFile.path.split('.').last}',
    );
    
    await sendMessage(
      content: caption ?? 'Image shared',
      type: MessageType.image,
      attachments: [attachment],
    );
  }
  
  Future<void> sendFileMessage({
    required File file,
    String? caption,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    FileType fileType;
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      fileType = FileType.image;
    } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      fileType = FileType.document;
    } else if (['mp3', 'wav', 'aac', 'm4a'].contains(extension)) {
      fileType = FileType.audio;
    } else if (['mp4', 'avi', 'mov', 'mkv'].contains(extension)) {
      fileType = FileType.video;
    } else {
      fileType = FileType.other;
    }
    
    final attachment = MessageAttachment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      fileName: file.path.split('/').last,
      fileSize: await file.length(),
      fileType: fileType,
      url: file.path,
      mimeType: _getMimeType(extension),
    );
    
    await sendMessage(
      content: caption ?? 'File shared: ${attachment.fileName}',
      type: MessageType.file,
      attachments: [attachment],
    );
  }
  
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  String _generateUniqueSubThreadId(String parentId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counter = ++_subThreadCounter;
    return '$parentId-sub-$timestamp-$counter';
  }

  Future<void> createHQThread({
    required String name,
    String? description,
    List<ThreadMemberModel>? members,
    List<String>? customSubThreads,
  }) async {
    final String threadId = 'hq-${DateTime.now().millisecondsSinceEpoch}';
    
    final newThread = ThreadModel(
      id: threadId,
      name: name,
      type: ThreadType.hq,
      members: members ?? ThreadMemberModel.dummyMembers,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: description,
    );
    
    _threads.add(newThread);
    // Inisialisasi _threadMessages
    if (!_threadMessages.containsKey(threadId)) {
      _threadMessages[threadId] = [];
    }
    print('🔧 DEBUG: Root HQ thread created: $threadId');
    
    final subThreadsToCreate = customSubThreads ?? ['#general', '#tasks', '#updates'];
    
    for (int i = 0; i < subThreadsToCreate.length; i++) {
      String subThreadName = subThreadsToCreate[i];
      
      // Tambah delay lebih lama biar timestamp pasti berbeda
      await Future.delayed(const Duration(milliseconds: 5));
      
      await _createSubThreadInternal(
        parentId: threadId,
        name: subThreadName,
        description: _getDefaultDescription(subThreadName),
        members: newThread.members,
      );
      
      print('🔧 DEBUG: Created sub-thread ${i + 1}/${subThreadsToCreate.length}: $subThreadName');
    }
    
    print('🔧 DEBUG: All sub-threads created for $threadId');
    print('🔧 DEBUG: Total threads after creation: ${_threads.length}');
    
    notifyListeners();
  }

  Future<void> _createSubThreadInternal({
    required String parentId,
    required String name,
    String? description,
    List<ThreadMemberModel>? members,
  }) async {
    final parentThread = _threads.firstWhere((t) => t.id == parentId);
    
    final threadType = parentThread.type;
    
    final threadId = _generateUniqueSubThreadId(parentId);
    
    print('🔧 DEBUG: Creating sub-thread "$name" with ID: $threadId');
    
    final newThread = ThreadModel(
      id: threadId,
      name: name,
      type: threadType,
      parentThreadId: parentId,
      projectId: parentThread.projectId,
      members: members ?? parentThread.members,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: description,
    );
    
    _threads.add(newThread);
    // Inisialisasi _threadMessages
    if (!_threadMessages.containsKey(threadId)) {
      _threadMessages[threadId] = [];
    }
    print('🔧 DEBUG: Sub-thread added to _threads, total: ${_threads.length}');
  }

  Future<void> createSubThread({
    required String parentId,
    required String name,
    String? description,
    List<ThreadMemberModel>? members,
  }) async {
    print('🔧 DEBUG: Creating individual sub-thread "$name" for parent "$parentId"');
    
    await _createSubThreadInternal(
      parentId: parentId,
      name: name,
      description: description,
      members: members,
    );
    
    print('🔧 DEBUG: Individual sub-thread created');
    print('🔧 DEBUG: Sub-threads for $parentId: ${getSubThreads(parentId).map((t) => '${t.name}(${t.id})').toList()}');
    
    notifyListeners();
    
    print('🔧 DEBUG: notifyListeners() called for individual sub-thread creation');
  }

  String _getDefaultDescription(String subThreadName) {
    final name = subThreadName.toLowerCase();
    if (name.contains('lobby')) return 'General discussion';
    if (name.contains('announcement')) return 'Important announcements';
    if (name.contains('brainstorm')) return 'Ideas and brainstorming';
    return 'Thread discussion';
  }

  Future<void> updateMemberRole({
    required String threadId,
    required String userId,
    required MemberRole role,
    String? customRole,
    Color? roleColor,
  }) async {
    final threadIndex = _threads.indexWhere((t) => t.id == threadId);
    if (threadIndex == -1) return;
    
    final memberIndex = _threads[threadIndex].members.indexWhere((m) => m.user.id == userId);
    if (memberIndex == -1) return;
    
    final updatedMember = _threads[threadIndex].members[memberIndex].copyWith(
      role: role,
      customRole: customRole,
      roleColor: roleColor,
    );
    
    final updatedMembers = List<ThreadMemberModel>.from(_threads[threadIndex].members);
    updatedMembers[memberIndex] = updatedMember;
    
    _threads[threadIndex] = _threads[threadIndex].copyWith(
      members: updatedMembers,
      updatedAt: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  Future<void> fetchThreads() async {
    _threads = ThreadModel.dummyThreads;
    
    for (final thread in _threads) {
      if (!_threadMessages.containsKey(thread.id)) {
        _threadMessages[thread.id] = MessageModel.getMinimalDummyMessages(thread.id);
      }
    }
    
    notifyListeners();
  }
  
  Future<void> fetchThreadMessages(String threadId) async {
    if (!_threadMessages.containsKey(threadId)) {
      _threadMessages[threadId] = MessageModel.getMinimalDummyMessages(threadId);
      notifyListeners();
    }
  }
  
  Future<void> fetchThreadMembers(String threadId) async {
    notifyListeners();
  }
  
  Future<void> deleteMessage(String messageId) async {
    final messages = _threadMessages[_selectedThreadId];
    if (messages != null) {
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        messages.removeAt(messageIndex);
        notifyListeners();
      }
    }
  }
  
  Future<void> editMessage(String messageId, String newContent) async {
    final messages = _threadMessages[_selectedThreadId];
    if (messages != null) {
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final originalMessage = messages[messageIndex];
        
        messages[messageIndex] = originalMessage.copyWith(
          content: newContent,
          isEdited: true,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }
}