import '../../data/models/task_model.dart';
import 'api_client.dart';

/// Service for handling all task-related API operations.
class TaskApiService {
  final ApiClient _client = ApiClient();

  /// Fetch all tasks from the backend.
  Future<List<TaskModel>> fetchTasks() async {
    try {
      final data = await _client.get('/tasks.php');
      if (data is List) {
        return data.map((e) => TaskModel.fromJson(e)).toList();
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      // Log error for debugging
      print('Error fetching tasks: $e');
      rethrow;
    }
  }

  /// Create a new task in the backend.
  Future<TaskModel?> createTask(TaskModel task) async {
    try {
      final result = await _client.post('/tasks.php', task.toJson());
      if (result['success'] == true && result['data'] != null) {
        return TaskModel.fromJson(result['data']);
      }
      return null;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  /// Update an existing task in the backend.
  Future<bool> updateTask(TaskModel task) async {
    try {
      final result = await _client.put('/tasks.php', task.toJson());
      return result['success'] == true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  /// Delete a task from the backend by ID.
  Future<bool> deleteTask(String id) async {
    try {
      final result = await _client.delete('/tasks.php', {'id': id});
      return result['success'] == true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
}
