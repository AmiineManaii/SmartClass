import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';

/// One method per admin-bound backend endpoint
/// (`contracts/admin|users|groups|exams|videoconference.openapi.yaml`,
/// base `/api/v1`, ADMIN-only).
/// Returns raw envelope contents; parsing lives in `../models/admin_models.dart`.
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._client);

  final ApiClient _client;

  static String get _base => ApiConfig.apiPrefix;

  /// Unwraps `{ data: [...] }` list envelopes with their `meta`.
  static ({List<dynamic> items, Map<String, dynamic> meta}) _listEnvelope(
    Response<dynamic> res,
  ) {
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      final meta = body['meta'];
      return (
        items: (body['data'] as List).toList(),
        meta: meta is Map<String, dynamic> ? meta : <String, dynamic>{},
      );
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  // Overview ---------------------------------------------------------------

  Future<Map<String, dynamic>> getOverview() async {
    final res = await _client.get<dynamic>('$_base/admin/overview');
    return apiEnvelope(res);
  }

  // Classes ----------------------------------------------------------------

  Future<({List<dynamic> items, Map<String, dynamic> meta})> listClasses({
    String? level,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final res = await _client.get<dynamic>(
      '$_base/groups',
      queryParameters: {
        'page': page,
        'limit': limit,
        'level': ?level,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _listEnvelope(res);
  }

  Future<Map<String, dynamic>> getClass(String id) async {
    final res = await _client.get<dynamic>('$_base/groups/$id');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> createClass({
    required String name,
    required String level,
    String? department,
    required int capacity,
    String? description,
    bool forumEnabled = true,
    bool entSyncEnabled = true,
    bool draft = false,
    String? referentId,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/groups',
      data: {
        'name': name,
        'level': level,
        if (department != null && department.isNotEmpty) 'department': department,
        'capacity': capacity,
        if (description != null && description.isNotEmpty) 'description': description,
        'forumEnabled': forumEnabled,
        'entSyncEnabled': entSyncEnabled,
        'status': draft ? 'DRAFT' : 'PUBLISHED',
        'referentId': ?referentId,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateClass(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final res = await _client.patch<dynamic>('$_base/groups/$id', data: fields);
    return apiEnvelope(res);
  }

  /// 204 No Content on success.
  Future<void> deleteClass(String id) async {
    await _client.delete<dynamic>('$_base/groups/$id');
  }

  Future<List<dynamic>> listDepartments() async {
    final res = await _client.get<dynamic>('$_base/groups/departments');
    final data = apiEnvelope(res);
    final departments = data['departments'];
    if (departments is! List) {
      throw const ApiException(message: 'Unexpected response format');
    }
    return departments.toList();
  }

  // People -----------------------------------------------------------------

  Future<({List<dynamic> items, Map<String, dynamic> meta})> listUsers({
    required String role,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final res = await _client.get<dynamic>(
      '$_base/users',
      queryParameters: {
        'role': role,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _listEnvelope(res);
  }

  Future<({List<dynamic> items, Map<String, dynamic> meta})> listMembers(
    String classId, {
    int page = 1,
    int limit = 100,
  }) async {
    final res = await _client.get<dynamic>(
      '$_base/groups/$classId/members',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _listEnvelope(res);
  }

  Future<Map<String, dynamic>> assignStudents(
    String classId,
    List<String> studentIds,
  ) async {
    final res = await _client.post<dynamic>(
      '$_base/groups/$classId/members',
      data: {'studentIds': studentIds},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> removeStudents(
    String classId,
    List<String> studentIds,
  ) async {
    final res = await _client.delete<dynamic>(
      '$_base/groups/$classId/members',
      data: {'studentIds': studentIds},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> listTeacherAssignments(String classId) async {
    final res = await _client.get<dynamic>('$_base/groups/$classId/teachers');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> assignTeachers(
    String classId,
    List<Map<String, dynamic>> assignments,
  ) async {
    final res = await _client.post<dynamic>(
      '$_base/groups/$classId/teachers',
      data: {'assignments': assignments},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> removeTeachers(
    String classId,
    List<String> teacherIds,
  ) async {
    final res = await _client.delete<dynamic>(
      '$_base/groups/$classId/teachers',
      data: {'teacherIds': teacherIds},
    );
    return apiEnvelope(res);
  }

  // Planning ---------------------------------------------------------------

  Future<Map<String, dynamic>> getTimetable({
    required String classGroupId,
    required String weekStart,
  }) async {
    final res = await _client.get<dynamic>(
      '$_base/videoconference/timetable',
      queryParameters: {'classGroupId': classGroupId, 'weekStart': weekStart},
    );
    return apiEnvelope(res);
  }

  // Frauds -----------------------------------------------------------------

  Future<({List<dynamic> items, Map<String, dynamic> meta})> listFraudReports({
    String? status,
    String? cursor,
    int limit = 100,
  }) async {
    final res = await _client.get<dynamic>(
      '$_base/exams/fraud-reports',
      queryParameters: {
        'limit': limit,
        'status': ?status,
        'cursor': ?cursor,
      },
    );
    return _listEnvelope(res);
  }

  Future<Map<String, dynamic>> getFraudSummary() async {
    final res = await _client.get<dynamic>('$_base/exams/fraud-reports/summary');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateFraudReport(
    String id, {
    required String status,
    String? resolution,
  }) async {
    final res = await _client.patch<dynamic>(
      '$_base/exams/fraud-reports/$id',
      data: {
        'status': status,
        if (resolution != null && resolution.isNotEmpty) 'resolution': resolution,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateTeacherApproval(
    String userId,
    String status,
  ) async {
    final res = await _client.patch<dynamic>(
      '$_base/users/$userId/teacher-approval',
      data: {'status': status},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateUserRole(
    String userId,
    String role,
  ) async {
    final res = await _client.patch<dynamic>(
      '$_base/users/$userId/role',
      data: {'role': role},
    );
    return apiEnvelope(res);
  }
}
