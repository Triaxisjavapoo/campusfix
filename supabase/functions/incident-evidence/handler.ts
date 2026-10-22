const MAX_BYTES = 5 * 1024 * 1024;
const ID = /^[A-Za-z0-9_-]{1,128}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const MIME_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

interface StorageError {
  message: string;
  statusCode?: string | number;
}
interface Storage {
  upload(path: string, body: Uint8Array, options: {
    contentType: string;
    upsert: boolean;
    cacheControl: string;
  }): Promise<{ error: StorageError | null }>;
  download(path: string): Promise<{ data: Blob | null; error: StorageError | null }>;
  remove(paths: string[]): Promise<{ error: StorageError | null }>;
}
interface Dependencies {
  projectId: string;
  allowedOrigins: string[];
  verifyToken(token: string): Promise<string>;
  storage: Storage;
  fetcher?: typeof fetch;
}
type Fields = Record<
  string,
  { stringValue?: string; booleanValue?: boolean; integerValue?: string }
>;

class RequestError extends Error {
  constructor(readonly status: number, readonly code: string) {
    super(code);
  }
}

export function validImage(bytes: Uint8Array, type: string): boolean {
  if (type === "image/jpeg") {
    return bytes.length >= 3 &&
      bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  }
  if (type === "image/png") {
    return bytes.length >= 8 &&
      [137, 80, 78, 71, 13, 10, 26, 10].every((value, index) => bytes[index] === value);
  }
  if (type === "image/webp") {
    return bytes.length >= 12 &&
      new TextDecoder().decode(bytes.subarray(0, 4)) === "RIFF" &&
      new TextDecoder().decode(bytes.subarray(8, 12)) === "WEBP";
  }
  return false;
}

