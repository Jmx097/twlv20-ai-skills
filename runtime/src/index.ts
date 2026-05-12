export type TenantSlug = 'global' | 'pure-peptide' | 'agere-sciences' | 'sru' | 'twlv20-internal';

export const TENANTS: TenantSlug[] = ['global', 'pure-peptide', 'agere-sciences', 'sru', 'twlv20-internal'];

export function isTenantSlug(value: string): value is TenantSlug {
  return (TENANTS as readonly string[]).includes(value);
}

export function health(): { ok: true; service: string; tenants: TenantSlug[] } {
  return { ok: true, service: 'twlv20-ai-runtime', tenants: TENANTS };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  console.log(JSON.stringify(health()));
  setInterval(() => {
    // no-op scaffold service heartbeat; real runtime loop lands in a later task.
  }, 60_000);
}
