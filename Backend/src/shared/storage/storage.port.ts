export interface StorageObjectStat {
  key: string;
  sizeBytes: number;
  mtime: Date;
  mimeType: string;
}

export interface ByteRange {
  start: number;
  end: number;
}

/**
 * Parses an HTTP Range header (`bytes=start-end`) against `totalSizeBytes`.
 * Returns `null` if the header is malformed or out of bounds (HTTP 416).
 */
export const parseHttpRangeHeader = (
  rangeHeader: string | undefined,
  totalSizeBytes: number,
): ByteRange | null => {
  if (!rangeHeader || !rangeHeader.startsWith('bytes=') || totalSizeBytes <= 0) {
    return null;
  }
  const spec = rangeHeader.slice('bytes='.length).split(',')[0]?.trim();
  if (!spec) return null;
  const [startStr, endStr] = spec.split('-');
  if (startStr === undefined || endStr === undefined) return null;

  if (startStr === '' && endStr !== '') {
    // Suffix byte-range-spec: "-500" means last 500 bytes
    const suffixLen = Number.parseInt(endStr, 10);
    if (!Number.isFinite(suffixLen) || suffixLen <= 0) return null;
    const start = Math.max(0, totalSizeBytes - suffixLen);
    return { start, end: totalSizeBytes - 1 };
  }

  const start = Number.parseInt(startStr, 10);
  const end =
    endStr === '' ? totalSizeBytes - 1 : Math.min(totalSizeBytes - 1, Number.parseInt(endStr, 10));

  if (!Number.isFinite(start) || !Number.isFinite(end) || start < 0 || start > end || start >= totalSizeBytes) {
    return null;
  }
  return { start, end };
};

/**
 * Abstract StoragePort for media recordings, extracted audio/frames,
 * subtitle tracks, and uploaded lecture documents.
 *
 * Designed for streaming large media files without loading entire videos
 * into memory, and extensible to S3-compatible adapters in future phases.
 */
export interface StoragePort {
  /**
   * Validates and normalizes a storage key. Rejects path traversal (`..`),
   * null bytes, drive prefixes, and absolute paths.
   */
  resolveSafeKey(key: string): string;

  /**
   * Opens a writable stream for saving large media files.
   */
  createWriteStream(key: string): Promise<NodeJS.WritableStream>;

  /**
   * Writes a buffer or Uint8Array directly to storage and returns metadata.
   */
  writeBuffer(key: string, data: Buffer | Uint8Array): Promise<StorageObjectStat>;
  putBuffer(key: string, data: Buffer | Uint8Array): Promise<StorageObjectStat>;

  /**
   * Opens a readable stream, optionally bounded to an inclusive byte range
   * `[start, end]` for HTTP 206 Partial Content playback.
   */
  createReadStream(key: string, range?: ByteRange): Promise<NodeJS.ReadableStream>;

  /**
   * Reads a small file (e.g., VTT, SRT, frame image, PDF) into a Buffer.
   */
  readBuffer(key: string): Promise<Buffer>;

  /**
   * Returns file metadata (`sizeBytes`, `mtime`, `mimeType`) or `null` if absent.
   */
  stat(key: string): Promise<StorageObjectStat | null>;

  /**
   * Checks whether the storage key exists.
   */
  exists(key: string): Promise<boolean>;

  /**
   * Deletes a stored object if it exists (idempotent).
   */
  delete(key: string): Promise<void>;

  /**
   * Resolves the internal filesystem path ONLY for local server-side tools
   * (LiveKit Egress, FFmpeg). Never expose this value in any HTTP response.
   */
  resolveInternalFilePath(key: string): string;
  resolveSafePath(key: string): string;
}
