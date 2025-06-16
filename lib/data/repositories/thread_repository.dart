import '../../core/network/api_client.dart';
import '../models/thread_model.dart';

class ThreadRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/threads.php';

  Future<List<ThreadModel>> getAllThreads() async {
    final response = await _apiClient.get(endpoint);
    return (response as List).map((e) => ThreadModel.fromJson(e)).toList();
  }

  Future<ThreadModel?> getThreadById(String id) async {
    final response = await _apiClient.get('$endpoint?id=$id');
    if (response == null || response.isEmpty) return null;
    return ThreadModel.fromJson(response);
  }

  Future<void> createThread(ThreadModel thread) async {
    await _apiClient.post(endpoint, thread.toJson());
  }

  Future<void> updateThread(ThreadModel thread) async {
    await _apiClient.put(endpoint, thread.toJson());
  }

  Future<void> deleteThread(String id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}