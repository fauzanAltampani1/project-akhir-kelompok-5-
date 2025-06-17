import 'package:flutter/material.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../taskroom/providers/task_provider.dart';
import '../../../providers/loading_state_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/personalization_helper.dart';

class HomeProvider with ChangeNotifier {
  final List<ProjectModel> _projects = ProjectModel.dummyProjects;
  DateTime _selectedDate = DateTime.now();

  // Referensi ke TaskProvider untuk mendapatkan data tasks
  TaskProvider? _taskProvider;
  LoadingStateProvider? _loadingStateProvider;

  // Setter untuk TaskProvider
  void setTaskProvider(TaskProvider provider) {
    _taskProvider = provider;
    notifyListeners();
  }

  // Setter untuk LoadingStateProvider
  void setLoadingStateProvider(LoadingStateProvider provider) {
    _loadingStateProvider = provider;
    notifyListeners();
  }

  List<ProjectModel> get projects => _projects;

  // Get only projects where the current user is a member
  List<ProjectModel> get userProjects =>
      PersonalizationHelper.getCurrentUserProjects(_projects);

  DateTime get selectedDate => _selectedDate;

  // Get loading states
  bool get isLoading => _loadingStateProvider?.isModuleLoading('home') ?? false;
  bool get hasError => _loadingStateProvider?.isModuleError('home') ?? false;
  String? get errorMessage => _loadingStateProvider?.getModuleMessage('home');

  // Getter untuk deadline tasks yang belum selesai
  List<TaskModel> get upcomingDeadlines {
    if (_taskProvider == null) return [];

    // Ambil deadline task yang belum selesai dan urutkan berdasarkan due date
    final tasks =
        _taskProvider!.deadlineTasks
            .where((task) => !task.isCompleted && task.dueDate != null)
            .toList();

    // Sort berdasarkan tanggal due date
    tasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return tasks;
  }

  // Getter untuk deadline tasks yang jatuh tempo hari ini
  List<TaskModel> get todayDeadlines {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return upcomingDeadlines.where((task) {
      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return taskDate.isAtSameMomentAs(today);
    }).toList();
  }

  // Getter untuk daily tasks yang belum selesai
  List<TaskModel> get uncompletedDailyTasks {
    if (_taskProvider == null) return [];
    return _taskProvider!.dailyTasks
        .where((task) => !task.isCompleted)
        .toList();
  }

  // Getter untuk total task yang diselesaikan minggu ini
  int get tasksCompletedThisWeek {
    if (_taskProvider == null) return 0;

    final now = DateTime.now();
    // Hitung tanggal awal minggu (Senin)
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    // Hitung tasks yang selesai minggu ini
    int completedCount = 0;

    // Untuk daily tasks, cek kapan terakhir diselesaikan
    for (var task in _taskProvider!.dailyTasks) {
      if (task.lastCompleted != null &&
          task.lastCompleted!.isAfter(startOfWeek)) {
        completedCount++;
      }
    }

    // Untuk deadline tasks, hitung yang sudah selesai dan masih ada di list
    // (yang sudah selesai dan sudah dihapus tidak bisa dihitung)
    completedCount +=
        _taskProvider!.deadlineTasks.where((task) => task.isCompleted).length;

    return completedCount;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void addProject(ProjectModel project) {
    _projects.add(project);
    notifyListeners();
  }

  // Load all home data
  Future<void> loadHomeData() async {
    if (_loadingStateProvider == null) {
      Logger.e('HomeProvider', 'LoadingStateProvider not set');
      return;
    }

    _loadingStateProvider!.setModuleLoading(
      'home',
      message: 'Loading home data...',
    );
    notifyListeners();

    try {
      // Simulate network delay - In a real app, this would be actual API calls
      await Future.delayed(const Duration(seconds: 1));

      // Check if task provider is available
      if (_taskProvider == null) {
        throw Exception('TaskProvider not available');
      }

      // Fetch tasks if needed
      if (_taskProvider!.tasks.isEmpty && !_taskProvider!.isLoading) {
        await _taskProvider!.fetchTasksFromBackend();
      }

      _loadingStateProvider!.setModuleLoaded(
        'home',
        message: 'Home data loaded',
      );
    } catch (e) {
      Logger.e('HomeProvider', 'Failed to load home data: $e');
      _loadingStateProvider!.setModuleError(
        'home',
        message: 'Failed to load home data: $e',
      );
    }

    notifyListeners();
  }

  // Refresh home data
  Future<void> refreshHomeData() async {
    if (_taskProvider != null) {
      await _taskProvider!.fetchTasksFromBackend();
    }

    await loadHomeData();
    notifyListeners();
  }
}
