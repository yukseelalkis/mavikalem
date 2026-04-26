-- Simplified realtime picking schema (order_id based, no sessions).
-- Run this script in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.picked_items (
  id uuid primary key default gen_random_uuid(),
  order_id bigint not null,
  sku text not null,
  product_name text not null,
  quantity integer not null default 0 check (quantity >= 0),
  updated_at timestamptz not null default now()
);

create unique index if not exists picked_items_order_sku_uidx
  on public.picked_items (order_id, sku);

create index if not exists picked_items_order_updated_idx
  on public.picked_items (order_id, updated_at desc);

create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists picked_items_set_updated_at on public.picked_items;
create trigger picked_items_set_updated_at
before update on public.picked_items
for each row execute function public.tg_set_updated_at();

alter table public.picked_items enable row level security;

drop policy if exists "picked_items_select_anon" on public.picked_items;
create policy "picked_items_select_anon"
on public.picked_items
for select
to anon, authenticated
using (true);

drop policy if exists "picked_items_insert_anon" on public.picked_items;
create policy "picked_items_insert_anon"
on public.picked_items
for insert
to anon, authenticated
with check (true);

drop policy if exists "picked_items_update_anon" on public.picked_items;
create policy "picked_items_update_anon"
on public.picked_items
for update
to anon, authenticated
using (true)
with check (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'picked_items'
  ) then
    alter publication supabase_realtime add table public.picked_items;
  end if;
end $$;
