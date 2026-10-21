import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const args = process.argv.slice(2);
const argument = (name) => {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
};
const projectId = argument('--project');
const email = argument('--email');
if (!projectId || !email || !/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(projectId) || !email.includes('@')) {
  throw new Error('Uso: npm run bootstrap:admin -- --project ID_REAL --email usuario@ejemplo.com. Primero registre esa cuenta en CampusFix. Requiere Application Default Credentials con acceso a Firebase Auth y Firestore.');
}
if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST || projectId.startsWith('demo-')) {
  throw new Error('Este script es para producción. Para emuladores use npm run seed:emulators.');
}
initializeApp({ projectId, credential: applicationDefault() });
const account = await getAuth().getUserByEmail(email);
if (account.disabled) throw new Error('La cuenta Auth está deshabilitada. No se modificó el perfil.');
const db = getFirestore();
const ref = db.doc(`users/${account.uid}`);
await db.runTransaction(async (transaction) => {
  const existing = await transaction.get(ref);
  if (existing.exists) {
    transaction.update(ref, { role: 'admin', active: true, updatedAt: FieldValue.serverTimestamp() });
  } else {
    transaction.create(ref, {
      name: account.displayName || email.split('@')[0], email: account.email,
      role: 'admin', active: true,
      createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    });
  }
});
console.log(`Administrador habilitado: ${account.email} (${account.uid}), proyecto ${projectId}.`);
console.log('Las credenciales administrativas permanecen fuera de la aplicación cliente.');
