import { createEvidenceHandler } from "./handler.ts";

const png = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10, 1]);
const origin = "https://campusfix-ae32e.web.app";
const base = "https://example.supabase.co/functions/v1/incident-evidence";
const id = "2f5236cd-5028-445c-a740-704c8cbd5f29";
function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function fixture(
  options: {
    inactive?: boolean;
    denyIncident?: boolean;
    denyCommit?: boolean;
    unknownCommit?: boolean;
    invalidToken?: boolean;
  } = {},
) {
  const uploads: string[] = [];
  const removals: string[] = [];
  const downloads: string[] = [];
  const writes: unknown[] = [];
  const response = (data: unknown, status = 200) => Response.json(data, { status });
  const handler = createEvidenceHandler({
    projectId: "campusfix-ae32e",
    allowedOrigins: [origin],
    verifyToken: async () => {
      if (options.invalidToken) throw new Error("bad signature");
      return "reporter";
    },
    storage: {
      async upload(path) {
        uploads.push(path);
        return { error: null };
      },
      async remove(paths) {
        removals.push(...paths);
        return { error: null };
      },
      async download(path) {
        downloads.push(path);
        return { data: new Blob([png]), error: null };
      },
    },
    fetcher: (async (input: string | URL | Request, init?: RequestInit) => {
      assert(new Headers(init?.headers).get("authorization") === "Bearer firebase.token");
      const url = String(input);
      if (url.endsWith("/users/reporter")) {
        return response({
          fields: {
            name: { stringValue: "Reportante" },
            active: { booleanValue: !options.inactive },
          },
        });
      }
      if (url.endsWith("/incidents/case1")) {
        return options.denyIncident ? response({}, 403) : response({ fields: {} });
      }
      if (url.endsWith(":commit")) {
        writes.push(JSON.parse(String(init?.body)));
        if (options.denyCommit) return response({}, 403);
        if (options.unknownCommit) throw new Error("Connection lost");
        return response({});
      }
      if (url.includes("/evidence/")) {
        if (options.unknownCommit) throw new Error("Connection still unavailable");
        if (options.denyCommit) return response({}, 403);
        return response({
          fields: {
            uploaderId: { stringValue: "reporter" },
            contentType: { stringValue: "image/png" },
            path: { stringValue: `incidents/case1/reporter/${id}` },
            storageProvider: { stringValue: "supabase" },
          },
        });
      }
      throw new Error(`Unexpected endpoint ${url}`);
    }) as typeof fetch,
  });
  const request = (method = "POST", bytes = png, suffix = "") =>
    new Request(
      `${base}?incidentId=case1&name=foto.png${suffix}`,
      {
        method,
        headers: { origin, authorization: "Bearer firebase.token", "content-type": "image/png" },
        ...(method === "POST" ? { body: bytes } : {}),
      },
    );
  return { handler, request, uploads, removals, downloads, writes };
}

Deno.test("missing or invalid authentication never reaches storage", async () => {
  const f = fixture({ invalidToken: true });
  assert((await f.handler(new Request(`${base}?incidentId=case1`))).status === 401);
  assert((await f.handler(f.request())).status === 401);
  assert(f.uploads.length === 0 && f.downloads.length === 0);
});

Deno.test("foreign report and inactive profile cannot upload or download", async () => {
  for (const options of [{ denyIncident: true }, { inactive: true }]) {
    const f = fixture(options);
    assert((await f.handler(f.request())).status === 403);
    assert((await f.handler(f.request("GET", png, `&evidenceId=${id}`))).status === 403);
    assert(f.uploads.length === 0 && f.downloads.length === 0);
  }
});

Deno.test("invalid image contents and oversized bodies never create an object", async () => {
  const f = fixture();
  assert((await f.handler(f.request("POST", new TextEncoder().encode("<script>")))).status === 415);
  assert((await f.handler(f.request("POST", new Uint8Array(5 * 1024 * 1024 + 1)))).status === 413);
  assert(f.uploads.length === 0);
});

Deno.test("upload commits metadata with server timestamp after storing a private image", async () => {
  const f = fixture();
  const result = await f.handler(f.request());
  assert(result.status === 201);
  const body = await result.json();
  assert(f.uploads[0] === `incidents/case1/reporter/${body.evidenceId}`);
  const write = (f.writes[0] as {
    writes: {
      update: { fields: Record<string, unknown> };
      updateTransforms: { setToServerValue: string }[];
    }[];
  }).writes[0];
  assert(write.updateTransforms[0].setToServerValue === "REQUEST_TIME");
  assert(JSON.stringify(write.update.fields.storageProvider) === '{"stringValue":"supabase"}');
  assert(result.headers.get("access-control-allow-origin") === origin);
});

Deno.test("revoked access at metadata commit removes the incomplete upload", async () => {
  const f = fixture({ denyCommit: true });
  assert((await f.handler(f.request())).status === 403);
  assert(f.uploads.length === 1 && f.removals[0] === f.uploads[0]);
});

Deno.test("ambiguous commit failure keeps the object for reconciliation", async () => {
  const f = fixture({ unknownCommit: true });
  assert((await f.handler(f.request())).status === 503);
  assert(f.uploads.length === 1 && f.removals.length === 0);
});

Deno.test("authorized download returns private bytes and prevents path traversal", async () => {
  const f = fixture();
  const result = await f.handler(f.request("GET", png, `&evidenceId=${id}`));
  assert(result.status === 200 && result.headers.get("cache-control")?.includes("no-store"));
  assert(new Uint8Array(await result.arrayBuffer()).length === png.length);
  assert(f.downloads[0] === `incidents/case1/reporter/${id}`);
  const bad = await f.handler(f.request("GET", png, "&evidenceId=..%2Fother"));
  assert(bad.status === 400 && f.downloads.length === 1);
});

Deno.test("unexpected origins cannot use the function", async () => {
  const f = fixture();
  const req = f.request();
  req.headers.set("origin", "https://unrelated.example");
  assert((await f.handler(req)).status === 403 && f.uploads.length === 0);
});
