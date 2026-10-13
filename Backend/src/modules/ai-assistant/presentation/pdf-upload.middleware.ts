import multer, { type FileFilterCallback } from 'multer';
import type { Request, Response, NextFunction } from 'express';
import { ValidationError } from '../../../shared/errors/app-error.js';

const MAX_PDF_BYTES = 25 * 1024 * 1024;

const pdfOnlyFilter = (
  _req: Request,
  file: Express.Multer.File,
  callback: FileFilterCallback,
): void => {
  const isPdf =
    file.mimetype === 'application/pdf' || file.originalname.toLowerCase().endsWith('.pdf');
  if (!isPdf) {
    callback(
      new ValidationError('Only PDF files are supported', [
        { path: 'file', message: 'Upload a .pdf document (max 25 MB)' },
      ]),
    );
    return;
  }
  callback(null, true);
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_PDF_BYTES, files: 1 },
  fileFilter: pdfOnlyFilter,
});

/**
 * Single-PDF upload (`file` field) mapped onto backend stable errors:
 * missing/invalid file → 422, oversized file → 422 (documented).
 */
export const pdfUploadMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  upload.single('file')(req, res, (error: unknown) => {
    if (error) {
      if (error instanceof ValidationError) {
        next(error);
        return;
      }
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        (error as { code: string }).code === 'LIMIT_FILE_SIZE'
      ) {
        next(
          new ValidationError('PDF file too large', [
            { path: 'file', message: 'Maximum size is 25 MB' },
          ]),
        );
        return;
      }
      next(error);
      return;
    }
    if (!req.file) {
      next(
        new ValidationError('PDF file is required', [
          { path: 'file', message: 'Attach the course PDF in the file field' },
        ]),
      );
      return;
    }
    next();
  });
};
