import 'package:dio/dio.dart';
import '../network/api_client.dart';

/// Service for document upload API calls.
class DocumentService {
  final ApiClient _client;

  DocumentService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /documents/upload` — Upload a document file.
  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String fileName,
    required String documentType,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'documentType': documentType,
    });

    final response = await _client.post(
      '/documents/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  /// `GET /documents` — Get all documents for the authenticated user.
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final response = await _client.get('/documents');
    final list = response.data as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
