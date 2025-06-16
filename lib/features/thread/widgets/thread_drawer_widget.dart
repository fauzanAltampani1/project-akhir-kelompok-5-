import 'package:flutter/material.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../providers/thread_provider.dart';
import 'thread_dialogs.dart';

class ThreadDrawerWidget extends StatefulWidget {
  final ThreadProvider provider;
  
  const ThreadDrawerWidget({super.key, required this.provider});

  @override
  State<ThreadDrawerWidget> createState() => _ThreadDrawerWidgetState();
}

class _ThreadDrawerWidgetState extends State<ThreadDrawerWidget> {
  final Map<String, bool> _expansionStates = {};
  
  @override
  void initState() {
    super.initState();
    _updateExpansionStates();
    widget.provider.addListener(_onProviderChanged);
  }
  
  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    super.dispose();
  }
  
  void _onProviderChanged() {
    if (mounted) {
      setState(() {
        _updateExpansionStates();
      });
    }
  }
  
  void _updateExpansionStates() {
    // Clear previous states to avoid conflicts
    _expansionStates.clear();
    
    // Set expansion state based on currently selected thread
    for (final thread in widget.provider.rootHqThreads) {
      final subThreads = widget.provider.getSubThreads(thread.id);
      _expansionStates[thread.id] = subThreads.any((sub) => sub.id == widget.provider.selectedThreadId);
    }
    
    for (final thread in widget.provider.rootProjectThreads) {
      final subThreads = widget.provider.getSubThreads(thread.id);
      _expansionStates[thread.id] = subThreads.any((sub) => sub.id == widget.provider.selectedThreadId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootHqThreads = widget.provider.rootHqThreads;
    final rootProjectThreads = widget.provider.rootProjectThreads;
    
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: const [
                Icon(Icons.chat_bubble, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Thread', style: AppTextStyles.heading3),
              ],
            ),
          ),
          
          // Thread List - Scrollable
          Expanded(
            child: ListView(
              children: [
                // HQ Section
                ListTile(
                  title: Row(
                    children: [
                      const Text('#HQ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          ThreadDialogs.showCreateHQThreadDialog(context, widget.provider);
                        },
                      ),
                    ],
                  ),
                  dense: true,
                ),
                
                // List semua HQ root threads
                ...rootHqThreads.asMap().entries.map((entry) {
                  final index = entry.key;
                  final thread = entry.value;
                  final subThreads = widget.provider.getSubThreads(thread.id);
                  final isExpanded = _expansionStates[thread.id] ?? false;
                  
                  // ENHANCED DEBUG: Print thread structure
                  print('🏠 DEBUG Drawer: HQ Thread ${thread.name} (${thread.id})');
                  print('🏠 DEBUG Drawer: Sub-threads: ${subThreads.map((t) => '${t.name}(${t.id})').toList()}');
                  
                  if (subThreads.isEmpty) {
                    // Thread tanpa sub-thread
                    return ListTile(
                      key: ValueKey('hq-single-${thread.id}'),
                      leading: const Text('#'),
                      title: Text(thread.name.replaceFirst('#', '')),
                      dense: true,
                      selected: widget.provider.selectedThreadId == thread.id,
                      onTap: () {
                        widget.provider.selectThread(thread.id);
                        Navigator.pop(context);
                      },
                    );
                  } else {
                    // Thread dengan sub-thread
                    return ExpansionTile(
                      key: ValueKey('hq-expansion-${thread.id}-${subThreads.length}-${_expansionStates.hashCode}'),
                      leading: const Text('#'),
                      title: Text(thread.name.replaceFirst('#', '')),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.only(left: 32),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expansionStates[thread.id] = expanded;
                        });
                      },
                      children: [
                        // Sub-thread items - REAL-TIME DATA
                        ...subThreads.asMap().entries.map((subEntry) {
                          final subIndex = subEntry.key;
                          final subThread = subEntry.value;
                          
                          print('🏠 DEBUG Drawer: Rendering sub-thread ${subThread.name} (${subThread.id}) under ${thread.name}');
                          
                          return ListTile(
                            key: ValueKey('hq-sub-${subThread.id}-$subIndex'),
                            leading: Text(
                              _getThreadIcon(subThread.name),
                              style: const TextStyle(fontSize: 16),
                            ),
                            title: Text(subThread.name.replaceFirst('#', '')),
                            dense: true,
                            selected: widget.provider.selectedThreadId == subThread.id,
                            onTap: () {
                              widget.provider.selectThread(subThread.id);
                              Navigator.pop(context);
                            },
                          );
                        }),
                        
                        // Quick add sub-thread button
                        ListTile(
                          key: ValueKey('hq-add-${thread.id}'),
                          leading: const Icon(Icons.add, size: 16, color: AppColors.secondary),
                          title: const Text(
                            'Add sub-thread',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.pop(context);
                            print('🏠 DEBUG Drawer: Quick add sub-thread to ${thread.id} (${thread.name})');
                            ThreadDialogs.showCreateSubThreadDialog(context, widget.provider, thread.id);
                          },
                        ),
                      ],
                    );
                  }
                }),
                
                // PROJECT-THREADS Section
                const Divider(),
                ListTile(
                  title: const Text('#PROJECT-THREADS', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  dense: true,
                ),
                
                // List semua Project root threads
                ...rootProjectThreads.asMap().entries.map((entry) {
                  final index = entry.key;
                  final thread = entry.value;
                  final subThreads = widget.provider.getSubThreads(thread.id);
                  final isExpanded = _expansionStates[thread.id] ?? false;
                  
                  if (subThreads.isEmpty) {
                    // Thread tanpa sub-thread
                    return ListTile(
                      key: ValueKey('project-single-${thread.id}'),
                      leading: const Text('#'),
                      title: Text(thread.name.replaceFirst('#', '')),
                      dense: true,
                      selected: widget.provider.selectedThreadId == thread.id,
                      onTap: () {
                        widget.provider.selectThread(thread.id);
                        Navigator.pop(context);
                      },
                    );
                  } else {
                    // Thread dengan sub-thread
                    return ExpansionTile(
                      key: ValueKey('project-expansion-${thread.id}-${subThreads.length}-${_expansionStates.hashCode}'),
                      leading: const Text('#'),
                      title: Text(thread.name.replaceFirst('#', '')),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.only(left: 32),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expansionStates[thread.id] = expanded;
                        });
                      },
                      children: [
                        // Sub-thread items
                        ...subThreads.asMap().entries.map((subEntry) {
                          final subIndex = subEntry.key;
                          final subThread = subEntry.value;
                          return ListTile(
                            key: ValueKey('project-sub-${subThread.id}-$subIndex'),
                            leading: const Text('#'),
                            title: Text(subThread.name.replaceFirst('#', '')),
                            dense: true,
                            selected: widget.provider.selectedThreadId == subThread.id,
                            onTap: () {
                              widget.provider.selectThread(subThread.id);
                              Navigator.pop(context);
                            },
                          );
                        }),
                        
                        // Quick add sub-thread button
                        ListTile(
                          key: ValueKey('project-add-${thread.id}'),
                          leading: const Icon(Icons.add, size: 16, color: AppColors.secondary),
                          title: const Text(
                            'Add sub-thread',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.pop(context);
                            ThreadDialogs.showCreateSubThreadDialog(context, widget.provider, thread.id);
                          },
                        ),
                      ],
                    );
                  }
                }),
              ],
            ),
          ),
          
          // Bottom section (Profile & Logout)
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text('S', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Sinister'),
            onTap: () {
              // Profile action
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              // Logout action
            },
          ),
        ],
      ),
    );
  }

  // Helper untuk mendapatkan icon berdasarkan nama thread
  String _getThreadIcon(String threadName) {
    final name = threadName.toLowerCase();
    if (name.contains('lobby')) return '🏠';
    if (name.contains('announcement')) return '📣';
    if (name.contains('brainstorm')) return '💡';
    if (name.contains('design')) return '🎨';
    if (name.contains('ui')) return '📱';
    if (name.contains('ux')) return '👥';
    if (name.contains('dev')) return '💻';
    if (name.contains('qa')) return '🧪';
    if (name.contains('divisiit')) return '💻';
    if (name.contains('tes')) return '🧪';
    return '#';
  }
}