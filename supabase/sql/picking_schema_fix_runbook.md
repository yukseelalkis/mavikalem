# Picking Schema Fix Runbook

This runbook resolves `42703: column picked_items.order_id does not exist` for the remote-only picking flow.

## 1) Verify app is pointing to expected Supabase project

- Check `.env` values:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- Confirm the same project is open in Supabase Dashboard.

## 2) Audit current schema

Run:

- `supabase/sql/picking_schema_audit.sql`

Expected:

- `public.picked_items` exists
- Columns include `order_id`, `sku`, `product_name`, `quantity`, `updated_at`
- Unique index exists on `(order_id, sku)`
- RLS policies exist for `select/insert/update`
- `picked_items` appears in `supabase_realtime` publication

## 3) Align schema safely (data-preserving)

Run:

- `supabase/sql/picking_schema_align_remote_only.sql`

What it does:

- Adds missing required columns
- Backfills legacy fields (`match_key`, `barcode`) into `sku` where needed
- Removes invalid rows missing keys
- Merges duplicates per `(order_id, sku)` by summing quantity
- Recreates expected indexes, RLS policies, and realtime publication

## 4) Re-run audit

Run `picking_schema_audit.sql` again and confirm expected structure.

## 5) Validate from app

1. Open an order and enable picking mode.
2. Scan/add one line item.
3. Verify no red snackbar with `column picked_items.order_id does not exist`.
4. Confirm progress/line status updates from realtime stream.
5. Verify submit button enable/disable follows stream state.

## 6) Rollback note

This migration is intended to be idempotent and forward-fixing.  
If you need rollback, restore from Supabase backup/snapshot before re-running.
