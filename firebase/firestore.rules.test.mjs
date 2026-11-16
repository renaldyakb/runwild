import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-runwild',
    firestore: { rules: await readFile(new URL('./firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(() => env?.cleanup());

function profile(email = 'runner@example.com') {
  return {
    displayName: 'Pelari',
    email,
    level: 'pemula',
    goal: 'sehat',
    units: 'km',
    weeklyGoal: { type: 'sessions', target: 3 },
    privacy: { hideStartEnd: true, trimMeters: 200, defaultVisibility: 'private' },
    voice: { enabled: true, volume: 0.8, haptics: true, countdownCue: true, roundCue: true },
    autoPause: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    schemaVersion: 1,
  };
}
const owner = () => env.authenticatedContext('runner', { email: 'runner@example.com' }).firestore();

test('pemilik dan tamu dapat membuat dan membaca profil sendiri', async () => {
  const ref = doc(owner(), 'users/runner');
  await assertSucceeds(setDoc(ref, profile()));
  assert.equal((await assertSucceeds(getDoc(ref))).data().weeklyGoal.target, 3);
  const guest = doc(env.authenticatedContext('guest').firestore(), 'users/guest');
  await assertSucceeds(setDoc(guest, profile('')));
  await assertSucceeds(getDoc(guest));
});

test('profil akun lain, koleksi, dan subkoleksi tetap tertutup', async () => {
  const db = owner();
  await assertSucceeds(setDoc(doc(db, 'users/runner'), profile()));
  const other = env.authenticatedContext('other').firestore();
  await assertFails(getDoc(doc(other, 'users/runner')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/runner')));
  await assertFails(setDoc(doc(other, 'users/runner'), profile('')));
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(setDoc(doc(db, 'users/runner/activities/a'), { meters: 10 }));
  await assertFails(updateDoc(doc(db, 'users/runner'), { displayName: 'Nama baru' }));
  await assertFails(deleteDoc(doc(db, 'users/runner')));
});

test('field ekstra, email palsu, nilai target, dan timestamp klien ditolak', async () => {
  const ref = doc(owner(), 'users/runner');
  for (const changes of [
    { admin: true },
    { email: 'other@example.com' },
    { weeklyGoal: { type: 'sessions', target: 8 } },
    { displayName: '   ' },
    { createdAt: new Date(0) },
  ]) {
    await assertFails(setDoc(ref, { ...profile(), ...changes }));
  }
});
