-- ============================================================
-- 033_accessorial_processing_fields.sql
-- Heavy Haul Command
--
-- Aligns public.accessorials with the Load Workspace
-- processing workflow:
--
-- Pending -> Approved / Denied -> Invoiced -> Paid
--
-- Safe to rerun.
-- ============================================================


alter table public.accessorials
  add column if not exists approved_amount numeric(12,2);

alter table public.accessorials
  add column if not exists approval_reference text;

alter table public.accessorials
  add column if not exists denial_reason text;

alter table public.accessorials
  add column if not exists invoice_number text;

alter table public.accessorials
  add column if not exists paid_amount numeric(12,2);

alter table public.accessorials
  add column if not exists paid_at timestamptz;

alter table public.accessorials
  add column if not exists processing_notes text;


-- Helpful timestamps for the processing lifecycle.
alter table public.accessorials
  add column if not exists approved_at timestamptz;

alter table public.accessorials
  add column if not exists denied_at timestamptz;

alter table public.accessorials
  add column if not exists invoiced_at timestamptz;


-- Reload PostgREST schema cache so the browser can see
-- the newly-added fields immediately.
notify pgrst, 'reload schema';


-- ============================================================
-- VERIFICATION
-- ============================================================

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'accessorials'
  and column_name in (
    'status',
    'requested_amount',
    'approved_amount',
    'approval_reference',
    'approved_at',
    'denial_reason',
    'denied_at',
    'invoice_number',
    'invoiced_at',
    'paid_amount',
    'paid_at',
    'processing_notes'
  )
order by ordinal_position;
