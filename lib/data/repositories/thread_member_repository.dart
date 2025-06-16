import '../../core/network/api_client.dart';
import '../models/thread_member_model.dart';

class ThreadMemberRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/thread_members.php';

  Future<List<ThreadMemberModel>> getMembersByThread(String threadId) async {
    final response = await _apiClient.get('$endpoint?thread_id=$threadId');
    return (response as List).map((e) => ThreadMemberModel.fromJson(e)).toList();
  }

  Future<void> addMember(ThreadMemberModel member, String threadId) async {
    await _apiClient.post(endpoint, {
      ...member.toJson(),
      'thread_id': threadId,
    });
  }

  Future<void> updateMember(ThreadMemberModel member, String threadId) async {
    await _apiClient.put(endpoint, {
      ...member.toJson(),
      'thread_id': threadId,
    });
  }

  Future<void> removeMember(String threadId, String userId) async {
    await _apiClient.delete(endpoint, {'thread_id': threadId, 'user_id': userId});
  }
}