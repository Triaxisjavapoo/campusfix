import { access, mkdir, readdir } from 'node:fs/promises';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
const mode = process.argv[2];
if (!['start', 'test', 'integration', 'demo'].includes(mode)) throw new Error('Uso: node scripts/run-firebase-local.mjs start|test|integration|demo');
const cache = path.join(root, '.firebase', 'local-tooling');
await mkdir(cache, { recursive: true });
// Prefer an actual JDK on Windows; some Oracle javapath launchers stall in a sandbox.
let javaHome = process.env.JAVA_HOME;
if (!javaHome && process.platform === 'win32') {
  const javaDirectory = path.join(process.env.ProgramFiles || 'C:\\Program Files', 'Java');
  const candidates = (await readdir(javaDirectory).catch(() => [])).filter((name) => name.startsWith('jdk')).sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
  for (const name of candidates) {
    const candidate = path.join(javaDirectory, name);
    try { await access(path.join(candidate, 'bin', 'java.exe')); javaHome = candidate; break; }
    catch { /* Fall through to the next installed JDK. */ }
  }
}
const localEnv = { ...process.env, CI: 'true', XDG_CONFIG_HOME: path.join(cache, 'config'), FIREBASE_EMULATORS_PATH: path.join(cache, 'emulators') };
if (javaHome) {
  const pathKeys = Object.keys(localEnv).filter((key) => key.toLowerCase() === 'path');
  const originalPath = pathKeys.map((key) => localEnv[key]).filter(Boolean).join(path.delimiter);
  for (const key of pathKeys) delete localEnv[key];
  localEnv.JAVA_HOME = javaHome;
  localEnv.PATH = `${path.join(javaHome, 'bin')}${path.delimiter}${originalPath}`;
  console.log(`JDK: ${javaHome}`);
}
const args = mode === 'test'
  ? ['emulators:exec', '--project', 'demo-campusfix', '--only', 'firestore,storage', 'node --test --test-concurrency=1 tests/firebase-rules.test.mjs']
  : mode === 'integration'
    ? ['emulators:exec', '--project', 'demo-campusfix', '--only', 'auth,firestore,storage', 'node --test tests/firebase-workflow.integration.mjs']
    : mode === 'demo'
      ? ['--config', 'firebase.demo.json', 'emulators:exec', '--project', 'demo-campusfix', '--only', 'auth,firestore,storage,hosting', 'node scripts/seed-emulators.mjs && node scripts/keep-demo-running.mjs']
      : ['emulators:start', '--project', 'demo-campusfix'];
// Run the CLI in this process so Ctrl+C reaches the emulator lifecycle handler.
for (const key of Object.keys(process.env).filter((key) => key.toLowerCase() === 'path')) delete process.env[key];
Object.assign(process.env, localEnv);
process.chdir(root);
const cli = path.join(root, 'node_modules', 'firebase-tools', 'lib', 'bin', 'firebase.js');
process.argv = [process.execPath, cli, ...args];
await import(pathToFileURL(cli).href);
