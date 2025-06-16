import '../../core/network/api_client.dart';
import '../models/project_task_model.dart';

class ProjectTaskRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/project_tasks.php';

  Future<List<ProjectTaskModel>> getAllProjectTasks() async {
    final response = await _apiClient.get(endpoint);
    return (response as List).map((e) => ProjectTaskModel.fromJson(e)).toList();
  }

  Future<ProjectTaskModel?> getProjectTaskById(String id) async {
    final response = await _apiClient.get('$endpoint?id=$id');
    if (response == null || response.isEmpty) return null;
    return ProjectTaskModel.fromJson(response);
  }

  Future<void> createProjectTask(ProjectTaskModel task) async {
    await _apiClient.post(endpoint, task.toJson());
  }

  Future<void> updateProjectTask(ProjectTaskModel task) async {
    await _apiClient.put(endpoint, task.toJson());
  }

  Future<void> deleteProjectTask(String id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}