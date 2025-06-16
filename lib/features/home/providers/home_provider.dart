import 'package:flutter/material.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../taskroom/providers/task_provider.dart';

class HomeProvider with ChangeNotifier {
  final List<ProjectModel> _projects = ProjectModel.dummyProjects;
  DateTime _selectedDate = DateTime.now();
  
  // Referensi ke TaskProvider untuk mendapatkan data tasks
  TaskProvider? _taskProvider;
  
  // Setter untuk TaskProvider
  void setTaskProvider(TaskProvider provider) {
    _taskProvider = provider;
    notifyListeners();
  }
  
  List<ProjectModel> get projects => _projects;
  DateTime get selectedDate => _selectedDate;
  
  // Getter untuk deadline tasks yang belum selesai
  List<TaskModel> get upcomingDeadlines {
    if (_taskProvider == null) return [];
    
    // Ambil deadline task yang belum selesai dan urutkan berdasarkan due date
    final tasks = _taskProvider!.deadlineTasks
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
        task.dueDate!.day
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
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
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
    completedCount += _taskProvider!.deadlineTasks
        .where((task) => task.isCompleted)
        .length;
    
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
}