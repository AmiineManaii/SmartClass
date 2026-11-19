import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { ExamDetail } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';

export interface Requester {
  id: string;
  role: Role | null;
}

/** A teacher may only manage exams for a class they actually teach. */
export const assertCanUseClass = async (
  exams: ExamRepositoryPort,
  classGroupId: string,
  requester: Requester,
): Promise<void> => {
  if (requester.role === 'ADMIN') return;
  const allowed = await exams.isTeacherOfClass(requester.id, classGroupId);
  if (!allowed) {
    throw new ForbiddenError('You do not teach this class');
  }
};

/**
 * Author, class teacher or admin only. Returning 404 for a class the teacher
 * does not teach would hide whether the exam exists, but the UI needs a clear
 * 403; keep 403 (no cross-tenant data is leaked, only the id the caller sent).
 */
export const assertCanManageExam = async (
  exams: ExamRepositoryPort,
  exam: ExamDetail,
  requester: Requester,
): Promise<void> => {
  if (requester.role === 'ADMIN') return;
  if (exam.authorId === requester.id) return;
  const allowed = await exams.isTeacherOfClass(requester.id, exam.classGroupId);
  if (!allowed) {
    throw new ForbiddenError('You do not have access to this exam');
  }
};

export const loadExamForTeacher = async (
  exams: ExamRepositoryPort,
  examId: string,
  requester: Requester,
): Promise<ExamDetail> => {
  const exam = await exams.findExamById(examId);
  if (!exam) throw new NotFoundError('Exam not found');
  await assertCanManageExam(exams, exam, requester);
  return exam;
};

export const assertStudentOfExam = async (
  exams: ExamRepositoryPort,
  exam: ExamDetail,
  studentId: string,
): Promise<void> => {
  const enrolled = await exams.isStudentOfClass(studentId, exam.classGroupId);
  if (!enrolled) {
    throw new ForbiddenError('You are not enrolled in this class');
  }
};
