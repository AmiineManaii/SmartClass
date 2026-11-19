import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/exam_class_option.dart';

/// Caller's class memberships for exam authoring (`GET /groups/mine`).
/// Real data only: an empty list means the teacher has no class yet.
class ExamClassesDataSource {
  ExamClassesDataSource(this._client);

  final ApiClient _client;

  Future<List<ExamClassOption>> myClasses() async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/mine',
    );
    final body = res.data;
    if (body is! Map<String, dynamic> || body['data'] is! List) {
      throw const ApiException(message: 'Unexpected response format');
    }
    return (body['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ExamClassOption(
            id: (json['id'] as String?) ?? '',
            name: (json['name'] as String?) ?? '',
            myRole: (json['myRole'] as String?) ?? 'STUDENT',
            department: (json['department'] as String?)?.trim(),
          ),
        )
        .where((option) => option.id.isNotEmpty)
        .toList();
  }
}
