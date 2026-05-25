import 'api_client.dart';
import '../models/api_response_model.dart';

class UploadService {
  final ApiClient _apiClient;

  UploadService(this._apiClient);

  // ─── Upload Image ───────────────────────────────────────────────────────────
  Future<UploadResponseModel> uploadImage(String imagePath) async {
    try {
      final response = await _apiClient.uploadFile(
        '/upload/image',
        imagePath,
        'file',
      );
      return UploadResponseModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
