import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const projectId = 'demo-campusfix';
for (const [key, port] of Object.entries({
  FIREBASE_AUTH_EMULATOR_HOST: 9099, FIRESTORE_EMULATOR_HOST: 8080, FIREBASE_STORAGE_EMULATOR_HOST: 9199,
})) {
  process.env[key] ||= `127.0.0.1:${port}`;
  if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env[key])) {
    throw new Error(`${key} debe apuntar a localhost. El seed nunca escribe en producción.`);
  }
}
initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();
const now = Timestamp.now();
const password = 'CampusFix2026!';
const people = [
  { uid: 'demo-reporter', name: 'María Estudiante', email: 'reporter@campusfix.local', role: 'reporter' },
  { uid: 'demo-technician', name: 'Carlos Técnico', email: 'tecnico@campusfix.local', role: 'technician' },
  { uid: 'demo-admin', name: 'Ana Administradora', email: 'admin@campusfix.local', role: 'admin' },
];
for (const person of people) {
  const { uid, name, email } = person;
  try { await auth.getUser(uid); }
  catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    await auth.createUser({ uid, displayName: name, email, password, emailVerified: true });
  }
  await db.doc(`users/${uid}`).set({ name, email, role: person.role, active: true, createdAt: now, updatedAt: now });
}
const categories = [
  ['infraestructura', 'Infraestructura', 'Edificios, aulas, mobiliario y accesibilidad.'],
  ['electricidad', 'Electricidad', 'Iluminación, tomacorrientes y fallas eléctricas.'],
  ['tecnologia', 'Tecnología', 'Equipos informáticos, redes y audiovisuales.'],
  ['fontaneria', 'Fontanería', 'Agua potable, tuberías y servicios sanitarios.'],
  ['limpieza', 'Limpieza', 'Higiene, residuos y mantenimiento de áreas comunes.'],
];
for (const [id, name, description] of categories) {
  await db.doc(`categories/${id}`).set({ name, description, active: true, createdAt: now, updatedAt: now });
}
const samples = [
  { id: 'DEMO0001campusfix0001', title: 'Lámpara parpadea en aula 202', description: 'La lámpara ubicada sobre la segunda fila parpadea constantemente durante las clases.', categoryId: 'electricidad', categoryName: 'Electricidad', location: 'Edificio A, aula 202', priority: 'MEDIA', status: 'REPORTADA', assignedTo: null, assignedName: null },
  { id: 'DEMO0002campusfix0002', title: 'Proyector sin señal en biblioteca', description: 'El proyector de la sala colaborativa no reconoce ninguna conexión HDMI.', categoryId: 'tecnologia', categoryName: 'Tecnología', location: 'Biblioteca, sala colaborativa', priority: 'ALTA', status: 'ASIGNADA', assignedTo: 'demo-technician', assignedName: 'Carlos Técnico' },
  { id: 'DEMO0003campusfix0003', title: 'Fuga de agua junto al laboratorio', description: 'Se observa una fuga pequeña en el lavamanos junto a la entrada del laboratorio.', categoryId: 'fontaneria', categoryName: 'Fontanería', location: 'Laboratorio de ciencias, primer piso', priority: 'ALTA', status: 'RESUELTA', assignedTo: 'demo-technician', assignedName: 'Carlos Técnico' },
];
for (const sample of samples) {
  const { id, ...data } = sample;
  const ref = db.doc(`incidents/${id}`);
  if ((await ref.get()).exists) continue;
  const steps = [{ actorId: 'demo-reporter', actorName: 'María Estudiante', type: 'CREATED', fromStatus: null, toStatus: 'REPORTADA', message: 'Incidencia registrada en los datos de demostración.' }];
  if (data.status !== 'REPORTADA') steps.push({ actorId: 'demo-admin', actorName: 'Ana Administradora', type: 'ASSIGNED', fromStatus: 'REPORTADA', toStatus: 'ASIGNADA', message: 'Asignada al equipo de soporte para su atención.' });
  if (data.status === 'RESUELTA') {
    steps.push({ actorId: 'demo-technician', actorName: 'Carlos Técnico', type: 'STATUS_CHANGED', fromStatus: 'ASIGNADA', toStatus: 'EN_ATENCION', message: 'Se inició la reparación del lavamanos.' });
    steps.push({ actorId: 'demo-technician', actorName: 'Carlos Técnico', type: 'STATUS_CHANGED', fromStatus: 'EN_ATENCION', toStatus: 'RESUELTA', message: 'Se cambió el empaque y se comprobó que no hay fugas.' });
  }
  const batch = db.batch();
  batch.create(ref, {
    ...data, number: `CF-${new Date().getUTCFullYear()}-${id.slice(0, 8).toUpperCase()}`,
    reporterId: 'demo-reporter', reporterName: 'María Estudiante', createdAt: now, updatedAt: now,
    resolvedAt: data.status === 'RESUELTA' ? now : null, closedAt: null,
    version: steps.length, lastEventId: `seed-${steps.length}`,
  });
  for (const [index, step] of steps.entries()) batch.create(ref.collection('events').doc(`seed-${index + 1}`), { ...step, version: index + 1, createdAt: now });
  await batch.commit();
}
console.log(`Datos de demostración listos exclusivamente en ${projectId}.`);
console.table(people.map(({ email, role }) => ({ email, role, password })));
