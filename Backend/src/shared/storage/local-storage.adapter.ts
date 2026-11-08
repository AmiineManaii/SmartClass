import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { getEnv } from '../../config/env.js';
import { NotFoundError, StorageAccessDeniedError } from '../errors/app-error.js';
import type { ByteRange, StorageObjectStat, StoragePort } from './storage.port.js';

const MIME_BY_EXT: Record<string, string> = {
  '.mp4': 'video/mp4',
  '.webm': 'video/webm',
  '.mkv': 'video/x-matroska',
  '.wav': 'audio/wav',
  '.m4a': 'audio/mp4',
  '.mp3': 'audio/mpeg',
  '.vtt': 'text/vtt; charset=utf-8',
  '.srt': 'application/x-subrip; charset=utf-8',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.pdf': 'application/pdf',
  '.json': 'application/json',
};

const inferMimeType = (key: string): string => {
  const ext = path.extname(key).toLowerCase();
  return MIME_BY_EXT[ext] ?? 'application/octet-stream';
};

export class LocalStorageAdapter implements StoragePort {
  private readonly rootDir: string;

  constructor(rootDir?: string) {
    const configured = rootDir ?? getEnv().STORAGE_LOCAL_ROOT;
    this.rootDir = path.resolve(configured);
    try {
      fsp.mkdir(this.rootDir, { recursive: true }).then(() => fsp.chmod(this.rootDir, 0o777)).catch(() => {});
    } catch {}
  }

  public getRootDir(): string {
    return this.rootDir;
  }

  public resolveSafeKey(rawKey: string): string {
    if (!rawKey || typeof rawKey !== 'string') {
      throw new StorageAccessDeniedError('Storage key must be a non-empty string');
    }
    if (rawKey.includes('\0')) {
      throw new StorageAccessDeniedError('Storage key contains null byte');
    }
    // Reject backslashes, drive letters, and leading slashes
    if (rawKey.includes('\\') || /^[a-zA-Z]:/.test(rawKey) || rawKey.startsWith('/')) {
      throw new StorageAccessDeniedError('Storage key must be a relative POSIX key');
    }

    const segments = rawKey.split('/').filter((s) => s.length > 0);
    if (segments.length === 0) {
      throw new StorageAccessDeniedError('Storage key cannot be empty');
    }

    for (const seg of segments) {
      if (seg === '.' || seg === '..' || !/^[a-zA-Z0-9._-]+$/.test(seg)) {
        throw new StorageAccessDeniedError(`Invalid storage key segment: ${seg}`);
      }
    }

    const normalizedKey = segments.join('/');
    const resolvedPath = path.resolve(this.rootDir, ...segments);
    const rootWithSep = this.rootDir.endsWith(path.sep)
      ? this.rootDir
      : `${this.rootDir}${path.sep}`;

    if (!resolvedPath.startsWith(rootWithSep)) {
      throw new StorageAccessDeniedError('Path traversal detected');
    }

    return normalizedKey;
  }

  public resolveInternalFilePath(key: string): string {
    const safeKey = this.resolveSafeKey(key);
    return path.resolve(this.rootDir, ...safeKey.split('/'));
  }

  public resolveSafePath(key: string): string {
    return this.resolveInternalFilePath(key);
  }

  private async ensureParentDir(fullPath: string): Promise<void> {
    const parent = path.dirname(fullPath);
    await fsp.mkdir(parent, { recursive: true });
    try {
      await fsp.chmod(parent, 0o777);
    } catch {}
  }

  public async createWriteStream(key: string): Promise<NodeJS.WritableStream> {
    const fullPath = this.resolveInternalFilePath(key);
    await this.ensureParentDir(fullPath);
    return fs.createWriteStream(fullPath);
  }

  public async writeBuffer(key: string, data: Buffer | Uint8Array): Promise<StorageObjectStat> {
    const safeKey = this.resolveSafeKey(key);
    const fullPath = this.resolveInternalFilePath(safeKey);
    await this.ensureParentDir(fullPath);
    await fsp.writeFile(fullPath, data);
    const st = await fsp.stat(fullPath);
    return {
      key: safeKey,
      sizeBytes: st.size,
      mtime: st.mtime,
      mimeType: inferMimeType(safeKey),
    };
  }

  public async putBuffer(key: string, data: Buffer | Uint8Array): Promise<StorageObjectStat> {
    return this.writeBuffer(key, data);
  }

  public async createReadStream(key: string, range?: ByteRange): Promise<NodeJS.ReadableStream> {
    const safeKey = this.resolveSafeKey(key);
    const fullPath = this.resolveInternalFilePath(safeKey);
    const exists = await this.exists(safeKey);
    if (!exists) {
      throw new NotFoundError('Stored media file not found');
    }

    if (range) {
      if (range.start < 0 || range.end < range.start) {
        throw new StorageAccessDeniedError('Invalid byte range');
      }
      return fs.createReadStream(fullPath, { start: range.start, end: range.end });
    }

    return fs.createReadStream(fullPath);
  }

  public async readBuffer(key: string): Promise<Buffer> {
    const safeKey = this.resolveSafeKey(key);
    const fullPath = this.resolveInternalFilePath(safeKey);
    try {
      return await fsp.readFile(fullPath);
    } catch {
      throw new NotFoundError('Stored file not found');
    }
  }

  public async stat(key: string): Promise<StorageObjectStat | null> {
    const safeKey = this.resolveSafeKey(key);
    const fullPath = this.resolveInternalFilePath(safeKey);
    try {
      const st = await fsp.stat(fullPath);
      if (!st.isFile()) return null;
      return {
        key: safeKey,
        sizeBytes: st.size,
        mtime: st.mtime,
        mimeType: inferMimeType(safeKey),
      };
    } catch {
      return null;
    }
  }

  public async exists(key: string): Promise<boolean> {
    const st = await this.stat(key);
    return st !== null;
  }

  public async delete(key: string): Promise<void> {
    const safeKey = this.resolveSafeKey(key);
    const fullPath = this.resolveInternalFilePath(safeKey);
    try {
      await fsp.unlink(fullPath);
    } catch {
      // Idempotent delete
    }
  }
}
