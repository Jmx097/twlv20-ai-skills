import test from 'node:test';
import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { health, isTenantSlug, TENANTS } from '../src/index.js';

const tenantSkillsRoot = join(process.cwd(), '..', 'skills');
const infraSchemaPath = join(process.cwd(), '..', 'infra', 'schema.sql');

test('health returns runtime identity and tenants', () => {
  const result = health();
  assert.equal(result.ok, true);
  assert.equal(result.service, 'twlv20-ai-runtime');
  assert.deepEqual(result.tenants, TENANTS);
});

test('tenant slug guard accepts known tenants only', () => {
  assert.equal(isTenantSlug('pure-peptide'), true);
  assert.equal(isTenantSlug('agere-sciences'), true);
  assert.equal(isTenantSlug('ajiri'), false);
  assert.equal(isTenantSlug('not-a-tenant'), false);
});

test('runtime tenant list matches mapped skill directories', async () => {
  const skillDirectories = (await readdir(tenantSkillsRoot, { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();

  assert.deepEqual([...TENANTS].sort(), skillDirectories);
});

test('skill manifests use the mapped tenant slug for name and scope', async () => {
  for (const tenant of TENANTS) {
    const manifest = await readFile(join(tenantSkillsRoot, tenant, 'skill.yaml'), 'utf8');
    assert.match(manifest, new RegExp(`^name: ${tenant}$`, 'm'));
    assert.match(manifest, new RegExp(`^scope: ${tenant}$`, 'm'));
  }
});

test('runtime tenants match infra seed tenant slugs', async () => {
  const schema = await readFile(infraSchemaPath, 'utf8');
  const seedBlock = schema.match(/INSERT INTO tenants \(slug, name\) VALUES([\s\S]*?)ON CONFLICT/);
  assert.ok(seedBlock, 'tenant seed block should be present in infra/schema.sql');

  const seededTenants = [...seedBlock[1].matchAll(/\('([^']+)',/g)].map((match) => match[1]).sort();
  const runtimeTenants = TENANTS.filter((tenant) => tenant !== 'global').sort();

  assert.deepEqual(runtimeTenants, seededTenants);
});
