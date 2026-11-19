import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/entities/exam_monitoring.dart';

/// JSON mappers for `contracts/exams.openapi.yaml`.
///
/// Kept in infrastructure so domain entities stay transport-agnostic.
Map<String, dynamic> asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  return value is List ? value : const <dynamic>[];
}

DateTime parseDate(dynamic value, {DateTime? fallback}) {
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? parseNullableDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return null;
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? parseNullableInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

num parseNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}

num? parseNullableNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

String parseString(dynamic value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

String? parseNullableString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

ExamSettings parseSettings(dynamic value) {
  final json = asMap(value);
  return ExamSettings(
    shuffleQuestions: json['shuffleQuestions'] == true,
    requireCamera: json['requireCamera'] == true,
    allowQuestionSkip: json['allowQuestionSkip'] != false,
    showResultsAfterClose: json['showResultsAfterClose'] != false,
    maxViolationCount: parseInt(json['maxViolationCount'], fallback: 3),
  );
}

List<ExamOption> parseOptions(dynamic value) {
  return asList(value)
      .map(asMap)
      .where((option) => parseString(option['id']).isNotEmpty)
      .map(
        (option) => ExamOption(
          id: parseString(option['id']),
          text: parseString(option['text']),
        ),
      )
      .toList();
}

List<String> parseStringList(dynamic value) {
  return asList(value).whereType<String>().toList();
}

QuestionDraft questionDraftFromJson(Map<String, dynamic> json) {
  return QuestionDraft(
    prompt: parseString(json['prompt']),
    hint: parseNullableString(json['hint']),
    options: parseOptions(json['options']),
    correctOptionIds: parseStringList(json['correctOptionIds']),
    explanation: parseNullableString(json['explanation']),
    points: parseInt(json['points'], fallback: 1),
  );
}

TeacherQuestion teacherQuestionFromJson(Map<String, dynamic> json) {
  return TeacherQuestion(
    id: parseString(json['id']),
    examId: parseString(json['examId']),
    order: parseInt(json['order']),
    type: ExamQuestionType.fromWire(json['type'] as String?),
    prompt: parseString(json['prompt']),
    hint: parseNullableString(json['hint']),
    options: parseOptions(json['options']),
    correctOptionIds: parseStringList(json['correctOptionIds']),
    explanation: parseNullableString(json['explanation']),
    points: parseInt(json['points'], fallback: 1),
  );
}

StudentQuestion studentQuestionFromJson(Map<String, dynamic> json) {
  return StudentQuestion(
    id: parseString(json['id']),
    order: parseInt(json['order']),
    type: ExamQuestionType.fromWire(json['type'] as String?),
    prompt: parseString(json['prompt']),
    hint: parseNullableString(json['hint']),
    options: parseOptions(json['options']),
    points: parseInt(json['points'], fallback: 1),
  );
}

ExamSummary examSummaryFromJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  return ExamSummary(
    id: parseString(json['id']),
    title: parseString(json['title']),
    description: parseNullableString(json['description']),
    classGroupId: parseString(json['classGroupId']),
    className: parseNullableString(json['className']),
    authorId: parseString(json['authorId']),
    durationMinutes: parseInt(json['durationMinutes']),
    startsAt: parseDate(json['startsAt'], fallback: now),
    endsAt: parseDate(json['endsAt'], fallback: now),
    status: ExamStatus.fromWire(json['status'] as String?),
    source: ExamSource.fromWire(json['source'] as String?),
    settings: parseSettings(json['settings']),
    questionCount: parseInt(json['questionCount']),
    totalPoints: parseInt(json['totalPoints']),
    createdAt: parseDate(json['createdAt'], fallback: now),
    updatedAt: parseDate(json['updatedAt'], fallback: now),
  );
}

ExamDetail examDetailFromJson(Map<String, dynamic> json) {
  final summary = examSummaryFromJson(json);
  return ExamDetail(
    id: summary.id,
    title: summary.title,
    description: summary.description,
    classGroupId: summary.classGroupId,
    className: summary.className,
    authorId: summary.authorId,
    durationMinutes: summary.durationMinutes,
    startsAt: summary.startsAt,
    endsAt: summary.endsAt,
    status: summary.status,
    source: summary.source,
    settings: summary.settings,
    questionCount: summary.questionCount,
    totalPoints: summary.totalPoints,
    createdAt: summary.createdAt,
    updatedAt: summary.updatedAt,
    questions: asList(json['questions'])
        .map(asMap)
        .map(teacherQuestionFromJson)
        .toList(),
  );
}

ImportedExamPreview importedPreviewFromJson(Map<String, dynamic> json) {
  return ImportedExamPreview(
    title: parseString(json['title']),
    description: parseNullableString(json['description']),
    sourceFormat: parseString(json['sourceFormat']),
    questions: asList(json['questions'])
        .map(asMap)
        .map(questionDraftFromJson)
        .toList(),
  );
}

