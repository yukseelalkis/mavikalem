-- Data-preserving schema alignment for remote-only picking flow.
-- Target shape:
--   picked_items(order_id, sku, product_name, quantity, updated_at)
-- This script is idempotent and safe to re-run.

create extension if not exists pgcrypto;

-- 1) Ensure table exists.
create table if not exists public.picked_items (
  id uuid primary key default gen_random_uuid()
);

-- 2) Ensure required columns exist.
alter table public.picked_items
  add column if not exists order_id bigint,
  add column if not exists sku text,
  add column if not exists product_name text,
  add column if not exists quantity integer default 0,
  add column if not exists updated_at timestamptz default now();

-- 3) Backfill from legacy columns when possible.
do $$
begin
  -- Legacy sku nullable/empty cleanup.
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'picked_items'
      and column_name = 'match_key'
  ) then
    execute $sql$
      update public.picked_items
      set sku = coalesce(nullif(trim(sku), ''), nullif(trim(match_key), ''))
      where sku is null or trim(sku) = ''
    $sql$;
  end if;

  -- Legacy barcode fallback into sku.
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'picked_items'
      and column_name = 'barcode'
  ) then
    execute $sql$
      update public.picked_items
      set sku = coalesce(nullif(trim(sku), ''), nullif(trim(barcode), ''))
      where sku is null or trim(sku) = ''
    $sql$;
  end if;

  -- Ensure product_name has a value.
  execute $sql$
    update public.picked_items
    set product_name = coalesce(nullif(trim(product_name), ''), sku, 'unknown')
    where product_name is null or trim(product_name) = ''
  $sql$;

  -- Guard quantity lower bound.
  execute $sql$
    update public.picked_items
    set quantity = greatest(coalesce(quantity, 0), 0)
    where quantity is null or quantity < 0
  $sql$;
end $$;

-- 4) Remove rows still missing mandatory key fields.
delete from public.picked_items
where order_id is null
   or sku is null
   or trim(sku) = '';

-- 5) Normalize sku formatting to reduce duplicate keys.
update public.picked_items
set sku = trim(sku)
where sku <> trim(sku);

-- 6) Resolve duplicate (order_id, sku) rows by summing quantity.
with merged as (
  select
    order_id,
    sku,
    coalesce(max(nullif(trim(product_name), '')), sku, 'unknown') as product_name,
    sum(greatest(coalesce(quantity, 0), 0))::integer as quantity,
    max(updated_at) as updated_at
  from public.picked_items
  group by order_id, sku
),
deleted as (
  delete from public.picked_items
  where order_id is not null
    and sku is not null
  returning *
)
insert into public.picked_items (id, order_id, sku, product_name, quantity, updated_at)
select gen_random_uuid(), m.order_id, m.sku, m.product_name, m.quantity, coalesce(m.updated_at, now())
from merged m;

-- 7) Enforce final constraints and indexes.
alter table public.picked_items
  alter column order_id set not null,
  alter column sku set not null,
  alter column product_name set not null,
  alter column quantity set default 0,
  alter column quantity set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

alter table public.picked_items
  drop constraint if exists picked_items_quantity_check;
alter table public.picked_items
  add constraint picked_items_quantity_check check (quantity >= 0);

drop index if exists public.picked_items_order_match_uidx;
drop index if exists public.picked_items_order_sku_uidx;
create unique index if not exists picked_items_order_sku_uidx
  on public.picked_items (order_id, sku);

drop index if exists public.picked_items_order_updated_idx;
create index if not exists picked_items_order_updated_idx
  on public.picked_items (order_id, updated_at desc);

-- 8) Ensure updated_at trigger exists.
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

-- 9) Ensure RLS and policies for remote-only client access.
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

-- 10) Ensure realtime publication membership.
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
