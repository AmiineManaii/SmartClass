import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
/// Student/teacher side of the groups bounded context.
///
/// Only `GET /api/v1/groups/mine` (any authenticated role): the classes
/// the caller belongs to, with `myRole` (STUDENT/TEACHER/REFERENT).
/// All other group endpoints are ADMIN-only (see the admin feature).
class GroupsRemoteDataSource {
  GroupsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> myGroups() async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/mine',
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  /// Current-week timetable of one class (teacher-scoped read server-side).
  /// Returns the `{ weekStart, days, events }` week view.
  Future<Map<String, dynamic>> weekTimetable(String classGroupId) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/timetable',
      queryParameters: {'classGroupId': classGroupId},
    );
    return apiEnvelope(res);
  }
}
