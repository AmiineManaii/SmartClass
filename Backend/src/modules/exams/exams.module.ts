import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireApprovedTeacherMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import { getEnv } from '../../config/env.js';
import type { StoragePort } from '../../shared/storage/storage.port.js';
import { LocalStorageAdapter } from '../../shared/storage/local-storage.adapter.js';
import type { AiGatewayPort } from '../ai-assistant/index.js';
import { OpenAICompatibleGateway } from '../ai-assistant/index.js';
import type { FraudRepositoryPort } from './domain/fraud-repository.port.js';
import type { ExamRepositoryPort } from './domain/exam-repository.port.js';
import type { ExamAiModelCatalogPort } from './domain/exam-ai-model-catalog.port.js';
import { PrismaFraudRepositoryAdapter } from './infrastructure/prisma-fraud-repository.adapter.js';
import { PrismaExamRepositoryAdapter } from './infrastructure/prisma-exam-repository.adapter.js';
import { OllamaExamModelCatalogAdapter } from './infrastructure/ollama-exam-model-catalog.adapter.js';
import { ListFraudReportsUseCase } from './application/list-fraud-reports.use-case.js';
import { GetFraudSummaryUseCase } from './application/get-fraud-summary.use-case.js';
import { UpdateFraudReportUseCase } from './application/update-fraud-report.use-case.js';
import { CreateExamUseCase } from './application/create-exam.use-case.js';
import { UpdateExamUseCase } from './application/update-exam.use-case.js';
import { ListMyExamsUseCase } from './application/list-my-exams.use-case.js';
import { GetTeacherExamUseCase } from './application/get-teacher-exam.use-case.js';
import { PublishExamUseCase } from './application/publish-exam.use-case.js';
import { CloseExamUseCase } from './application/close-exam.use-case.js';
import { ImportExamUseCase } from './application/import-exam.use-case.js';
import { GenerateExamAiUseCase } from './application/generate-exam-ai.use-case.js';
import { ListClassCoursesUseCase } from './application/list-class-courses.use-case.js';
import { ListAvailableExamsUseCase } from './application/list-available-exams.use-case.js';
import { StartAttemptUseCase } from './application/start-attempt.use-case.js';
import { GetAttemptUseCase } from './application/get-attempt.use-case.js';
import { SaveAnswersUseCase } from './application/save-answers.use-case.js';
import { SubmitAttemptUseCase } from './application/submit-attempt.use-case.js';
import { GetStudentResultUseCase } from './application/get-student-result.use-case.js';
import { RecordEventUseCase } from './application/record-event.use-case.js';
import { GetExamResultsUseCase } from './application/get-exam-results.use-case.js';
import { GetAttemptMonitoringUseCase } from './application/get-attempt-monitoring.use-case.js';
import { UpdateEventStateUseCase } from './application/update-event-state.use-case.js';
import { SaveRecordingUseCase } from './application/save-recording.use-case.js';
import { ResolveRecordingUseCase } from './application/resolve-recording.use-case.js';
import { DeleteRecordingUseCase } from './application/delete-recording.use-case.js';
import { ExamsController } from './presentation/exams.controller.js';
import { ExamTeacherController } from './presentation/exam-teacher.controller.js';
import { ExamStudentController } from './presentation/exam-student.controller.js';
import { ExamMonitoringController } from './presentation/exam-monitoring.controller.js';
import { createExamsRouter } from './presentation/exams.routes.js';

export interface ExamsModuleOptions {
  fraudRepository?: FraudRepositoryPort;
  examRepository?: ExamRepositoryPort;
  storage?: StoragePort;
  aiGateway?: AiGatewayPort;
  aiModelCatalog?: ExamAiModelCatalogPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
  requireTeacherMiddleware?: RequestHandler;
  requireStudentMiddleware?: RequestHandler;
}

export interface ExamsModule {
  router: Router;
  controller: ExamsController;
  teacherController: ExamTeacherController;
  studentController: ExamStudentController;
  monitoringController: ExamMonitoringController;
}