async function readImage(req: Request): Promise<Uint8Array> {
  if (Number(req.headers.get("content-length")) > MAX_BYTES) {
    throw new RequestError(413, "image_too_large");
  }
  const reader = req.body?.getReader();
  if (!reader) throw new RequestError(400, "empty_image");
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > MAX_BYTES) {
        await reader.cancel();
        throw new RequestError(413, "image_too_large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  if (!size) throw new RequestError(400, "empty_image");
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  return bytes;
}

export function createEvidenceHandler(deps: Dependencies): (req: Request) => Promise<Response> {
  const fetcher = deps.fetcher ?? fetch;
  const documentRoot = `projects/${deps.projectId}/databases/(default)/documents`;
  const firestoreRoot = `https://firestore.googleapis.com/v1/${documentRoot}`;

  async function firestore(token: string, path: string, body?: unknown): Promise<unknown> {
    const response = await fetcher(`${firestoreRoot}${path}`, {
      method: body ? "POST" : "GET",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(20000),
    });
    if (!response.ok) {
      const code = response.status;
      throw new RequestError(
        code === 401 || code === 403 || code === 404 || code === 429 ? code : 503,
        "firestore_access_failed",
      );
    }
    return response.json();
  }

  async function document(token: string, path: string): Promise<Fields> {
    const result = await firestore(token, path) as { fields?: Fields };
    if (!result.fields) throw new RequestError(404, "document_not_found");
    return result.fields;
  }

  return async (req: Request): Promise<Response> => {
    const origin = req.headers.get("origin");
    const allowedOrigin = origin && (deps.allowedOrigins.includes(origin) ||
      /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(origin));
    const headers = new Headers({
      "Cache-Control": "no-store, private",
      "X-Content-Type-Options": "nosniff",
      "Vary": "Origin",
    });
    if (allowedOrigin) {
      headers.set("Access-Control-Allow-Origin", origin!);
      headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      headers.set(
        "Access-Control-Allow-Headers",
        "authorization, content-type, apikey, x-client-info",
      );
    }
    const json = (status: number, data: unknown) =>
      new Response(JSON.stringify(data), {
        status,
        headers: new Headers([...headers, ["Content-Type", "application/json"]]),
      });
    if (origin && !allowedOrigin) return json(403, { error: "origin_not_allowed" });
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
    if (req.method !== "GET" && req.method !== "POST") {
      headers.set("Allow", "GET, POST, OPTIONS");
      return json(405, { error: "method_not_allowed" });
    }

    let requestStage = "authorization";
    try {
      const match = /^Bearer ([A-Za-z0-9_.-]+)$/.exec(req.headers.get("authorization") ?? "");
      if (!match) throw new RequestError(401, "authentication_required");
      const token = match[1];
      let uid: string;
      try {
        uid = await deps.verifyToken(token);
      } catch {
        throw new RequestError(401, "invalid_firebase_session");
      }
      if (!ID.test(uid)) throw new RequestError(401, "invalid_firebase_identity");
      const url = new URL(req.url);
      const incidentId = url.searchParams.get("incidentId") ?? "";
      if (!ID.test(incidentId)) throw new RequestError(400, "invalid_incident_id");

      // Both REST reads use the caller's Firebase token. Firestore Security Rules
      // remain authoritative, including current role, active status and assignment.
      const profile = await document(token, `/users/${encodeURIComponent(uid)}`);
      if (profile.active?.booleanValue !== true) throw new RequestError(403, "inactive_profile");
      await document(token, `/incidents/${incidentId}`);

      if (req.method === "GET") {
        requestStage = "download";
        const evidenceId = url.searchParams.get("evidenceId") ?? "";
        if (!UUID.test(evidenceId)) throw new RequestError(400, "invalid_evidence_id");
        const evidence = await document(token, `/incidents/${incidentId}/evidence/${evidenceId}`);
        const uploader = evidence.uploaderId?.stringValue ?? "";
        const type = evidence.contentType?.stringValue ?? "";
        const path = `incidents/${incidentId}/${uploader}/${evidenceId}`;
        if (
          !ID.test(uploader) || evidence.path?.stringValue !== path ||
          evidence.storageProvider?.stringValue !== "supabase" || !MIME_TYPES.has(type)
        ) {
          throw new RequestError(404, "image_not_found");
        }
        const { data, error } = await deps.storage.download(path);
        if (error) {
          throw new RequestError(
            String(error.statusCode) === "404" ? 404 : 503,
            "storage_download_failed",
          );
        }
        if (!data) throw new RequestError(404, "image_not_found");
        if (data.size > MAX_BYTES) throw new RequestError(413, "image_too_large");
        headers.set("Content-Type", type);
        headers.set("Content-Disposition", "inline");
        return new Response(data, { status: 200, headers });
      }

      requestStage = "upload";
      const name = (url.searchParams.get("name") ?? "").trim();
      const type = (req.headers.get("content-type") ?? "").split(";")[0].trim().toLowerCase();
      if (!name || name.length > 180 || /[\u0000-\u001f]/.test(name)) {
        throw new RequestError(400, "invalid_filename");
      }
      if (!MIME_TYPES.has(type)) throw new RequestError(415, "unsupported_image");
      const bytes = await readImage(req);
      if (!validImage(bytes, type)) throw new RequestError(415, "invalid_image_signature");
      const id = crypto.randomUUID();
      const path = `incidents/${incidentId}/${uid}/${id}`;
      const uploaded = await deps.storage.upload(path, bytes, {
        contentType: type,
        upsert: false,
        cacheControl: "0",
      });
      if (uploaded.error) {
        const code = String(uploaded.error.statusCode);
        throw new RequestError(
          code === "413" ? 413 : code === "429" ? 429 : code === "507" ? 507 : 503,
          "storage_upload_failed",
        );
      }
      try {
        // Server timestamps satisfy the existing evidence rules. Authorization is
        // rechecked at commit time, so a revoked assignment also cancels the upload.
        const stringValue = (value: string) => ({ stringValue: value });
        await firestore(token, ":commit", {
          writes: [{
            update: {
              name: `${documentRoot}/incidents/${incidentId}/evidence/${id}`,
              fields: {
                uploaderId: stringValue(uid),
                uploaderName: stringValue(profile.name?.stringValue ?? ""),
                name: stringValue(name),
                path: stringValue(path),
                contentType: stringValue(type),
                storageProvider: stringValue("supabase"),
                size: { integerValue: String(bytes.length) },
              },
            },
            currentDocument: { exists: false },
            updateTransforms: [{ fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" }],
          }],
        });
      } catch (error) {
        // A timeout may mean the commit succeeded but its response was lost.
        // Read it back before compensating; never delete a confirmed attachment.
        let committed = false;
        try {
          const saved = await document(token, `/incidents/${incidentId}/evidence/${id}`);
          committed = saved.path?.stringValue === path &&
            saved.storageProvider?.stringValue === "supabase";
        } catch (readError) {
          const definiteRejection = error instanceof RequestError &&
            [401, 403, 404, 429].includes(error.status);
          const missing = readError instanceof RequestError && readError.status === 404;
          if (!definiteRejection && !missing) {
            console.error("campusfix_evidence_commit_unknown", id);
            throw new RequestError(503, "check_report_before_retry");
          }
        }
        if (!committed) {
          const cleanup = await deps.storage.remove([path]);
          if (cleanup.error) console.error("campusfix_evidence_cleanup_required", id);
          throw error;
        }
      }
      return json(201, { evidenceId: id });
    } catch (error) {
      if (error instanceof RequestError) return json(error.status, { error: error.code });
      // Keep tokens, file bytes, names and provider secrets out of logs/responses.
      console.error("campusfix_evidence_unavailable", requestStage);
      return json(503, { error: "evidence_service_unavailable" });
    }
  };
}
