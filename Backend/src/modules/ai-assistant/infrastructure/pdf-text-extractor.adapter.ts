import { extractText } from 'unpdf';
import { ValidationError } from '../../../shared/errors/app-error.js';

export interface ExtractedPdf {
  text: string;
  totalPages: number;
}

export interface PdfTextExtractorPort {
  extract(buffer: Buffer): Promise<ExtractedPdf>;
}

const PDF_MAGIC = Buffer.from('%PDF');

export class UnpdfTextExtractor implements PdfTextExtractorPort {
  public async extract(buffer: Buffer): Promise<ExtractedPdf> {
    if (buffer.length === 0 || !buffer.subarray(0, PDF_MAGIC.length).equals(PDF_MAGIC)) {
      throw new ValidationError('Invalid PDF file', [
        { path: 'file', message: 'The uploaded file is not a valid PDF document' },
      ]);
    }
    let extracted: { text: string; totalPages: number };
    try {
      const result = await extractText(new Uint8Array(buffer));
      const pages = Array.isArray(result.text) ? result.text : [result.text];
      extracted = {
        text: pages
          .filter((page): page is string => typeof page === 'string')
          .join('\n\n')
          .trim(),
        totalPages: result.totalPages ?? 0,
      };
    } catch {
      throw new ValidationError('Unreadable PDF file', [
        { path: 'file', message: 'Text could not be extracted (scanned or protected PDF?)' },
      ]);
    }
    const { text, totalPages } = extracted;
    if (text.length < 100) {
      throw new ValidationError('PDF without usable text', [
        { path: 'file', message: 'Less than 100 characters of text extracted' },
      ]);
    }
    return { text, totalPages };
  }
}
