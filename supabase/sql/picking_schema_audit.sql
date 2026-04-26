-- Audit script for remote-only picking schema compatibility.
-- Run in Supabase SQL Editor to inspect current database state.

-- 1) Table existence in public schema.
select
  table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('picked_items', 'picking_sessions')
order by table_name;

-- 2) picked_items columns and types.
select
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'picked_items'
order by ordinal_position;

-- 3) picked_items indexes (expect unique on order_id, sku).
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'picked_items'
order by indexname;

-- 4) picked_items RLS policies (expect select/insert/update for anon+authenticated).
select
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'picked_items'
order by policyname;

-- 5) Realtime publication membership.
select
  pubname,
  schemaname,
  tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
  and schemaname = 'public'
  and tablename in ('picked_items', 'picking_sessions')
order by tablename;
