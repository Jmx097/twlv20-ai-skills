import test from 'node:test';
import assert from 'node:assert/strict';
import { health, isTenantSlug, TENANTS } from '../src/index.js';

test('health returns runtime identity and tenants', () => {
  const result = health();
  assert.equal(result.ok, true);
  assert.equal(result.service, 'twlv20-ai-runtime');
  assert.deepEqual(result.tenants, TENANTS);
});

test('tenant slug guard accepts known tenants only', () => {
  assert.equal(isTenantSlug('pure-peptide'), true);
  assert.equal(isTenantSlug('not-a-tenant'), false);
});
