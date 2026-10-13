import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/course_entry.dart';

/// Real data source of the "Mes cours" page: `GET /api/v1/groups/mine`
/// (any authenticated role) — the caller's class memberships with
/// `myRole` and `mySubjects` (`contracts/groups.openapi.yaml`).
/// No mock data: an empty list is a real empty state.
class CoursesRemoteDataSource {
  CoursesRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<CourseEntry>> myClasses() async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/mine',
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_toEntry)
          .toList();
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  CourseEntry _toEntry(Map<String, dynamic> json) {
    return CourseEntry(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      level: (json['level'] as String?) ?? '',
      department: (json['department'] as String?)?.trim(),
      status: (json['status'] as String?) ?? 'PUBLISHED',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? 0,
      myRole: (json['myRole'] as String?) ?? 'STUDENT',
      subjects: (json['mySubjects'] is List)
          ? (json['mySubjects'] as List).whereType<String>().toList()
          : const <String>[],
    );
  }
}