export const createExamsModule = (options: ExamsModuleOptions = {}): ExamsModule => {
  const fraudRepository = options.fraudRepository ?? new PrismaFraudRepositoryAdapter();
  const examRepository = options.examRepository ?? new PrismaExamRepositoryAdapter();
  const storage = options.storage ?? new LocalStorageAdapter();
  const env = getEnv();
  const aiGateway =
    options.aiGateway ??
    new OpenAICompatibleGateway({
      model: env.AI_MODEL,
      fallbackModel: env.AI_MODEL,
    });
  const aiModelCatalog = options.aiModelCatalog ?? new OllamaExamModelCatalogAdapter();

  const listFraudReportsUseCase = new ListFraudReportsUseCase(fraudRepository);
  const getFraudSummaryUseCase = new GetFraudSummaryUseCase(fraudRepository);
  const updateFraudReportUseCase = new UpdateFraudReportUseCase(fraudRepository);

  const createExamUseCase = new CreateExamUseCase(examRepository);
  const updateExamUseCase = new UpdateExamUseCase(examRepository);
  const listMyExamsUseCase = new ListMyExamsUseCase(examRepository);
  const getTeacherExamUseCase = new GetTeacherExamUseCase(examRepository);
  const publishExamUseCase = new PublishExamUseCase(examRepository);
  const closeExamUseCase = new CloseExamUseCase(examRepository);
  const importExamUseCase = new ImportExamUseCase();
  const generateExamAiUseCase = new GenerateExamAiUseCase(
    examRepository,
    aiGateway,
    aiModelCatalog,
    env.AI_MODEL,
  );
  const listClassCoursesUseCase = new ListClassCoursesUseCase(examRepository);
  const listAvailableExamsUseCase = new ListAvailableExamsUseCase(examRepository);
  const startAttemptUseCase = new StartAttemptUseCase(examRepository);
  const getAttemptUseCase = new GetAttemptUseCase(examRepository);
  const saveAnswersUseCase = new SaveAnswersUseCase(examRepository);
  const submitAttemptUseCase = new SubmitAttemptUseCase(examRepository);
  const getStudentResultUseCase = new GetStudentResultUseCase(examRepository);
  const recordEventUseCase = new RecordEventUseCase(examRepository);
  const getExamResultsUseCase = new GetExamResultsUseCase(examRepository);
  const getAttemptMonitoringUseCase = new GetAttemptMonitoringUseCase(examRepository);
  const updateEventStateUseCase = new UpdateEventStateUseCase(examRepository);
  const saveRecordingUseCase = new SaveRecordingUseCase(examRepository, storage);
  const resolveRecordingUseCase = new ResolveRecordingUseCase(examRepository);
  const deleteRecordingUseCase = new DeleteRecordingUseCase(examRepository, storage);

  const controller = new ExamsController(
    listFraudReportsUseCase,
    getFraudSummaryUseCase,
    updateFraudReportUseCase,
  );
  const teacherController = new ExamTeacherController(
    createExamUseCase,
    updateExamUseCase,
    listMyExamsUseCase,
    getTeacherExamUseCase,
    publishExamUseCase,
    closeExamUseCase,
    importExamUseCase,
    generateExamAiUseCase,
    listClassCoursesUseCase,
    getExamResultsUseCase,
  );
  const studentController = new ExamStudentController(
    listAvailableExamsUseCase,
    startAttemptUseCase,
    getAttemptUseCase,
    saveAnswersUseCase,
    submitAttemptUseCase,
    getStudentResultUseCase,
    recordEventUseCase,
    saveRecordingUseCase,
  );
  const monitoringController = new ExamMonitoringController(
    getAttemptMonitoringUseCase,
    updateEventStateUseCase,
    resolveRecordingUseCase,
    deleteRecordingUseCase,
    storage,
  );

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('ExamsModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);
  const requireTeacherMiddleware =
    options.requireTeacherMiddleware ??
    createRequireApprovedTeacherMiddleware(['TEACHER', 'ADMIN'] as Role[]);
  const requireStudentMiddleware =
    options.requireStudentMiddleware ?? createRequireRoleMiddleware(['STUDENT'] as Role[]);

  const router = createExamsRouter({
    controller,
    teacherController,
    studentController,
    monitoringController,
    authenticateMiddleware,
    requireAdminMiddleware,
    requireTeacherMiddleware,
    requireStudentMiddleware,
  });

  return { router, controller, teacherController, studentController, monitoringController };
};
