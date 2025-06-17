import '../../thread/providers/thread_provider.dart';
import '../../../data/models/thread_model.dart';

// Extension methods for ThreadProvider to add functionality
// that should eventually be moved into the provider class itself
extension ThreadProviderExtensions on ThreadProvider {
  /// Updates thread information with new values
  Future<void> updateThreadInfo(
    String threadId,
    ThreadModel updatedThread,
  ) async {
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex == -1) return;

    // Update thread in the list
    threads[threadIndex] = updatedThread;

    // Reselect thread to refresh UI if currently selected
    if (selectedThreadId == threadId) {
      selectThread(threadId);
    } else {
      // Just notify listeners if not the selected thread
      notifyListeners();
    }
  }

  /// Removes a thread and its messages
  Future<void> removeThread(String threadId) async {
    // Get thread before removal to find parent
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex == -1) return;

    final thread = threads[threadIndex];
    final parentThreadId = thread.parentThreadId;

    // Remove thread and its messages
    threads.removeWhere((t) => t.id == threadId);
    threadMessages.remove(threadId);

    // If we're deleting the currently selected thread, select the parent or another thread
    if (selectedThreadId == threadId) {
      if (parentThreadId != null) {
        selectThread(parentThreadId);
      } else if (threads.isNotEmpty) {
        selectThread(threads.first.id);
      }
    } else {
      // Just notify listeners if not affecting current selection
      notifyListeners();
    }
  }
}
