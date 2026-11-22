export { createExamsModule, type ExamsModule, type ExamsModuleOptions } from './exams.module.js';
export { ExamKnowledgeBlueprintService } from './application/exam-knowledge-blueprint.service.js';
export type {
  ExamCoverageReport,
  ExamKnowledgeBlueprint,
  ExamKnowledgeSearchMode,
  ExamKnowledgeSourceAttribution,
  ExamSourceCoverageEntry,
} from './domain/exam-knowledge.types.js';
export type {
  FraudClass,
  FraudReportView,
  FraudSeverity,
  FraudStatus,
  FraudStudent,
  FraudSummary,
} from './domain/fraud-report.entity.js';
export type { FraudRepositoryPort, ListFraudReportsQuery } from './domain/fraud-repository.port.js';
