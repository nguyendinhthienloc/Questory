create table if not exists public.shared_run_links (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  run_payload jsonb not null,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

insert into storage.buckets (id, name, public)
values ('shared-run-images', 'shared-run-images', false)
on conflict (id) do nothing;

alter table public.shared_run_links enable row level security;

revoke all on table public.shared_run_links from anon, authenticated;

create index if not exists shared_run_links_expires_at_idx
  on public.shared_run_links (expires_at);
