import multer, { type FileFilterCallback } from 'multer';
import type { Request, Response, NextFunction } from 'express';
import { getEnv } from '../../../config/env.js';
import { ValidationError } from '../../../shared/errors/app-error.js';

const importUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 1 },
  fileFilter: (_req: Request, file: Express.Multer.File, callback: FileFilterCallback): void => {
    const name = file.originalname.toLowerCase();
    const supported =
      name.endsWith('.json') ||
      name.endsWith('.csv') ||
      name.endsWith('.txt') ||
      ['application/json', 'text/csv', 'text/plain'].includes(file.mimetype);
    if (!supported) {
      callback(
        new ValidationError('Unsupported exam file', [
          { path: 'file', message: 'Upload a .json, .csv or .txt file (max 10 MB)' },
        ]),
      );
      return;
    }
    callback(null, true);
  },
});

const recordingUpload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: getEnv().STORAGE_MAX_UPLOAD_MB * 1024 * 1024,
    files: 1,
  },
  fileFilter: (_req: Request, file: Express.Multer.File, callback: FileFilterCallback): void => {
    const name = file.originalname.toLowerCase();
    const baseMime = file.mimetype.split(';')[0]?.trim();
    const supported =
      name.endsWith('.webm') ||
      name.endsWith('.mp4') ||
      baseMime === 'video/webm' ||
      baseMime === 'video/mp4';
    if (!supported) {
      callback(
        new ValidationError('Unsupported recording format', [
          { path: 'file', message: 'Upload a WebM or MP4 video segment' },
        ]),
      );
      return;
    }
    callback(null, true);
  },
});

const mapMulterError = (error: unknown, field: string, label: string): unknown => {
  if (error instanceof ValidationError) return error;
  if (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code: string }).code === 'LIMIT_FILE_SIZE'
  ) {
    return new ValidationError(`${label} is too large`, [
      { path: field, message: `Maximum size is ${getEnv().STORAGE_MAX_UPLOAD_MB} MB` },
    ]);
  }
  return error;
};

export const examImportUploadMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  importUpload.single('file')(req, res, (error: unknown) => {
    if (error) {
      next(mapMulterError(error, 'file', 'Exam file'));
      return;
    }
    if (!req.file) {
      next(
        new ValidationError('Exam file is required', [
          { path: 'file', message: 'Attach a .json, .csv or .txt file in the file field' },
        ]),
      );
      return;
    }
    next();
  });
};

export const examRecordingUploadMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  recordingUpload.single('file')(req, res, (error: unknown) => {
    if (error) {
      next(mapMulterError(error, 'file', 'Recording segment'));
      return;
    }
    if (!req.file) {
      next(
        new ValidationError('Recording file is required', [
          { path: 'file', message: 'Attach a WebM or MP4 segment in the file field' },
        ]),
      );
      return;
    }
    next();
  });
};
