{{flutter_js}}
{{flutter_build_config}}

// Firebase needs a connection; legacy Flutter offline caches must not keep an
// older application running after a deployment. Auth persistence is untouched.
(() => {
  const buildVersion = '2026.10.21.3';
  const migrationParameter = '__campusfix_update';
  const appBase = new URL('.', document.baseURI);
  const workerUrl = new URL('flutter_service_worker.js', appBase);
  const cacheNames = ['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest'];
  const entrypoints = ['', 'index.html', 'main.dart.js', 'flutter.js', 'flutter_bootstrap.js', 'version.json'];

  const isOwnWorker = (worker) => {
    if (!worker?.scriptURL) return false;
    const url = new URL(worker.scriptURL);
    return url.origin === workerUrl.origin && url.pathname === workerUrl.pathname;
  };

  async function removeOwnFlutterCacheEntries() {
    if (!('caches' in window)) return;
    const existingNames = await caches.keys();
    const presentNames = cacheNames.filter((name) => existingNames.includes(name));
    let verifiedCampusFix = false;
    for (const name of presentNames.filter((name) => name !== 'flutter-app-manifest')) {
      const cache = await caches.open(name);
      for (const path of ['', 'index.html']) {
        const response = await cache.match(new URL(path, appBase).href);
        if (response && /<title>\s*CampusFix[\s·<]/i.test(await response.text())) {
          verifiedCampusFix = true;
        }
      }
    }
    // These historical names are shared by Flutter apps on the same origin.
    // Only touch entries after identifying this application's cached document.
    if (!verifiedCampusFix) return;
    const ownUrls = new Set(entrypoints.map((path) => new URL(path, appBase).href));
    if (presentNames.includes('flutter-app-manifest')) {
      const manifestCache = await caches.open('flutter-app-manifest');
      const manifestUrl = new URL('manifest', appBase).href;
      const response = await manifestCache.match(manifestUrl);
      if (response) {
        try {
          const manifest = await response.json();
          if (manifest['main.dart.js'] && (manifest['index.html'] || manifest['/'])) {
            for (const resource of Object.keys(manifest)) {
              const url = new URL(resource === '/' ? '' : resource, appBase);
              if (url.origin === appBase.origin && url.pathname.startsWith(appBase.pathname)) {
                ownUrls.add(url.href);
              }
            }
            ownUrls.add(manifestUrl);
          }
        } catch (_) {
          // Malformed legacy metadata is harmless once its worker is removed.
        }
      }
    }
    for (const name of presentNames) {
      const cache = await caches.open(name);
      for (const request of await cache.keys()) {
        const url = new URL(request.url);
        url.search = '';
        url.hash = '';
        if (ownUrls.has(url.href)) await cache.delete(request);
      }
      if ((await cache.keys()).length === 0) await caches.delete(name);
    }
  }

  async function startCampusFix() {
    document.documentElement.dataset.campusfixBuild = buildVersion;
    if ('serviceWorker' in navigator) {
      try {
        const registrations = await navigator.serviceWorker.getRegistrations();
        for (const registration of registrations) {
          if (registration.scope === appBase.href &&
              [registration.active, registration.waiting, registration.installing].some(isOwnWorker)) {
            await registration.unregister();
          }
        }
      } catch (error) {
        console.warn('CampusFix: no se pudo retirar el worker anterior.', error);
      }
    }
    try {
      await removeOwnFlutterCacheEntries();
    } catch (error) {
      console.warn('CampusFix: no se pudo limpiar la caché de la aplicación.', error);
    }

    // An unregistered worker can still control the current document until the
    // next navigation. Do not start Flutter through that outdated controller.
    const url = new URL(window.location.href);
    if ('serviceWorker' in navigator && isOwnWorker(navigator.serviceWorker.controller)) {
      if (url.searchParams.get(migrationParameter) === buildVersion) {
        const message = document.querySelector('#loading p');
        if (message) message.textContent = 'Actualización pendiente. Cierra esta pestaña y vuelve a abrir CampusFix.';
        return;
      }
      url.searchParams.set(migrationParameter, buildVersion);
      window.location.replace(url.href);
      return;
    }
    if (url.searchParams.has(migrationParameter)) {
      url.searchParams.delete(migrationParameter);
      window.history.replaceState(window.history.state, '', url.href);
    }
    for (const build of _flutter.buildConfig.builds) {
      if (build.mainJsPath) {
        const mainUrl = new URL(build.mainJsPath, appBase);
        mainUrl.searchParams.set('v', buildVersion);
        build.mainJsPath = mainUrl.href;
      }
    }
    // Deliberately omit serviceWorkerSettings: CampusFix is an online app.
    await _flutter.loader.load();
  }

  startCampusFix().catch((error) => {
    console.error('CampusFix: no se pudo iniciar la aplicación.', error);
    const message = document.querySelector('#loading p');
    if (message) message.textContent = 'No se pudo cargar CampusFix. Revisa tu conexión y recarga la página.';
  });
})();