GeneratedExamPreview generatedPreviewFromJson(Map<String, dynamic> json) {
  return GeneratedExamPreview(
    title: parseString(json['title']),
    description: parseNullableString(json['description']),
    model: parseString(json['model']),
    questions: asList(json['questions'])
        .map(asMap)
        .map(questionDraftFromJson)
        .toList(),
  );
}

AvailableExam availableExamFromJson(Map<String, dynamic> json) {
  final summary = examSummaryFromJson(json);
  return AvailableExam(
    id: summary.id,
    title: summary.title,
    description: summary.description,
    classGroupId: summary.classGroupId,
    className: summary.className,
    authorId: summary.authorId,
    durationMinutes: summary.durationMinutes,
    startsAt: summary.startsAt,
    endsAt: summary.endsAt,
    status: summary.status,
    source: summary.source,
    settings: summary.settings,
    questionCount: summary.questionCount,
    totalPoints: summary.totalPoints,
    createdAt: summary.createdAt,
    updatedAt: summary.updatedAt,
    availability: ExamAvailability.fromWire(json['availability'] as String?),
    attemptStatus: AttemptStatus.fromWire(json['attemptStatus'] as String?),
    canStart: json['canStart'] == true,
    canResume: json['canResume'] == true,
    remainingMs: parseNullableInt(json['remainingMs']),
  );
}

StudentAttempt studentAttemptFromJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  return StudentAttempt(
    id: parseString(json['id']),
    examId: parseString(json['examId']),
    status: AttemptStatus.fromWire(json['status'] as String?) ??
        AttemptStatus.inProgress,
    startedAt: parseDate(json['startedAt'], fallback: now),
    expiresAt: parseDate(json['expiresAt'], fallback: now),
    submittedAt: parseNullableDate(json['submittedAt']),
    remainingMs: parseInt(json['remainingMs']),
    violationCount: parseInt(json['violationCount']),
    terminatedReason: parseNullableString(json['terminatedReason']),
  );
}

StudentAnswer studentAnswerFromJson(Map<String, dynamic> json) {
  return StudentAnswer(
    questionId: parseString(json['questionId']),
    selectedOptionIds: parseStringList(json['selectedOptionIds']),
    savedAt: parseDate(json['savedAt']),
  );
}

StudentExam studentExamFromJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  return StudentExam(
    id: parseString(json['id']),
    title: parseString(json['title']),
    description: parseNullableString(json['description']),
    className: parseNullableString(json['className']),
    durationMinutes: parseInt(json['durationMinutes']),
    startsAt: parseDate(json['startsAt'], fallback: now),
    endsAt: parseDate(json['endsAt'], fallback: now),
    status: ExamStatus.fromWire(json['status'] as String?),
    settings: parseSettings(json['settings']),
    questionCount: parseInt(json['questionCount']),
    totalPoints: parseInt(json['totalPoints']),
    questions: asList(json['questions'])
        .map(asMap)
        .map(studentQuestionFromJson)
        .toList(),
    serverNow: parseDate(json['serverNow'], fallback: now),
  );
}

AttemptSession attemptSessionFromJson(Map<String, dynamic> json) {
  return AttemptSession(
    exam: studentExamFromJson(asMap(json['exam'])),
    attempt: studentAttemptFromJson(asMap(json['attempt'])),
    answers: asList(json['answers']).map(asMap).map(studentAnswerFromJson).toList(),
    resumed: json['resumed'] == true,
    canResume: json['canResume'] == true,
    serverNow: parseDate(json['serverNow']),
  );
}

SaveAnswersResult saveAnswersFromJson(Map<String, dynamic> json) {
  return SaveAnswersResult(
    savedAt: parseDate(json['savedAt']),
    answers: asList(json['answers']).map(asMap).map(studentAnswerFromJson).toList(),
    remainingMs: parseInt(json['remainingMs']),
    serverNow: parseDate(json['serverNow']),
  );
}

SubmitAttemptResult submitAttemptFromJson(Map<String, dynamic> json) {
  return SubmitAttemptResult(
    attempt: studentAttemptFromJson(asMap(json['attempt'])),
    autoSubmitted: json['autoSubmitted'] == true,
    serverNow: parseDate(json['serverNow']),
  );
}

StudentResult studentResultFromJson(Map<String, dynamic> json) {
  return StudentResult(
    examId: parseString(json['examId']),
    examTitle: parseString(json['examTitle']),
    status: AttemptStatus.fromWire(json['status'] as String?) ??
        AttemptStatus.submitted,
    score: parseNum(json['score']),
    maxScore: parseNum(json['maxScore']),
    correctCount: parseInt(json['correctCount']),
    questionCount: parseInt(json['questionCount']),
    submittedAt: parseNullableDate(json['submittedAt']),
    terminatedReason: parseNullableString(json['terminatedReason']),
    items: asList(json['items']).map(asMap).map((item) {
      return StudentResultItem(
        questionId: parseString(item['questionId']),
        selectedOptionIds: parseStringList(item['selectedOptionIds']),
        correct: item['correct'] == true,
        pointsAwarded: parseNum(item['pointsAwarded']),
        pointsMax: parseInt(item['pointsMax']),
      );
    }).toList(),
  );
}

