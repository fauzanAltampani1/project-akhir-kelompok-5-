import '../../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/tasks.php';

  Future<List<TaskModel>> getAllTasks() async {
    final response = await _apiClient.get(endpoint);
    return (response as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final response = await _apiClient.get('$endpoint?id=$id');
    if (response == null || response.isEmpty) return null;
    return TaskModel.fromJson(response);
  }

  Future<void> createTask(TaskModel task) async {
    await _apiClient.post(endpoint, task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _apiClient.put(endpoint, task.toJson());
  }

  Future<void> deleteTask(String id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}
