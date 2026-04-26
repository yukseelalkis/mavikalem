-- Realtime order picking setup for Mavikalem.
-- Run this script in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.picking_sessions (
  id uuid primary key default gen_random_uuid(),
  order_id bigint not null,
  picker_name text not null,
  device_id text,
  supabase_user_id uuid not null default auth.uid(),
  status text not null default 'active'
    check (status in ('active', 'completed', 'cancelled')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists picking_sessions_order_status_idx
  on public.picking_sessions (order_id, status);

create index if not exists picking_sessions_started_at_idx
  on public.picking_sessions (started_at desc);

create table if not exists public.picked_items (
  id uuid primary key default gen_random_uuid(),
  order_id bigint not null,
  match_key text not null,
  sku text,
  barcode text,
  product_name text not null,
  quantity integer not null default 0 check (quantity >= 0),
  last_session_id uuid references public.picking_sessions(id) on delete set null,
  last_picker_name text,
  last_device_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists picked_items_order_match_uidx
  on public.picked_items (order_id, match_key);

create index if not exists picked_items_order_updated_idx
  on public.picked_items (order_id, updated_at desc);

create index if not exists picked_items_session_idx
  on public.picked_items (last_session_id);

create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists picking_sessions_set_updated_at on public.picking_sessions;
create trigger picking_sessions_set_updated_at
before update on public.picking_sessions
for each row execute function public.tg_set_updated_at();

drop trigger if exists picked_items_set_updated_at on public.picked_items;
create trigger picked_items_set_updated_at
before update on public.picked_items
for each row execute function public.tg_set_updated_at();

alter table public.picking_sessions enable row level security;
alter table public.picked_items enable row level security;

drop policy if exists "picking_sessions_select_authenticated" on public.picking_sessions;
create policy "picking_sessions_select_authenticated"
on public.picking_sessions
for select
to authenticated
using (true);

drop policy if exists "picking_sessions_insert_authenticated" on public.picking_sessions;
create policy "picking_sessions_insert_authenticated"
on public.picking_sessions
for insert
to authenticated
with check (supabase_user_id = auth.uid());

drop policy if exists "picking_sessions_update_authenticated" on public.picking_sessions;
create policy "picking_sessions_update_authenticated"
on public.picking_sessions
for update
to authenticated
using (true)
with check (true);

drop policy if exists "picked_items_select_authenticated" on public.picked_items;
create policy "picked_items_select_authenticated"
on public.picked_items
for select
to authenticated
using (true);

drop policy if exists "picked_items_insert_authenticated" on public.picked_items;
create policy "picked_items_insert_authenticated"
on public.picked_items
for insert
to authenticated
with check (true);

drop policy if exists "picked_items_update_authenticated" on public.picked_items;
create policy "picked_items_update_authenticated"
on public.picked_items
for update
to authenticated
using (true)
with check (true);

create or replace function public.add_picked_item(
  p_order_id bigint,
  p_match_key text,
  p_sku text,
  p_barcode text,
  p_product_name text,
  p_quantity integer,
  p_session_id uuid,
  p_picker_name text,
  p_device_id text
) returns public.picked_items
language plpgsql
security invoker
as $$
declare
  v_row public.picked_items;
begin
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'p_quantity must be > 0';
  end if;

  if p_match_key is null or length(trim(p_match_key)) = 0 then
    raise exception 'p_match_key required';
  end if;

  insert into public.picked_items (
    order_id,
    match_key,
    sku,
    barcode,
    product_name,
    quantity,
    last_session_id,
    last_picker_name,
    last_device_id
  ) values (
    p_order_id,
    p_match_key,
    nullif(p_sku, ''),
    nullif(p_barcode, ''),
    p_product_name,
    p_quantity,
    p_session_id,
    p_picker_name,
    p_device_id
  )
  on conflict (order_id, match_key) do update set
    quantity = public.picked_items.quantity + excluded.quantity,
    sku = coalesce(public.picked_items.sku, excluded.sku),
    barcode = coalesce(public.picked_items.barcode, excluded.barcode),
    product_name = excluded.product_name,
    last_session_id = excluded.last_session_id,
    last_picker_name = excluded.last_picker_name,
    last_device_id = excluded.last_device_id
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.add_picked_item(
  bigint,
  text,
  text,
  text,
  text,
  integer,
  uuid,
  text,
  text
) to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'picking_sessions'
  ) then
    alter publication supabase_realtime add table public.picking_sessions;
  end if;
end $$;

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
