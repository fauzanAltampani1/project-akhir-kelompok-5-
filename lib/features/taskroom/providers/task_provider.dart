// Modifikasi file: lib/features/taskroom/providers/task_provider.dart

import 'package:flutter/material.dart';
import '../../../data/models/task_model.dart';
import '../../../core/network/task_api_service.dart';
import '../../../providers/loading_state_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/personalization_helper.dart';

class TaskProvider with ChangeNotifier {
  List<TaskModel> _tasks = [];
  final TaskApiService _api = TaskApiService();
  bool _isLoading = false;
  String? _errorMessage;
  LoadingStateProvider? _loadingStateProvider;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoadingStateProvider(LoadingStateProvider provider) {
    _loadingStateProvider = provider;
    notifyListeners();
  }

  List<TaskModel> get dailyTasks =>
      _tasks.where((task) => task.type == TaskType.daily).toList();

  List<TaskModel> get deadlineTasks =>
      _tasks.where((task) => task.type == TaskType.deadline).toList();

  List<TaskModel> get priorityTasks =>
      PersonalizationHelper.getPriorityTasks(_tasks);

  Future<void> fetchTasksFromBackend() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_loadingStateProvider != null) {
      _loadingStateProvider!.setModuleLoading(
        'tasks',
        message: 'Fetching tasks...',
      );
    }

    try {
      _tasks = await _api.fetchTasks();

      if (_loadingStateProvider != null) {
        _loadingStateProvider!.setModuleLoaded(
          'tasks',
          message: 'Tasks loaded successfully',
        );
      }

      Logger.i(
        'TaskProvider',
        'Tasks fetched successfully (${_tasks.length} tasks)',
      );
    } catch (e) {
      _errorMessage = 'Failed to fetch tasks: $e';

      if (_loadingStateProvider != null) {
        _loadingStateProvider!.setModuleError(
          'tasks',
          message: 'Failed to fetch tasks: $e',
        );
      }

      Logger.e('TaskProvider', 'Failed to fetch tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTask(TaskModel task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final createdTask = await _api.createTask(task);
      if (createdTask != null) {
        // Add the new task with the generated ID to the local list
        _tasks.add(createdTask);
        notifyListeners();
        return true;
      }
      _errorMessage = 'Failed to create task';
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create task: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _api.updateTask(task);
      if (success) {
        await fetchTasksFromBackend();
        return true;
      }
      _errorMessage = 'Failed to update task';
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTask(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _api.deleteTask(id);
      if (success) {
        await fetchTasksFromBackend();
        return true;
      }
      _errorMessage = 'Failed to delete task';
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update untuk mengelola streak
  void updateDailyTask(String id, {bool? isCompleted}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];

      // Hanya proses jika daily task
      if (task.type == TaskType.daily) {
        int newStreak = task.streak;
        DateTime? newLastCompleted;

        if (isCompleted == true) {
          // Jika task dinyatakan selesai
          newLastCompleted = now;

          // Cek apakah ini adalah hari yang berbeda dari terakhir completed
          if (task.lastCompleted == null) {
            // Task pertama kali diselesaikan
            newStreak = 1;
          } else {
            final lastCompletedDate = DateTime(
              task.lastCompleted!.year,
              task.lastCompleted!.month,
              task.lastCompleted!.day,
            );

            // Cek apakah hari ini atau kemarin
            if (today.difference(lastCompletedDate).inDays == 1) {
              // Kemarin, maka streak berlanjut
              newStreak = task.streak + 1;
            } else if (today.difference(lastCompletedDate).inDays > 1) {
              // Lebih dari 1 hari, streak reset
              newStreak = 1;
            } else if (today.difference(lastCompletedDate).inDays == 0) {
              // Hari yang sama, streak tidak berubah
              newStreak = task.streak;
            }
          }
        } else if (isCompleted == false && task.isCompleted == true) {
          // Jika task dibatalkan setelah selesai
          // Reset streak jika dibatalkan hari ini
          if (task.lastCompleted != null) {
            final lastCompletedDate = DateTime(
              task.lastCompleted!.year,
              task.lastCompleted!.month,
              task.lastCompleted!.day,
            );

            if (today.difference(lastCompletedDate).inDays == 0) {
              // Jika dibatalkan di hari yang sama
              newStreak = task.streak > 0 ? task.streak - 1 : 0;
              // Jika streak > 1, kembalikan ke hari kemarin
              newLastCompleted =
                  newStreak > 0 ? today.subtract(Duration(days: 1)) : null;
            }
          }
        }

        // Update task
        _tasks[index] = task.copyWith(
          isCompleted: isCompleted ?? task.isCompleted,
          streak: newStreak,
          lastCompleted: newLastCompleted,
        );
      } else {
        // Untuk non-daily task, update seperti biasa
        _tasks[index] = task.copyWith(
          isCompleted: isCompleted ?? task.isCompleted,
        );
      }

      notifyListeners();
    }
  }

  // Method untuk memeriksa dan mereset daily tasks setiap hari
  void checkDailyReset() {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool needsUpdate = false;

      // Reset status selesai untuk daily tasks
      for (int i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        if (task.type == TaskType.daily && task.isCompleted) {
          // Cek apakah task diselesaikan kemarin
          if (task.lastCompleted != null) {
            final lastCompletedDate = DateTime(
              task.lastCompleted!.year,
              task.lastCompleted!.month,
              task.lastCompleted!.day,
            );

            // Jika bukan hari ini, reset completed status
            if (today.compareTo(lastCompletedDate) > 0) {
              _tasks[i] = task.copyWith(isCompleted: false);
              needsUpdate = true;
            }
          }
        }
      }

      if (needsUpdate) {
        notifyListeners();
      }
    });
  }

  void cleanCompletedDeadlineTasks() {
    // Buat salinan list dengan hanya task yang:
    // - Bukan deadline task yang sudah selesai
    // - Atau semua daily tasks (tetap dipertahankan)
    _tasks =
        _tasks
            .where(
              (task) =>
                  task.type == TaskType.daily ||
                  (task.type == TaskType.deadline && !task.isCompleted),
            )
            .toList();

    notifyListeners();
  }

  // Method untuk melakukan pengecekan dan pembersihan otomatis
  void checkAndCleanTasks() {
    // 1. Reset daily tasks (method yang sudah ada)
    checkDailyReset();

    // 2. Bersihkan deadline tasks yang sudah selesai
    cleanCompletedDeadlineTasks();
  }

  // Method untuk menjadwalkan pembersihan otomatis jam 00:00
  void scheduleMidnightCleanup() {
    // Wrap in microtask to avoid setState during build
    Future.microtask(() {
      final now = DateTime.now();

      // Hitung waktu sampai tengah malam berikutnya
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final timeUntilMidnight = midnight.difference(now);

      // Jadwalkan pembersihan
      Future.delayed(timeUntilMidnight, () {
        // Bersihkan task
        checkAndCleanTasks();

        // Jadwalkan lagi untuk tengah malam berikutnya (rekursif)
        scheduleMidnightCleanup();
      });
    });
  }

  // Tambahan method baru
  List<TaskModel> getTasksByProjectId(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  // Complete task
  Future<void> completeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(isCompleted: true);
      notifyListeners();
      try {
        // await _api.completeTask(taskId);
        Logger.i('TaskProvider', 'Task completed: $taskId');
      } catch (e) {
        Logger.e('TaskProvider', 'Error completing task: $e');
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(isCompleted: false);
        notifyListeners();
      }
    }
  }

  // Uncomplete task
  Future<void> uncompleteTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(isCompleted: false);
      notifyListeners();
      try {
        // await _api.uncompleteTask(taskId);
        Logger.i('TaskProvider', 'Task uncompleted: $taskId');
      } catch (e) {
        Logger.e('TaskProvider', 'Error uncompleting task: $e');
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(isCompleted: true);
        notifyListeners();
      }
    }
  }
}
