import '../../core/network/api_client.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/projects.php';

  Future<List<ProjectModel>> getAllProjects() async {
    final response = await _apiClient.get(endpoint);
    return (response as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<ProjectModel?> getProjectById(String id) async {
    final response = await _apiClient.get('$endpoint?id=$id');
    if (response == null || response.isEmpty) return null;
    return ProjectModel.fromJson(response);
  }

  Future<void> createProject(ProjectModel project) async {
    await _apiClient.post(endpoint, project.toJson());
  }

  Future<void> updateProject(ProjectModel project) async {
    await _apiClient.put(endpoint, project.toJson());
  }

  Future<void> deleteProject(String id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}