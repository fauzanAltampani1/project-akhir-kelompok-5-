import '../../core/network/api_client.dart';
import '../models/mention_model.dart';

class MentionRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/mentions.php';

  Future<List<MentionModel>> getMentionsByMessage(String messageId) async {
    final response = await _apiClient.get('$endpoint?message_id=$messageId');
    return (response as List).map((e) => MentionModel.fromJson(e)).toList();
  }

  Future<void> createMention(MentionModel mention) async {
    await _apiClient.post(endpoint, mention.toJson());
  }

  Future<void> updateMention(MentionModel mention) async {
    await _apiClient.put(endpoint, mention.toJson());
  }

  Future<void> deleteMention(int id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}