import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, Timestamp, updateDoc, where, writeBatch } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

const projectId = 'demo-campusfix';
let env;
const now = Timestamp.fromDate(new Date('2026-10-21T12:00:00Z'));
const names = { reporter: 'María Estudiante', other: 'Otro Estudiante', technician: 'Carlos Técnico', technician2: 'Otra Técnica', admin: 'Ana Administradora', inactive: 'Cuenta Inactiva' };
const userData = (uid, role = 'reporter', active = true) => ({ name: names[uid] || 'Nuevo Usuario', email: `${uid}@example.test`, role, active, createdAt: now, updatedAt: now });
const incidentData = (patch = {}) => ({
  number: 'CF-2026-ABCDEFGH', title: 'Lámpara dañada en aula', description: 'La lámpara del aula no enciende desde ayer.',
  categoryId: 'electricidad', categoryName: 'Electricidad', location: 'Edificio A, aula 202',
  priority: 'MEDIA', status: 'REPORTADA', reporterId: 'reporter', reporterName: names.reporter,
  assignedTo: null, assignedName: null, createdAt: now, updatedAt: now, resolvedAt: null, closedAt: null,
  version: 1, lastEventId: 'initial-event', ...patch,
});
const dbFor = (uid) => env.authenticatedContext(uid, { email: `${uid}@example.test` }).firestore();
const storageFor = (uid) => env.authenticatedContext(uid, { email: `${uid}@example.test` }).storage();
async function seedIncident(id = 'incident-1', patch = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'incidents', id), incidentData(patch));
    await setDoc(doc(context.firestore(), 'incidents', id, 'events', 'initial-event'), {
      actorId: 'reporter', actorName: names.reporter, type: 'CREATED', fromStatus: null, toStatus: 'REPORTADA', message: 'Incidencia registrada.', version: 1, createdAt: now,
    });
  });
}
function mutate(uid, patch, { kind = 'STATUS_CHANGED', id = 'incident-1', from = 'REPORTADA', version = 2, eventId = `event-${Date.now()}-${Math.random()}`, actorId = uid, actorName = names[uid], message = 'Acción realizada para atender la incidencia.', auditPatch = {} } = {}) {
  const db = dbFor(uid);
  const batch = writeBatch(db);
  batch.update(doc(db, 'incidents', id), { ...patch, version, lastEventId: eventId, updatedAt: serverTimestamp() });
  batch.set(doc(db, 'incidents', id, 'events', eventId), {
    actorId, actorName, type: kind, fromStatus: from, toStatus: patch.status || from,
    message, createdAt: serverTimestamp(), version, ...auditPatch,
  });
  return batch.commit();
}
async function createIncident(uid = 'reporter', patch = {}, eventPatch = {}) {
  const db = dbFor(uid);
  const batch = writeBatch(db);
  batch.set(doc(db, 'incidents', 'new-incident'), incidentData({
    reporterId: uid, reporterName: names[uid], createdAt: serverTimestamp(), updatedAt: serverTimestamp(), lastEventId: 'create-event', ...patch,
  }));
  batch.set(doc(db, 'incidents', 'new-incident', 'events', 'create-event'), {
    actorId: uid, actorName: names[uid], type: 'CREATED', fromStatus: null, toStatus: 'REPORTADA',
    message: 'Incidencia registrada.', createdAt: serverTimestamp(), version: 1, ...eventPatch,
  });
  return batch.commit();
}
before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { host: '127.0.0.1', port: 8080, rules: await readFile('firestore.rules', 'utf8') },
    storage: { host: '127.0.0.1', port: 9199, rules: await readFile('storage.rules', 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all(Object.keys(names).map((uid) => setDoc(doc(db, 'users', uid), userData(uid, uid.startsWith('technician') ? 'technician' : uid === 'admin' ? 'admin' : 'reporter', uid !== 'inactive'))));
    await setDoc(doc(db, 'categories', 'electricidad'), { name: 'Electricidad', description: 'Instalaciones eléctricas.', active: true, createdAt: now, updatedAt: now });
    await setDoc(doc(db, 'categories', 'inactive'), { name: 'Inactiva', description: '', active: false, createdAt: now, updatedAt: now });
  });
});
test('registro permite exclusivamente rol reporter y correo de Auth', async () => {
  const db = dbFor('new-user');
  await assertFails(setDoc(doc(db, 'users', 'new-user'), { ...userData('new-user', 'admin'), createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'users', 'new-user'), { ...userData('new-user'), email: 'suplantado@example.test', createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(db, 'users', 'new-user'), { ...userData('new-user'), createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
});
test('perfil propio admite nombre pero rechaza autoescalamiento y autodesactivar admin', async () => {
  await assertSucceeds(updateDoc(doc(dbFor('reporter'), 'users', 'reporter'), { name: 'Nombre actualizado', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(dbFor('reporter'), 'users', 'reporter'), { role: 'admin', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(dbFor('admin'), 'users', 'admin'), { active: false, updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(dbFor('admin'), 'users', 'other'), { role: 'technician', updatedAt: serverTimestamp() }));
});
test('usuarios no pueden enumerar perfiles; admin sí', async () => {
  await assertFails(getDocs(collection(dbFor('reporter'), 'users')));
  await assertFails(getDoc(doc(dbFor('other'), 'users', 'reporter')));
  await assertSucceeds(getDocs(collection(dbFor('admin'), 'users')));
  await assertSucceeds(getDoc(doc(dbFor('inactive'), 'users', 'inactive')));
});
test('catálogo solo cambia por admin y no permite borrar historia', async () => {
  await assertSucceeds(getDocs(collection(dbFor('reporter'), 'categories')));
  await assertFails(updateDoc(doc(dbFor('reporter'), 'categories', 'electricidad'), { active: false, updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(dbFor('admin'), 'categories', 'electricidad'), { active: false, updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(dbFor('admin'), 'categories', 'electricidad')));
});
test('crear incidencia y auditoría atómicamente funciona', async () => {
  await assertSucceeds(createIncident());
  assert.equal((await getDoc(doc(dbFor('reporter'), 'incidents', 'new-incident'))).data().version, 1);
});
test('crear sin auditoría, con identidad falsa, categoría inactiva o campos arbitrarios falla', async () => {
  await assertFails(setDoc(doc(dbFor('reporter'), 'incidents', 'bare'), incidentData({ createdAt: serverTimestamp(), updatedAt: serverTimestamp() })));
  await assertFails(createIncident('reporter', { reporterId: 'other' }));
  await assertFails(createIncident('reporter', { categoryId: 'inactive', categoryName: 'Inactiva' }));
  await assertFails(createIncident('reporter', { categoryName: 'Falsa' }));
  await assertFails(createIncident('reporter', { extra: true }));
  await assertFails(createIncident('reporter', {}, { actorId: 'admin', actorName: names.admin }));
});
test('lecturas aisladas por propietario y técnico asignado; consultas requieren filtro', async () => {
  await seedIncident();
  await assertSucceeds(getDoc(doc(dbFor('reporter'), 'incidents', 'incident-1')));
  await assertFails(getDoc(doc(dbFor('other'), 'incidents', 'incident-1')));
  await assertFails(getDoc(doc(dbFor('technician'), 'incidents', 'incident-1')));
  await assertFails(getDocs(collection(dbFor('reporter'), 'incidents')));
  await assertSucceeds(getDocs(query(collection(dbFor('reporter'), 'incidents'), where('reporterId', '==', 'reporter'))));
  await assertSucceeds(getDocs(collection(dbFor('admin'), 'incidents')));
});
test('cuentas inactivas y usuarios sin login no acceden a datos', async () => {
  await seedIncident();
  await assertFails(getDoc(doc(dbFor('inactive'), 'incidents', 'incident-1')));
  await assertFails(createIncident('inactive'));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'categories')));
});
test('cambio de reportante a técnico revoca privilegios de propietario y creación', async () => {
  await seedIncident('incident-1', { status: 'CERRADA', resolvedAt: now, closedAt: now });
  await assertSucceeds(updateDoc(doc(dbFor('admin'), 'users', 'reporter'), { role: 'technician', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(dbFor('reporter'), 'incidents', 'incident-1')));
  await assertFails(uploadBytes(ref(storageFor('reporter'), 'incidents/incident-1/reporter/promoted'), new Uint8Array([1]), { contentType: 'image/png' }));
  await assertFails(mutate('reporter', { status: 'REABIERTA', assignedTo: null, assignedName: null, resolvedAt: null, closedAt: null }, { from: 'CERRADA' }));
  await assertFails(createIncident('technician'));
  await assertSucceeds(createIncident('admin'));
});
test('admin clasifica y revisa con auditoría; reporter no', async () => {
  await seedIncident();
  await assertFails(mutate('reporter', { priority: 'ALTA' }, { kind: 'CLASSIFIED' }));
  await assertSucceeds(mutate('admin', { priority: 'ALTA' }, { kind: 'CLASSIFIED' }));
  await assertSucceeds(mutate('admin', { status: 'EN_REVISION' }, { version: 3 }));
});
test('solo admin asigna a técnico activo y nombre válido', async () => {
  await seedIncident();
  const assignment = { status: 'ASIGNADA', assignedTo: 'technician', assignedName: names.technician };
  await assertFails(mutate('reporter', assignment, { kind: 'ASSIGNED' }));
  await assertFails(mutate('admin', { ...assignment, assignedTo: 'other', assignedName: names.other }, { kind: 'ASSIGNED' }));
  await assertFails(mutate('admin', { ...assignment, assignedName: 'Nombre falsificado' }, { kind: 'ASSIGNED' }));
  await assertSucceeds(mutate('admin', assignment, { kind: 'ASSIGNED' }));
  await assertSucceeds(getDoc(doc(dbFor('technician'), 'incidents', 'incident-1')));
});
test('actualizar sin evento, evento falso, versión repetida y editar datos base falla', async () => {
  await seedIncident();
  await assertFails(updateDoc(doc(dbFor('admin'), 'incidents', 'incident-1'), { status: 'EN_REVISION', updatedAt: serverTimestamp(), version: 2, lastEventId: 'missing' }));
  await assertFails(mutate('admin', { status: 'EN_REVISION' }, { actorId: 'reporter', actorName: names.reporter }));
  await assertFails(mutate('admin', { status: 'EN_REVISION' }, { version: 1 }));
  await assertFails(mutate('admin', { status: 'EN_REVISION', reporterId: 'other' }));
  await assertFails(mutate('admin', { status: 'EN_REVISION' }, { auditPatch: { fromStatus: 'CERRADA' } }));
});
test('solo técnico asignado inicia y resuelve; no se omiten estados', async () => {
  await seedIncident('incident-1', { status: 'ASIGNADA', assignedTo: 'technician', assignedName: names.technician });
  await assertFails(mutate('admin', { status: 'EN_ATENCION' }, { from: 'ASIGNADA' }));
  await assertFails(mutate('technician2', { status: 'EN_ATENCION' }, { from: 'ASIGNADA' }));
  await assertFails(mutate('technician', { status: 'RESUELTA', resolvedAt: serverTimestamp() }, { from: 'ASIGNADA' }));
  await assertSucceeds(mutate('technician', { status: 'EN_ATENCION' }, { from: 'ASIGNADA' }));
  await assertFails(mutate('admin', { status: 'RESUELTA', resolvedAt: serverTimestamp() }, { from: 'EN_ATENCION', version: 3 }));
  await assertFails(mutate('technician', { status: 'RESUELTA' }, { from: 'EN_ATENCION', version: 3 }));
  await assertSucceeds(mutate('technician', { status: 'RESUELTA', resolvedAt: serverTimestamp() }, { from: 'EN_ATENCION', version: 3 }));
});
test('solo admin cierra y cierre registra timestamp de servidor', async () => {
  await seedIncident('incident-1', { status: 'RESUELTA', assignedTo: 'technician', assignedName: names.technician, resolvedAt: now });
  await assertFails(mutate('reporter', { status: 'CERRADA', closedAt: serverTimestamp() }, { from: 'RESUELTA' }));
  await assertFails(mutate('technician', { status: 'CERRADA', closedAt: serverTimestamp() }, { from: 'RESUELTA' }));
  await assertFails(mutate('admin', { status: 'CERRADA' }, { from: 'RESUELTA' }));
  await assertSucceeds(mutate('admin', { status: 'CERRADA', closedAt: serverTimestamp() }, { from: 'RESUELTA' }));
});
test('propietario reabre limpiando asignación y fechas, y cancela antes de asignación', async () => {
  await seedIncident('incident-1', { status: 'CERRADA', assignedTo: 'technician', assignedName: names.technician, resolvedAt: now, closedAt: now });
  await assertFails(mutate('reporter', { status: 'REABIERTA' }, { from: 'CERRADA' }));
  await assertSucceeds(mutate('reporter', { status: 'REABIERTA', assignedTo: null, assignedName: null, resolvedAt: null, closedAt: null }, { from: 'CERRADA' }));
  await seedIncident('cancelable');
  await assertSucceeds(mutate('reporter', { status: 'CANCELADA' }, { id: 'cancelable' }));
});
test('auditoría no admite inserciones aisladas, ediciones ni eliminación de incidencias', async () => {
  await seedIncident();
  const db = dbFor('admin');
  await assertFails(setDoc(doc(db, 'incidents', 'incident-1', 'events', 'fake'), { actorId: 'admin', actorName: names.admin, type: 'STATUS_CHANGED', fromStatus: 'REPORTADA', toStatus: 'REPORTADA', message: 'Evento falso.', createdAt: serverTimestamp(), version: 1 }));
  await assertFails(updateDoc(doc(db, 'incidents', 'incident-1', 'events', 'initial-event'), { message: 'Historia alterada' }));
  await assertFails(deleteDoc(doc(db, 'incidents', 'incident-1', 'events', 'initial-event')));
  await assertFails(deleteDoc(doc(db, 'incidents', 'incident-1')));
});
test('comentarios son inmutables, privados y verifican autor', async () => {
  await seedIncident();
  const data = { authorId: 'reporter', authorName: names.reporter, text: 'El problema continúa hoy.', createdAt: serverTimestamp() };
  await assertFails(setDoc(doc(dbFor('other'), 'incidents', 'incident-1', 'comments', 'x'), data));
  await assertFails(setDoc(doc(dbFor('reporter'), 'incidents', 'incident-1', 'comments', 'x'), { ...data, authorId: 'admin' }));
  const comment = doc(dbFor('reporter'), 'incidents', 'incident-1', 'comments', 'x');
  await assertSucceeds(setDoc(comment, data));
  await assertFails(updateDoc(comment, { text: 'Editado' }));
  await assertFails(deleteDoc(comment));
});
test('metadatos evidencia validan ruta, formato, tamaño y autor; no se borran', async () => {
  await seedIncident();
  const evidence = doc(dbFor('reporter'), 'incidents', 'incident-1', 'evidence', 'image');
  const data = { uploaderId: 'reporter', uploaderName: names.reporter, name: 'foto.png', path: 'incidents/incident-1/reporter/image', contentType: 'image/png', size: 200, createdAt: serverTimestamp() };
  await assertFails(setDoc(evidence, { ...data, path: 'incidents/incident-2/reporter/image' }));
  await assertFails(setDoc(evidence, { ...data, contentType: 'text/html' }));
  await assertFails(setDoc(evidence, { ...data, size: 5 * 1024 * 1024 + 1 }));
  await assertFails(setDoc(evidence, { ...data, storageProvider: 'public-url' }));
  const externalEvidence = doc(dbFor('reporter'), 'incidents', 'incident-1', 'evidence', 'supabase-image');
  await assertSucceeds(setDoc(externalEvidence, { ...data, path: 'incidents/incident-1/reporter/supabase-image', storageProvider: 'supabase' }));
  await assertFails(getDoc(doc(dbFor('other'), 'incidents', 'incident-1', 'evidence', 'supabase-image')));
  await assertSucceeds(setDoc(evidence, data));
  await assertFails(deleteDoc(evidence));
});
test('Storage exige participante, uploader propio, imagen <=5MiB y prohíbe sobrescribir', async () => {
  await seedIncident('storage-incident');
  const path = `incidents/storage-incident/reporter/${Date.now()}`;
  const image = new Uint8Array([137, 80, 78, 71]);
  await assertFails(uploadBytes(ref(storageFor('other'), path), image, { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(storageFor('reporter'), path.replace('/reporter/', '/other/')), image, { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(storageFor('reporter'), path), image, { contentType: 'text/html' }));
  await assertFails(uploadBytes(ref(storageFor('reporter'), path), new Uint8Array(5 * 1024 * 1024 + 1), { contentType: 'image/png' }));
  await assertSucceeds(uploadBytes(ref(storageFor('reporter'), path), image, { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(storageFor('reporter'), path), image, { contentType: 'image/png' }));
  await assertSucceeds(getBytes(ref(storageFor('reporter'), path)));
  await assertFails(getBytes(ref(storageFor('other'), path)));
  await assertFails(getBytes(ref(storageFor('inactive'), path)));
  await assertSucceeds(deleteObject(ref(storageFor('reporter'), path)));
});
test('Storage conserva imagen una vez registrados metadatos de evidencia', async () => {
  await seedIncident('storage-immutable');
  const id = `immutable-${Date.now()}`;
  const path = `incidents/storage-immutable/reporter/${id}`;
  await assertSucceeds(uploadBytes(ref(storageFor('reporter'), path), new Uint8Array([1]), { contentType: 'image/webp' }));
  await assertSucceeds(setDoc(doc(dbFor('reporter'), 'incidents', 'storage-immutable', 'evidence', id), { uploaderId: 'reporter', uploaderName: names.reporter, name: 'foto.webp', path, contentType: 'image/webp', size: 1, createdAt: serverTimestamp() }));
  await assertFails(deleteObject(ref(storageFor('reporter'), path)));
  await assertFails(deleteObject(ref(storageFor('admin'), path)));
});
