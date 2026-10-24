#!/usr/bin/env node
import { readFileSync } from 'fs';
import { MongoClient } from 'mongodb';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');

function loadUri() {
  if (process.env.MONGODB_URI?.trim()) return process.env.MONGODB_URI.trim();
  const envPath = join(root, 'apps/api/.env');
  const match = readFileSync(envPath, 'utf8').match(/MONGODB_URI=\s*(.+)/);
  if (!match) throw new Error('Set MONGODB_URI');
  return match[1].trim();
}

const uri = loadUri().replace(/\/[^/?]+(\?|$)/, '/training-record$1');
const client = new MongoClient(uri);
await client.connect();
const db = client.db('training-record');
await db.collection('programs').createIndex({ programType: 1 }, { unique: true });
await db.collection('sessions').createIndex({ programType: 1, date: 1 });
await db.collection('sessions').createIndex({ id: 1 }, { unique: true });
await db.collection('sessions').createIndex({ 'exercises.id': 1 });
await db.collection('_meta').updateOne(
  { _id: 'setup' },
  {
    $set: {
      app: 'training-record',
      updatedAt: new Date(),
      note: 'Rotate DB password; iOS must use App Services, not this URI.',
    },
  },
  { upsert: true },
);
const names = (await db.listCollections().toArray()).map((c) => c.name);
console.log('training-record ready:', names.join(', '));
await client.close();