ExamResultEntry examResultEntryFromJson(Map<String, dynamic> json) {
  return ExamResultEntry(
    attemptId: parseString(json['attemptId']),
    studentId: parseString(json['studentId']),
    studentName: parseString(json['studentName']),
    status: AttemptStatus.fromWire(json['status'] as String?) ??
        AttemptStatus.inProgress,
    score: parseNullableNum(json['score']),
    maxScore: parseNum(json['maxScore']),
    correctCount: parseInt(json['correctCount']),
    questionCount: parseInt(json['questionCount']),
    submittedAt: parseNullableDate(json['submittedAt']),
    violationCount: parseInt(json['violationCount']),
  );
}

ExamResults examResultsFromJson(Map<String, dynamic> json) {
  return ExamResults(
    examId: parseString(json['examId']),
    examTitle: parseString(json['examTitle']),
    status: ExamStatus.fromWire(json['status'] as String?),
    attemptCount: parseInt(json['attemptCount']),
    averageScore: parseNullableNum(json['averageScore']),
    results: asList(json['results'])
        .map(asMap)
        .map(examResultEntryFromJson)
        .toList(),
  );
}

ExamEvent examEventFromJson(Map<String, dynamic> json) {
  final metadata = json['metadata'];
  return ExamEvent(
    id: parseString(json['id']),
    attemptId: parseString(json['attemptId']),
    examId: parseString(json['examId']),
    studentId: parseString(json['studentId']),
    type: ExamEventType.fromWire(json['type'] as String?),
    severity: ExamSeverity.fromWire(json['severity'] as String?),
    state: ExamEventState.fromWire(json['state'] as String?),
    occurredAt: parseDate(json['occurredAt']),
    durationMs: parseNullableInt(json['durationMs']),
    source: parseString(json['source']),
    metadata: metadata is Map<String, dynamic> ? metadata : <String, dynamic>{},
    decision: ExamDecision.fromWire(json['decision'] as String?),
    createdAt: parseDate(json['createdAt']),
  );
}

RecordEventResult recordEventFromJson(Map<String, dynamic> json) {
  return RecordEventResult(
    event: examEventFromJson(asMap(json['event'])),
    attempt: studentAttemptFromJson(asMap(json['attempt'])),
    decision: ExamDecision.fromWire(json['decision'] as String?),
    severity: ExamSeverity.fromWire(json['severity'] as String?),
    remainingMs: parseInt(json['remainingMs']),
    serverNow: parseDate(json['serverNow']),
  );
}

ExamRecording examRecordingFromJson(Map<String, dynamic> json) {
  return ExamRecording(
    id: parseString(json['id']),
    attemptId: parseString(json['attemptId']),
    examId: parseString(json['examId']),
    eventId: parseNullableString(json['eventId']),
    kind: parseString(json['kind']),
    mimeType: parseString(json['mimeType']),
    sizeBytes: parseNullableInt(json['sizeBytes']),
    durationMs: parseNullableInt(json['durationMs']),
    createdAt: parseDate(json['createdAt']),
  );
}

MonitoredAttempt monitoredAttemptFromJson(Map<String, dynamic> json) {
  return MonitoredAttempt(
    id: parseString(json['id']),
    studentId: parseString(json['studentId']),
    studentName: parseString(json['studentName']),
    status: AttemptStatus.fromWire(json['status'] as String?) ??
        AttemptStatus.inProgress,
    startedAt: parseDate(json['startedAt']),
    expiresAt: parseDate(json['expiresAt']),
    submittedAt: parseNullableDate(json['submittedAt']),
    score: parseNullableNum(json['score']),
    maxScore: parseNum(json['maxScore']),
    violationCount: parseInt(json['violationCount']),
    terminatedReason: parseNullableString(json['terminatedReason']),
    answers: asList(json['answers'])
        .map(asMap)
        .map(studentAnswerFromJson)
        .toList(),
  );
}

AttemptMonitoring attemptMonitoringFromJson(Map<String, dynamic> json) {
  return AttemptMonitoring(
    examId: parseString(json['examId']),
    examTitle: parseString(json['examTitle']),
    questionCount: parseInt(json['questionCount']),
    attempt: monitoredAttemptFromJson(asMap(json['attempt'])),
    events: asList(json['events']).map(asMap).map(examEventFromJson).toList(),
    recordings: asList(json['recordings'])
        .map(asMap)
        .map(examRecordingFromJson)
        .toList(),
    questions: asList(json['questions'])
        .map(asMap)
        .map(teacherQuestionFromJson)
        .toList(),
  );
}
