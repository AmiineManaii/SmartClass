import { Router, type RequestHandler } from 'express';
import type { ExamsController } from './exams.controller.js';
import type { ExamTeacherController } from './exam-teacher.controller.js';
import type { ExamStudentController } from './exam-student.controller.js';
import type { ExamMonitoringController } from './exam-monitoring.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  classCoursesParamsSchema,
  createExamBodySchema,
  eventStateParamsSchema,
  examIdParamsSchema,
  fraudReportIdParamsSchema,
  generateExamAiBodySchema,
  listFraudReportsQuerySchema,
  monitoringParamsSchema,
  recordEventBodySchema,
  recordingParamsSchema,
  recordingUploadBodySchema,
  saveAnswersBodySchema,
  updateEventStateBodySchema,
  updateExamBodySchema,
  updateFraudReportBodySchema,
} from './exams.validation.js';
import {
  examImportUploadMiddleware,
  examRecordingUploadMiddleware,
} from './exam-upload.middleware.js';

export interface ExamsRouterOptions {
  controller: ExamsController;
  teacherController: ExamTeacherController;
  studentController: ExamStudentController;
  monitoringController: ExamMonitoringController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
  requireTeacherMiddleware: RequestHandler;
  requireStudentMiddleware: RequestHandler;
}

export const createExamsRouter = (options: ExamsRouterOptions): Router => {
  const router = Router();
  const {
    controller,
    teacherController,
    studentController,
    monitoringController,
    authenticateMiddleware,
    requireAdminMiddleware,
    requireTeacherMiddleware,
    requireStudentMiddleware,
  } = options;

  router.use(authenticateMiddleware);

  // --- Integrity slice (ADMIN only) ---------------------------------------
  router.get('/fraud-reports/summary', requireAdminMiddleware, controller.getFraudSummary);

  router.get(
    '/fraud-reports',
    requireAdminMiddleware,
    validate({ query: listFraudReportsQuerySchema }),
    controller.listFraudReports,
  );

  router.patch(
    '/fraud-reports/:id',
    requireAdminMiddleware,
    validate({ params: fraudReportIdParamsSchema, body: updateFraudReportBodySchema }),
    controller.updateFraudReport,
  );

  // --- Static teacher routes (before '/:examId') --------------------------
  router.get('/mine', requireTeacherMiddleware, teacherController.listMine);

  router.post(
    '/import',
    requireTeacherMiddleware,
    examImportUploadMiddleware,
    teacherController.importPreview,
  );

  // Published + validated courses the teacher may pick as AI sources.
  router.get(
    '/classes/:classGroupId/courses',
    requireTeacherMiddleware,
    validate({ params: classCoursesParamsSchema }),
    teacherController.classCourses,
  );

  router.post(
    '/ai/generate',
    requireTeacherMiddleware,
    validate({ body: generateExamAiBodySchema }),
    teacherController.generateAi,
  );

  // --- Static student routes (before '/:examId') --------------------------
  router.get('/available', requireStudentMiddleware, studentController.listAvailableExams);

  // --- Exam creation ------------------------------------------------------
  router.post(
    '/',
    requireTeacherMiddleware,
    validate({ body: createExamBodySchema }),
    teacherController.create,
  );

  // --- Student attempt lifecycle -----------------------------------------
  router.post(
    '/:examId/start',
    requireStudentMiddleware,
    validate({ params: examIdParamsSchema }),
    studentController.start,
  );

  router.get(
    '/:examId/attempt',
    requireStudentMiddleware,
    validate({ params: examIdParamsSchema }),
    studentController.currentAttempt,
  );

  router.put(
    '/:examId/attempt/answers',
    requireStudentMiddleware,
    validate({ params: examIdParamsSchema, body: saveAnswersBodySchema }),
    studentController.save,
  );

  router.post(
    '/:examId/attempt/submit',
    requireStudentMiddleware,
    validate({ params: examIdParamsSchema }),
    studentController.submit,
  );

  router.get(
    '/:examId/attempt/result',
    requireStudentMiddleware,
    validate({ params: examIdParamsSchema }),
    studentController.result,
  );

  router.post(
    '/:examId/attempt/events',
    requireStudentMiddleware,
    validate({ params: examIdParamsSchema, body: recordEventBodySchema }),
    studentController.reportEvent,
  );

  router.post(
    '/:examId/attempt/recordings',
    requireStudentMiddleware,
    examRecordingUploadMiddleware,
    validate({ params: examIdParamsSchema, body: recordingUploadBodySchema }),
    studentController.uploadRecording,
  );

  // --- Teacher management -------------------------------------------------
  router.get(
    '/:examId',
    requireTeacherMiddleware,
    validate({ params: examIdParamsSchema }),
    teacherController.getOne,
  );

  router.patch(
    '/:examId',
    requireTeacherMiddleware,
    validate({ params: examIdParamsSchema, body: updateExamBodySchema }),
    teacherController.update,
  );

  router.patch(
    '/:examId/publish',
    requireTeacherMiddleware,
    validate({ params: examIdParamsSchema }),
    teacherController.publish,
  );

  router.patch(
    '/:examId/close',
    requireTeacherMiddleware,
    validate({ params: examIdParamsSchema }),
    teacherController.close,
  );

  router.get(
    '/:examId/results',
    requireTeacherMiddleware,
    validate({ params: examIdParamsSchema }),
    teacherController.results,
  );

  router.get(
    '/:examId/attempts/:attemptId',
    requireTeacherMiddleware,
    validate({ params: monitoringParamsSchema }),
    monitoringController.attempt,
  );

  router.patch(
    '/:examId/events/:eventId',
    requireTeacherMiddleware,
    validate({ params: eventStateParamsSchema, body: updateEventStateBodySchema }),
    monitoringController.setEventState,
  );

  router.get(
    '/:examId/recordings/:recordingId/stream',
    requireTeacherMiddleware,
    validate({ params: recordingParamsSchema }),
    monitoringController.streamRecording,
  );

  router.delete(
    '/:examId/recordings/:recordingId',
    requireTeacherMiddleware,
    validate({ params: recordingParamsSchema }),
    monitoringController.removeRecording,
  );

  return router;
};
