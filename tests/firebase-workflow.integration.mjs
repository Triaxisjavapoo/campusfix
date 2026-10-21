import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { deleteApp, initializeApp } from 'firebase/app';
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { collection, connectFirestoreEmulator, doc, getDoc, getDocs, getFirestore, onSnapshot, orderBy, query, runTransaction, serverTimestamp, setDoc, updateDoc, where, writeBatch } from 'firebase/firestore';
import { connectStorageEmulator, deleteObject, getBytes, getStorage, ref, uploadBytes } from 'firebase/storage';
import { assertFails, initializeTestEnvironment } from '@firebase/rules-unit-testing';

// Real email/password Auth sessions exercise the same maps, transactions,
// subscriptions and private Storage paths as FirebaseRepository in Flutter.
const projectId = 'demo-campusfix';
const bucket = `${projectId}.firebasestorage.app`;
const people = {};
const apps = [];
let fixture;
let incidentId;
const password = 'CampusFixIntegration2026!';
const categoryId = 'integration-electricidad';

before(async () => {
  fixture = await initializeTestEnvironment({
    projectId,
    firestore: { host: '127.0.0.1', port: 8080, rules: await readFile('firestore.rules', 'utf8') },
    storage: { host: '127.0.0.1', port: 9199, rules: await readFile('storage.rules', 'utf8') },
  });
  await fixture.clearFirestore();
  for (const [key, name] of Object.entries({ reporter: 'María Reportante', other: 'Otro Reportante', technician: 'Carlos Técnico', admin: 'Ana Administradora' })) {
    const app = initializeApp({ projectId, apiKey: 'demo-campusfix-api-key', appId: `1:123456789:web:${key}`, authDomain: `${projectId}.firebaseapp.com`, storageBucket: bucket }, `integration-${key}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    const db = getFirestore(app);
    connectFirestoreEmulator(db, '127.0.0.1', 8080);
    const storage = getStorage(app);
    connectStorageEmulator(storage, '127.0.0.1', 9199);
    const email = `${key}@campusfix-integration.local`;
    const credential = await createUserWithEmailAndPassword(auth, email, password);
    const uid = credential.user.uid;
    await setDoc(doc(db, 'users', uid), { name, email, role: 'reporter', active: true, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
    people[key] = { app, auth, db, storage, uid, name, email };
  }
  // The only privileged fixture action simulates the first-admin bootstrap and
  // administrator assigning a technician role. Every scenario below uses Auth.
  await fixture.withSecurityRulesDisabled(async (context) => {
    for (const key of ['admin', 'technician']) await updateDoc(doc(context.firestore(), 'users', people[key].uid), { role: key, updatedAt: serverTimestamp() });
  });
});
after(async () => {
  await Promise.all(apps.map(deleteApp));
  await fixture?.cleanup();
});

function event(actor, type, fromStatus, toStatus, version, message = 'Acción documentada mediante el cliente autenticado.') {
  return { actorId: actor.uid, actorName: actor.name, type, fromStatus, toStatus, message, version, createdAt: serverTimestamp() };
}
async function change(actor, patch, type = 'STATUS_CHANGED', expectedVersion = null) {
  const incident = doc(actor.db, 'incidents', incidentId);
  const audit = doc(collection(incident, 'events'));
  await runTransaction(actor.db, async (transaction) => {
    const snapshot = await transaction.get(incident);
    const current = snapshot.data();
    if (expectedVersion != null && current.version !== expectedVersion) throw new Error('STALE_VERSION');
    const version = current.version + 1;
    transaction.update(incident, { ...patch, version, lastEventId: audit.id, updatedAt: serverTimestamp() });
    transaction.set(audit, event(actor, type, current.status, patch.status || current.status, version));
  });
}
function nextSnapshot(db, selection, predicate) {
  let unsubscribe;
  let timer;
  const promise = new Promise((resolve, reject) => {
    timer = setTimeout(() => { unsubscribe?.(); reject(new Error('No llegó la actualización en tiempo real.')); }, 10000);
    unsubscribe = onSnapshot(selection(db), (snapshot) => {
      if (!predicate(snapshot)) return;
      clearTimeout(timer); unsubscribe?.(); resolve(snapshot);
    }, (error) => { clearTimeout(timer); unsubscribe?.(); reject(error); });
  });
  return promise;
}

test('ciclo completo con Auth real, transacciones, tiempo real y evidencia privada', { timeout: 120000 }, async (t) => {
  const { reporter, other, technician, admin } = people;
  await t.test('correo/contraseña y catálogo administrativo', async () => {
    await signOut(reporter.auth);
    await signInWithEmailAndPassword(reporter.auth, reporter.email, password);
    await assert.rejects(signInWithEmailAndPassword(other.auth, other.email, 'clave-incorrecta'), (error) => ['auth/wrong-password', 'auth/invalid-credential'].includes(error.code));
    await setDoc(doc(admin.db, 'categories', categoryId), { name: 'Electricidad', description: 'Fallas de iluminación del campus.', active: true, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
    await assertFails(setDoc(doc(reporter.db, 'categories', 'forged'), { name: 'Falsa', description: '', active: true, createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  });
  await t.test('crear usa exactamente los campos del repositorio Dart y su auditoría', async () => {
    const incident = doc(collection(reporter.db, 'incidents'));
    const audit = doc(collection(incident, 'events'));
    incidentId = incident.id;
    await runTransaction(reporter.db, async (transaction) => {
      const category = await transaction.get(doc(reporter.db, 'categories', categoryId));
      transaction.set(incident, {
        number: `CF-${new Date().getFullYear()}-${incident.id.slice(0, 8).toUpperCase()}`,
        title: 'Lámpara apagada en el aula 202', description: 'La lámpara del fondo no enciende y dificulta seguir las clases.',
        categoryId, categoryName: category.data().name, location: 'Edificio A, aula 202', priority: 'MEDIA', status: 'REPORTADA',
        reporterId: reporter.uid, reporterName: reporter.name, assignedTo: null, assignedName: null,
        createdAt: serverTimestamp(), updatedAt: serverTimestamp(), resolvedAt: null, closedAt: null, version: 1, lastEventId: audit.id,
      });
      transaction.set(audit, event(reporter, 'CREATED', null, 'REPORTADA', 1, 'Incidencia registrada.'));
    });
    const mine = await getDocs(query(collection(reporter.db, 'incidents'), where('reporterId', '==', reporter.uid), orderBy('createdAt', 'desc')));
    assert.equal(mine.size, 1);
    await assertFails(getDoc(doc(other.db, 'incidents', incidentId)));
    await assertFails(getDoc(doc(technician.db, 'incidents', incidentId)));
  });
  await t.test('clasificar, revisar y asignar; suscripción del técnico recibe el caso', async () => {
    await change(admin, { categoryId, categoryName: 'Electricidad', priority: 'ALTA' }, 'CLASSIFIED', 1);
    await change(admin, { status: 'EN_REVISION' }, 'STATUS_CHANGED', 2);
    const live = nextSnapshot(technician.db, (db) => query(collection(db, 'incidents'), where('assignedTo', '==', technician.uid), orderBy('createdAt', 'desc')), (snapshot) => snapshot.docs.some((item) => item.id === incidentId));
    await change(admin, { assignedTo: technician.uid, assignedName: technician.name, status: 'ASIGNADA' }, 'ASSIGNED', 3);
    assert.equal((await live).size, 1);
    await assert.rejects(change(admin, { priority: 'BAJA' }, 'CLASSIFIED', 3), /STALE_VERSION/);
  });
  await t.test('solo técnico asignado atiende y resuelve; comentarios autenticados', async () => {
    await assertFails(change(admin, { status: 'EN_ATENCION' }));
    await change(technician, { status: 'EN_ATENCION' }, 'STATUS_CHANGED', 4);
    await setDoc(doc(collection(technician.db, 'incidents', incidentId, 'comments')), { authorId: technician.uid, authorName: technician.name, text: 'Se cambió la lámpara y se revisó el circuito.', createdAt: serverTimestamp() });
    await change(technician, { status: 'RESUELTA', resolvedAt: serverTimestamp() }, 'STATUS_CHANGED', 5);
    const comments = await getDocs(query(collection(reporter.db, 'incidents', incidentId, 'comments'), orderBy('createdAt')));
    assert.equal(comments.size, 1);
    await assertFails(getDocs(collection(other.db, 'incidents', incidentId, 'comments')));
  });
  await t.test('PNG real conserva bytes y solo participantes lo descargan', async () => {
    const bytes = Uint8Array.from(Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6vRoAAAAASUVORK5CYII=', 'base64'));
    const id = 'integration-image';
    const path = `incidents/${incidentId}/${technician.uid}/${id}`;
    await uploadBytes(ref(technician.storage, path), bytes, { contentType: 'image/png' });
    await setDoc(doc(technician.db, 'incidents', incidentId, 'evidence', id), { uploaderId: technician.uid, uploaderName: technician.name, name: 'lampara-reparada.png', path, contentType: 'image/png', size: bytes.length, createdAt: serverTimestamp() });
    assert.deepEqual(new Uint8Array(await getBytes(ref(reporter.storage, path))), bytes);
    await assertFails(getBytes(ref(other.storage, path)));
    await assertFails(uploadBytes(ref(technician.storage, path), bytes, { contentType: 'image/png' }));
    await assertFails(deleteObject(ref(technician.storage, path)));
  });
  await t.test('solo admin cierra, reportante reabre y se pierde asignación', async () => {
    await assertFails(change(reporter, { status: 'CERRADA', closedAt: serverTimestamp() }));
    await change(admin, { status: 'CERRADA', closedAt: serverTimestamp() }, 'STATUS_CHANGED', 6);
    await change(reporter, { status: 'REABIERTA', assignedTo: null, assignedName: null, resolvedAt: null, closedAt: null }, 'STATUS_CHANGED', 7);
    const reopened = (await getDoc(doc(reporter.db, 'incidents', incidentId))).data();
    assert.equal(reopened.status, 'REABIERTA');
    assert.equal(reopened.version, 8);
    assert.equal(reopened.assignedTo, null);
    assert.equal(reopened.resolvedAt, null);
    await assertFails(getDoc(doc(technician.db, 'incidents', incidentId)));
    const history = await getDocs(query(collection(reporter.db, 'incidents', incidentId, 'events'), orderBy('version', 'desc')));
    assert.deepEqual(history.docs.map((item) => item.data().version), [8, 7, 6, 5, 4, 3, 2, 1]);
  });
  await t.test('revocación de rol usa Firestore sin refrescar token Auth', async () => {
    await updateDoc(doc(admin.db, 'users', reporter.uid), { role: 'technician', updatedAt: serverTimestamp() });
    await assertFails(getDoc(doc(reporter.db, 'incidents', incidentId)));
    await updateDoc(doc(admin.db, 'users', other.uid), { active: false, updatedAt: serverTimestamp() });
    await assertFails(getDocs(collection(other.db, 'categories')));
    await assertFails(updateDoc(doc(other.db, 'users', other.uid), { active: true, updatedAt: serverTimestamp() }));
  });
});
