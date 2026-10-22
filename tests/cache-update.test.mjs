import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';

const template = await fs.readFile(new URL('../web/flutter_bootstrap.js', import.meta.url), 'utf8');
const script = template.replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');
const origin = 'https://campusfix-ae32e.web.app/';
const worker = { scriptURL: `${origin}flutter_service_worker.js?v=old` };

function fakeCache(entries = {}) {
  const data = new Map(Object.entries(entries));
  return {
    data,
    async match(url) {
      const body = data.get(url);
      return body === undefined ? undefined : {
        async text() { return body; },
        async json() { return JSON.parse(body); },
      };
    },
    async keys() { return [...data.keys()].map((url) => ({ url })); },
    async delete(request) { return data.delete(request.url); },
  };
}

async function runBootstrap({ url = origin, registrations = [], controller = null, caches = new Map() } = {}) {
  const loads = [];
  const navigations = [];
  const historyChanges = [];
  const warnings = [];
  const message = { textContent: '' };
  const context = {
    URL,
    console: { warn: (...args) => warnings.push(args), error: (...args) => warnings.push(args) },
    document: {
      baseURI: origin,
      documentElement: { dataset: {} },
      querySelector() { return message; },
    },
    navigator: { serviceWorker: { async getRegistrations() { return registrations; }, controller } },
    caches: {
      async keys() { return [...caches.keys()]; },
      async open(name) { assert.ok(caches.has(name), 'must not create caches'); return caches.get(name); },
      async delete(name) { return caches.delete(name); },
    },
    _flutter: {
      buildConfig: {
        builds: [
          { compileTarget: 'dart2js', mainJsPath: 'main.dart.js' },
          { compileTarget: 'dart2wasm', mainWasmPath: 'main.dart.wasm', jsSupportRuntimePath: 'main.dart.mjs' },
        ],
      },
      loader: { async load(...args) { loads.push(args); } },
    },
  };
  context.window = {
    caches: context.caches,
    location: { href: url, replace: (destination) => navigations.push(destination) },
    history: { state: {}, replaceState: (...args) => historyChanges.push(args) },
  };
  vm.runInNewContext(script, context);
  await new Promise(setImmediate);
  return { context, loads, navigations, historyChanges, warnings, message };
}

test('loads the versioned entrypoint without registering a worker and preserves WASM build metadata', async () => {
  const result = await runBootstrap();
  assert.equal(result.loads.length, 1);
  assert.equal(result.loads[0].length, 0);
  assert.equal(result.context.document.documentElement.dataset.campusfixBuild, '2026.10.21.4');
  assert.equal(result.context._flutter.buildConfig.builds[0].mainJsPath, `${origin}main.dart.js?v=2026.10.21.4`);
  assert.equal(result.context._flutter.buildConfig.builds[1].mainWasmPath, 'main.dart.wasm');
  assert.equal(result.context._flutter.buildConfig.builds[1].jsSupportRuntimePath, 'main.dart.mjs');
  assert.equal(result.warnings.length, 0);
});

test('unregisters only the Flutter worker belonging to this app and navigates before loading through it', async () => {
  let ownRemoved = 0;
  let otherRemoved = 0;
  const result = await runBootstrap({
    url: `${origin}?filter=mine#reports`, controller: worker,
    registrations: [
      { scope: origin, active: worker, async unregister() { ownRemoved++; } },
      { scope: `${origin}other/`, active: { scriptURL: `${origin}other/flutter_service_worker.js` }, async unregister() { otherRemoved++; } },
      { scope: origin, active: { scriptURL: `${origin}firebase-messaging-sw.js` }, async unregister() { otherRemoved++; } },
    ],
  });
  assert.equal(ownRemoved, 1);
  assert.equal(otherRemoved, 0);
  assert.equal(result.loads.length, 0);
  assert.equal(result.navigations[0], `${origin}?filter=mine&__campusfix_update=2026.10.21.4#reports`);
});

test('avoids a reload loop if a browser retains the old controller', async () => {
  const result = await runBootstrap({ url: `${origin}?__campusfix_update=2026.10.21.4`, controller: worker });
  assert.equal(result.navigations.length, 0);
  assert.equal(result.loads.length, 0);
  assert.match(result.message.textContent, /Cierra esta pestaña/);
});

test('removes the migration query after regaining an uncontrolled document, preserving user URL state', async () => {
  const result = await runBootstrap({ url: `${origin}?filter=mine&__campusfix_update=2026.10.21.4#reports` });
  assert.equal(result.loads.length, 1);
  assert.equal(result.historyChanges[0][2], `${origin}?filter=mine#reports`);
});

test('cleans verified CampusFix resources and leaves other applications and storage untouched', async () => {
  const appCache = fakeCache({
    [origin]: '<!doctype html><title>CampusFix · Gestión del campus</title>',
    [`${origin}main.dart.js`]: 'old code',
    [`${origin}assets/AssetManifest.bin`]: 'old assets',
    [`${origin}other-app/main.dart.js`]: 'other app code',
  });
  const manifestCache = fakeCache({ [`${origin}manifest`]: JSON.stringify({
    '/': 'hash', 'index.html': 'hash', 'main.dart.js': 'hash', 'assets/AssetManifest.bin': 'hash',
  }) });
  const unrelatedCache = fakeCache({ [`${origin}something`]: 'keep' });
  const caches = new Map([
    ['flutter-app-cache', appCache], ['flutter-app-manifest', manifestCache], ['other-app-cache', unrelatedCache],
  ]);
  const result = await runBootstrap({ caches });
  assert.equal(result.loads.length, 1);
  assert.deepEqual([...appCache.data.keys()], [`${origin}other-app/main.dart.js`]);
  assert.equal(caches.has('flutter-app-manifest'), false);
  assert.equal(caches.get('other-app-cache'), unrelatedCache);
  // The VM exposes no localStorage, IndexedDB or Firebase Auth APIs. Startup
  // succeeding also verifies that this migration never needs to touch them.
  assert.equal(result.warnings.length, 0);
});

test('does not delete unidentified Flutter caches from another application', async () => {
  const appCache = fakeCache({ [origin]: '<title>Another app</title>', [`${origin}main.dart.js`]: 'keep' });
  const caches = new Map([['flutter-app-cache', appCache]]);
  const result = await runBootstrap({ caches });
  assert.equal(result.loads.length, 1);
  assert.equal(appCache.data.size, 2);
});

test('web source and both hosting configurations agree on release and no-store entrypoints', async () => {
  const html = await fs.readFile(new URL('../web/index.html', import.meta.url), 'utf8');
  assert.match(html, /flutter_bootstrap\.js\?v=2026\.10\.21\.4/);
  assert.match(html, /name="campusfix-build" content="2026\.10\.21\.4"/);
  for (const filename of ['firebase.json', 'firebase.demo.json']) {
    const config = JSON.parse(await fs.readFile(new URL(`../${filename}`, import.meta.url), 'utf8'));
    for (const source of ['/', '/index.html', '**/*.js', '/version.json']) {
      const header = config.hosting.headers.find((entry) => entry.source === source)
        ?.headers.find((entry) => entry.key === 'Cache-Control');
      assert.match(header?.value ?? '', /no-store/);
    }
  }
});
