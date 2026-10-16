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

  Future<Map<String, dynamic>> joinClass(String code) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/groups/join',
      data: {'code': code.trim().toUpperCase()},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> leaveClass(String groupId) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/leave',
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> generateInvitation(
    String groupId, {
    int? expiresInHours,
    int? maxUses,
  }) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/invitations',
      data: {
        'expiresInHours': ?expiresInHours,
        'maxUses': ?maxUses,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> rotateInvitation(
    String groupId, {
    int? expiresInHours,
    int? maxUses,
  }) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/invitations/rotate',
      data: {
        'expiresInHours': ?expiresInHours,
        'maxUses': ?maxUses,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> revokeInvitation(String groupId) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/invitations/revoke',
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getInvitationStatus(String groupId) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/invitations/status',
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> createVirtualClassroom({
    required String name,
    int? capacity,
    String? description,
  }) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/groups/virtual',
      data: {
        'name': name,
        'capacity': ?capacity,
        'description': ?description,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> removeMembers(
    String groupId,
    List<String> studentIds,
  ) async {
    final res = await _client.delete<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/members',
      data: {'studentIds': studentIds},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getClass(String groupId) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId',
    );
    return apiEnvelope(res);
  }

  Future<List<Map<String, dynamic>>> listMembers(
    String groupId, {
    int page = 1,
    int limit = 100,
  }) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/members',
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> listTeachers(String groupId) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/groups/$groupId/teachers',
    );
    final data = apiEnvelope(res);
    final assignments = data['assignments'];
    if (assignments is List) {
      return assignments.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
