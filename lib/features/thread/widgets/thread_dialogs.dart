import 'package:flutter/material.dart';
import '../../../config/themes/app_colors.dart';
import '../../../data/models/thread_member_model.dart';
import '../../../data/models/message_model.dart';
import '../providers/thread_provider.dart';

class ThreadDialogs {
  // FIXED: Active search dialog dengan real functionality
  static void showSearchDialog(BuildContext context, ThreadProvider threadProvider) {
    final searchController = TextEditingController(text: threadProvider.searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Search Messages'),
                const Spacer(),
                if (threadProvider.searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      searchController.clear();
                      threadProvider.clearSearch();
                      setState(() {});
                    },
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search input
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search messages, sender names...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                threadProvider.clearSearch();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      threadProvider.searchMessages(value);
                      setState(() {});
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Search results preview
                  if (threadProvider.searchQuery.isNotEmpty) ...[
                    Text(
                      'Found ${threadProvider.selectedThreadMessages.length} messages',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Preview results
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: threadProvider.selectedThreadMessages.take(5).length,
                        itemBuilder: (context, index) {
                          final message = threadProvider.selectedThreadMessages[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: _getAvatarColor(message.sender.name),
                              child: Text(
                                message.sender.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              message.sender.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _highlightSearchTerm(message.content, threadProvider.searchQuery),
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              message.getFormattedTime(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    if (threadProvider.selectedThreadMessages.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+ ${threadProvider.selectedThreadMessages.length - 5} more messages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter keywords to search messages',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  threadProvider.clearSearch();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Tetap apply search filter saat close dialog
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper untuk highlight search term
  static String _highlightSearchTerm(String content, String searchTerm) {
    if (searchTerm.isEmpty) return content;
    // Untuk preview sederhana, kita return content biasa
    // Di implementasi real bisa pakai RichText dengan highlighting
    return content;
  }

  // Helper untuk avatar color
  static Color _getAvatarColor(String name) {
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }

  // CLEAN: Show more options menu - REMOVED DEBUG INFO
  static void showMoreOptions(BuildContext context, ThreadProvider provider) {
    final selectedThread = provider.selectedThread;
    final isAdmin = selectedThread?.members
        .any((member) => 
            member.user.id == '1' && // Gunakan UserModel.currentUser.id di implementasi nyata
            member.role == MemberRole.admin) ?? false;

    // Get ROOT THREAD untuk add sub-thread
    final rootThread = selectedThread != null ? provider.getRootThread(selectedThread.id) : null;
    final rootThreadName = rootThread?.name ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Thread Options',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            
            // Create New HQ Thread
            ListTile(
              leading: const Icon(Icons.add_circle, color: AppColors.primary),
              title: const Text('Create New HQ Thread'),
              subtitle: const Text('Start a global thread not linked to any project'),
              onTap: () {
                Navigator.pop(context);
                showCreateHQThreadDialog(context, provider);
              },
            ),
            
            // Add Sub-Thread - Always add to ROOT THREAD
            if (rootThread != null)
              ListTile(
                leading: const Icon(Icons.subdirectory_arrow_right, color: AppColors.secondary),
                title: const Text('Add Sub-Thread'),
                subtitle: Text('Add sub-thread to $rootThreadName'),
                enabled: isAdmin,
                onTap: isAdmin ? () {
                  Navigator.pop(context);
                  showCreateSubThreadDialog(context, provider, rootThread.id);
                } : null,
              ),
            
            // Manage Members - Use root thread
            if (rootThread != null)
              ListTile(
                leading: const Icon(Icons.people_alt, color: Colors.orange),
                title: const Text('Manage Members'),
                subtitle: Text('Manage members of $rootThreadName'),
                enabled: isAdmin,
                onTap: isAdmin ? () {
                  Navigator.pop(context);
                  showManageMembersDialog(context, provider, rootThread.id);
                } : null,
              ),
                
            // Thread Settings
            if (selectedThread != null)
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Thread Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // Tampilkan dialog settings
                },
              ),
          ],
        );
      }
    );
  }

  // Show message options (edit, delete, reply, etc.)
  static void showMessageOptions(BuildContext context, MessageModel message, ThreadProvider threadProvider) {
    final isCurrentUser = message.sender.id == '1'; // UserModel.currentUser.id
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  showEditMessageDialog(context, message, threadProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  showDeleteMessageDialog(context, message, threadProvider);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Implement reply functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                // Implement copy functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  // Create HQ Thread Dialog - FIXED: No auto-select first subthread
  static void showCreateHQThreadDialog(BuildContext context, ThreadProvider provider) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final List<String> customSubThreads = ['lobby', 'announcement', 'brainstorm']; // Default
    final subThreadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New HQ Thread'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Thread Name',
                        hintText: 'e.g., FLIP KING',
                        prefixText: '#',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Brief description of this thread',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Custom Sub-Threads Section
                    const Text(
                      'Sub-Threads',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sub-threads will be created automatically:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // List of sub-threads
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: customSubThreads.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                            title: Text(customSubThreads[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: customSubThreads.length > 1 ? () {
                                setState(() {
                                  customSubThreads.removeAt(index);
                                });
                              } : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Add sub-thread input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subThreadController,
                            decoration: const InputDecoration(
                              hintText: 'Add sub-thread name',
                              prefixText: '#',
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty && !customSubThreads.contains(value.trim())) {
                                setState(() {
                                  customSubThreads.add(value.trim());
                                  subThreadController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final value = subThreadController.text.trim();
                            if (value.isNotEmpty && !customSubThreads.contains(value)) {
                              setState(() {
                                customSubThreads.add(value);
                                subThreadController.clear();
                              });
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final threadName = name.startsWith('#') ? name : '#$name';
                    
                    // Create HQ thread with custom sub-threads
                    await provider.createHQThread(
                      name: threadName,
                      description: descriptionController.text.trim().isEmpty 
                          ? null 
                          : descriptionController.text.trim(),
                      customSubThreads: customSubThreads,
                    );
                    
                    // FIXED: Select ROOT thread, not first sub-thread
                    final newRootThread = provider.threads.lastWhere(
                      (thread) => thread.name == threadName && thread.parentThreadId == null,
                    );
                    provider.selectThread(newRootThread.id);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('HQ Thread "$threadName" created successfully!')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Create Sub-Thread Dialog - CLEAN VERSION
  static void showCreateSubThreadDialog(BuildContext context, ThreadProvider provider, String parentId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    // Get parent thread info
    final parentThread = provider.threads.firstWhere((t) => t.id == parentId, orElse: () => provider.threads.first);
    
    // Validation: Ensure parentId is ROOT THREAD
    if (parentThread.parentThreadId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Cannot create sub-thread under sub-thread!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Sub-Thread'),
            Text(
              'Adding to: ${parentThread.name}',
              style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Sub-Thread Name',
                  hintText: 'e.g., development, design, qa',
                  prefixText: '#',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of this sub-thread',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final threadName = name.startsWith('#') ? name : '#$name';
                
                // Get initial sub-thread count
                final initialSubThreads = provider.getSubThreads(parentId);
                final initialCount = initialSubThreads.length;
                
                // Create sub-thread under ROOT THREAD
                await provider.createSubThread(
                  parentId: parentId,
                  name: threadName,
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                );
                
                // Wait for state update
                await Future.delayed(const Duration(milliseconds: 200));
                
                // Get updated sub-threads
                final updatedSubThreads = provider.getSubThreads(parentId);
                final newCount = updatedSubThreads.length;
                
                // Find and select the new sub-thread
                final newSubThread = updatedSubThreads.firstWhere(
                  (thread) => thread.name == threadName,
                  orElse: () => updatedSubThreads.isNotEmpty ? updatedSubThreads.last : initialSubThreads.first,
                );
                
                // Auto-select new sub-thread
                provider.selectThread(newSubThread.id);
                
                Navigator.pop(context);
                
                // Success feedback
                if (newCount > initialCount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Sub-thread "$threadName" created under ${parentThread.name}!'),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a thread name'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Manage Members Dialog
  static void showManageMembersDialog(BuildContext context, ThreadProvider provider, String threadId) {
    final selectedThread = provider.threads.firstWhere((t) => t.id == threadId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: selectedThread.members.length,
            itemBuilder: (context, index) {
              final member = selectedThread.members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.getInitials()),
                ),
                title: Text(member.user.name),
                subtitle: Text(member.customRole ?? member.role.toString().split('.').last),
                trailing: PopupMenuButton<MemberRole>(
                  onSelected: (role) async {
                    await provider.updateMemberRole(
                      threadId: threadId,
                      userId: member.user.id,
                      role: role,
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: MemberRole.admin,
                      child: Text('Admin'),
                    ),
                    const PopupMenuItem(
                      value: MemberRole.member,
                      child: Text('Member'),
                    ),
                    const PopupMenuItem(
                      value: MemberRole.custom,
                      child: Text('Custom Role'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Edit Message Dialog
  static void showEditMessageDialog(BuildContext context, MessageModel message, ThreadProvider provider) {
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new message...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                await provider.editMessage(message.id, newContent);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message updated successfully!')),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete Message Dialog
  static void showDeleteMessageDialog(BuildContext context, MessageModel message, ThreadProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteMessage(message.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted successfully!')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}