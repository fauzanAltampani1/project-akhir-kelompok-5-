import 'package:flutter/material.dart';
import '../../../data/models/project_task_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';

enum ProjectTaskLoadingState { idle, loading, success, error }

class ProjectTaskProvider with ChangeNotifier {
  List<ProjectTaskModel> _tasks = ProjectTaskModel.dummyTasks;
  ProjectTaskLoadingState _loadingState = ProjectTaskLoadingState.idle;
  String? _errorMessage;
  ProjectProvider? _projectProvider;

  List<ProjectTaskModel> get tasks => _tasks;
  ProjectTaskLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;

  List<ProjectTaskModel> get assignedTasks =>
      _tasks
          .where((task) => task.assigneeIds.contains(UserModel.currentUser.id))
          .toList();

  // Getter untuk task berdasarkan projectId
  List<ProjectTaskModel> getTasksByProjectId(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  void setProjectProvider(ProjectProvider provider) {
    _projectProvider = provider;
    notifyListeners();
  }

  // TAMBAH: Method helper untuk safe get project
  ProjectModel? _safeGetProjectById(String? projectId) {
    if (_projectProvider == null) {
      print('⚠️ ProjectTaskProvider: ProjectProvider not set');
      return null;
    }

    if (projectId == null || projectId.trim().isEmpty) {
      print('⚠️ ProjectTaskProvider: Empty/null project ID provided');
      return null;
    }

    return _projectProvider!.getProjectById(projectId);
  }

  Future<void> fetchTasksByProjectId(String projectId) async {
    // TAMBAH: Validasi projectId
    if (projectId.trim().isEmpty) {
      print('❌ ProjectTaskProvider: Cannot fetch tasks - empty project ID');
      _loadingState = ProjectTaskLoadingState.error;
      _errorMessage = 'Invalid project ID';
      notifyListeners();
      return;
    }

    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // Hanya ambil task untuk projectId tertentu
      _tasks =
          ProjectTaskModel.dummyTasks
              .where((task) => task.projectId == projectId)
              .toList();
      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null; // Clear error
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = ProjectTaskLoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> addProjectTask(ProjectTaskModel task) async {
    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();
    try {
      // TODO: Replace with backend call
      // final success = await _api.createProjectTask(task);
      // if (success) {
      //   await fetchTasksByProjectId(task.projectId!);
      //   _loadingState = ProjectTaskLoadingState.success;
      //   _errorMessage = null;
      //   notifyListeners();
      //   return true;
      // }
      // _errorMessage = 'Failed to create task';
      // _loadingState = ProjectTaskLoadingState.error;
      // notifyListeners();
      // return false;
      // TEMP: Simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = ProjectTaskLoadingState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProjectTask(
    String taskId, {
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? assigneeIds,
    bool? isCompleted,
  }) async {
    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();
    try {
      // TODO: Replace with backend call
      // final success = await _api.updateProjectTask(...);
      // if (success) {
      //   await fetchTasksByProjectId(...);
      //   _loadingState = ProjectTaskLoadingState.success;
      //   _errorMessage = null;
      //   notifyListeners();
      //   return true;
      // }
      // _errorMessage = 'Failed to update task';
      // _loadingState = ProjectTaskLoadingState.error;
      // notifyListeners();
      // return false;
      // TEMP: Simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = ProjectTaskLoadingState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteProjectTask(String taskId) async {
    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final task = _tasks.firstWhere((t) => t.id == taskId);
      _tasks = _tasks.where((t) => t.id != taskId).toList();

      // Update: Sinkronkan dummyTasks
      ProjectTaskModel.dummyTasks = _tasks;

      if (_projectProvider != null) {
        // GUNAKAN: Safe getter
        final project = _safeGetProjectById(task.projectId);
        if (project != null) {
          await _projectProvider!.updateProject(
            task.projectId,
            taskCount: project.taskCount - 1,
          );
        }
      }

      _loadingState = ProjectTaskLoadingState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = ProjectTaskLoadingState.error;
    }
    notifyListeners();
  }
}
