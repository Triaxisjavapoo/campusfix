import { createEvidenceHandler } from "./handler.ts";

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function fixture(role = "admin", options: { storageFailure?: boolean; denyLock?: boolean } = {}) {
  const root = "projects/campusfix-ae32e/databases/(default)/documents";
  const report = `${root}/incidents/case1`;
  let exists = true;
  let locked = false;
  let rejectStorage = !!options.storageFailure;
  let storageCalls = 0;
  let commits = 0;
  const objects = new Set(
    Array.from({ length: 105 }, (_, i) => `incidents/case1/uploader/file${i}`),
  );
  const collections: Record<string, Set<string>> = {
    evidence: new Set([`${report}/evidence/image1`]),
    comments: new Set([`${report}/comments/comentario-con-ñ`]),
    events: new Set(Array.from({ length: 105 }, (_, i) => `${report}/events/event${i}`)),
  };
  const handler = createEvidenceHandler({
    projectId: "campusfix-ae32e",
    allowedOrigins: ["https://campusfix-ae32e.web.app"],
    verifyToken: async () => "actor",
    storage: {
      async list(prefix) {
        storageCalls++;
        if (rejectStorage) {
          rejectStorage = false;
          return { data: null, error: { message: "outage" } };
        }
        const children = new Map<string, { name: string; id: string | null }>();
        for (const path of objects) {
          if (!path.startsWith(prefix + "/")) continue;
          const rest = path.slice(prefix.length + 1);
          const name = rest.split("/")[0];
          children.set(name, { name, id: rest.includes("/") ? null : name });
        }
        return { data: [...children.values()].slice(0, 100), error: null };
      },
      async remove(paths) {
        assert(locked && exists, "objects removed before report lock");
        for (const path of paths) {
          assert(objects.has(path));
          objects.delete(path);
        }
        return { error: null };
      },
      async upload() {
        throw new Error("unexpected upload");
      },
      async download() {
        throw new Error("unexpected download");
      },
    },
    fetcher: (async (input: string | URL | Request, init?: RequestInit) => {
      assert(new Headers(init?.headers).get("authorization") === "Bearer firebase.token");
      const url = new URL(String(input));
      if (url.pathname.endsWith("/users/actor")) {
        return Response.json({
          fields: {
            active: { booleanValue: role !== "inactive" },
            role: { stringValue: role },
          },
        });
      }
      if (url.pathname.endsWith("/incidents/case1")) {
        if (!exists) return Response.json({}, { status: 404 });
        return Response.json({
          fields: {
            version: { integerValue: "4" },
            deleting: { booleanValue: locked },
          },
          updateTime: "2026-10-21T12:00:00Z",
        });
      }
      if (url.pathname.endsWith(":commit")) {
        const body = JSON.parse(String(init?.body));
        commits++;
        for (const write of body.writes) {
          if (write.update) {
            if (options.denyLock) return Response.json({}, { status: 412 });
            assert(write.currentDocument.updateTime === "2026-10-21T12:00:00Z");
            assert(write.update.fields.deleting.booleanValue === true);
            locked = true;
          } else if (write.delete === report) {
            assert(locked && objects.size === 0, "parent removed before objects");
            assert(
              Object.values(collections).every((rows) => rows.size === 0),
              "parent removed before children",
            );
            exists = false;
          } else {
            assert(locked && objects.size === 0, "children removed before photos");
            const rows = Object.values(collections).find((rows) => rows.has(write.delete));
            assert(rows, "out-of-scope document deletion");
            rows.delete(write.delete);
          }
        }
        return Response.json({});
      }
      const collection = url.pathname.split("/").pop()!;
      if (collections[collection]) {
        assert(locked && url.searchParams.get("pageSize") === "100");
        return Response.json({
          documents: [...collections[collection]].slice(0, 100).map((name) => ({ name })),
        });
      }
      throw new Error("Unexpected Firestore operation");
    }) as typeof fetch,
  });
  const request = (version = "4") =>
    new Request(
      `https://example.supabase.co/functions/v1/incident-evidence?incidentId=case1&version=${version}`,
      {
        method: "DELETE",
        headers: {
          authorization: "Bearer firebase.token",
          origin: "https://campusfix-ae32e.web.app",
        },
      },
    );
  return {
    handler,
    request,
    objects,
    collections,
    get state() {
      return { exists, locked, storageCalls, commits };
    },
  };
}

Deno.test("reporter, technician and inactive users cannot start deletion", async () => {
  for (const role of ["reporter", "technician", "inactive"]) {
    const f = fixture(role);
    assert((await f.handler(f.request())).status === 403);
    assert(!f.state.locked && f.state.storageCalls === 0 && f.state.commits === 0);
  }
});

Deno.test("stale confirmation and concurrent write conflict delete nothing", async () => {
  const stale = fixture();
  assert((await stale.handler(stale.request("3"))).status === 409);
  assert(!stale.state.locked && stale.state.storageCalls === 0);
  const changed = fixture("admin", { denyLock: true });
  assert((await changed.handler(changed.request())).status === 409);
  assert(!changed.state.locked && changed.state.storageCalls === 0);
});

Deno.test("administrator deletes all pages of photos and children before parent", async () => {
  const f = fixture();
  const result = await f.handler(f.request());
  assert(result.status === 200 && (await result.json()).deleted === true);
  assert(!f.state.exists && f.objects.size === 0);
  assert(Object.values(f.collections).every((rows) => rows.size === 0));
});

Deno.test("storage failure preserves locked report and can be resumed", async () => {
  const f = fixture("admin", { storageFailure: true });
  assert((await f.handler(f.request())).status === 503);
  assert(f.state.exists && f.state.locked && Number(f.objects.size) === 105);
  assert(f.collections.comments.size === 1);
  assert((await f.handler(f.request("999"))).status === 200);
  assert(!f.state.exists && f.objects.size === 0);
});

Deno.test("repeating a completed deletion is idempotent", async () => {
  const f = fixture();
  assert((await f.handler(f.request())).status === 200);
  const commits = f.state.commits;
  assert((await f.handler(f.request())).status === 200);
  assert(f.state.commits === commits);
});
