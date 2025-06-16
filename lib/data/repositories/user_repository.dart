import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/users.php';

  Future<List<UserModel>> getAllUsers() async {
    final response = await _apiClient.get(endpoint);
    return (response as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final response = await _apiClient.get('$endpoint?id=$id');
    if (response == null || response.isEmpty) return null;
    return UserModel.fromJson(response);
  }

  Future<void> createUser(UserModel user, String password) async {
    await _apiClient.post(endpoint, {
      ...user.toJson(),
      'password': password,
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _apiClient.put(endpoint, user.toJson());
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}