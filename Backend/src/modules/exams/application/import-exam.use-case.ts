import type { ImportedExamPreview } from '../infrastructure/exam-import.parser.js';
import { parseExamImport, type ExamImportFile } from '../infrastructure/exam-import.parser.js';

export class ImportExamUseCase {
  public execute(file: ExamImportFile): ImportedExamPreview {
    return parseExamImport(file);
  }
}
