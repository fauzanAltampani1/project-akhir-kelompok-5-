import '../../core/network/api_client.dart';
import '../models/message_model.dart';

class MessageRepository {
  final ApiClient _apiClient = ApiClient();
  final String endpoint = '/messages.php';

  Future<List<MessageModel>> getMessagesByThread(String threadId) async {
    final response = await _apiClient.get('$endpoint?thread_id=$threadId');
    return (response as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<MessageModel?> getMessageById(String id) async {
    final response = await _apiClient.get('$endpoint?id=$id');
    if (response == null || response.isEmpty) return null;
    return MessageModel.fromJson(response);
  }

  Future<void> createMessage(MessageModel message) async {
    await _apiClient.post(endpoint, message.toJson());
  }

  Future<void> updateMessage(MessageModel message) async {
    await _apiClient.put(endpoint, message.toJson());
  }

  Future<void> deleteMessage(String id) async {
    await _apiClient.delete(endpoint, {'id': id});
  }
}