-- 057_business_bookkeeping.sql
-- Business-level bookkeeping: chart of accounts, invoicing (AR), expenses (AP),
-- payments, and reporting views. Accrual basis.
-- Distinct from load-level job costing (load_charges / v_load_margin) —
-- this layer tracks the health of the business itself.

-- ============================================================
-- CHART OF ACCOUNTS
-- ============================================================
create table if not exists chart_of_accounts (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid not null,
  account_code  text,
  account_name  text not null,
  account_type  text not null check (account_type in ('income','expense','asset','liability','equity')),
  tax_category  text,                 -- maps to a Schedule C line, e.g. 'Line 27a — Other expenses'
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ============================================================
-- CARRIER BILLING TERMS
-- How you're paid per carrier: flat fee, percentage, or a mix over time.
-- ============================================================
create table if not exists carrier_billing_terms (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,
  carrier_id        uuid not null references carriers(id),
  fee_type          text not null check (fee_type in ('flat','percentage')),
  flat_fee_amount   numeric,
  percentage_rate   numeric,          -- store as decimal, e.g. 0.08 for 8%
  effective_date    date not null default current_date,
  notes             text,
  created_at        timestamptz not null default now(),

  constraint fee_amount_matches_type check (
    (fee_type = 'flat' and flat_fee_amount is not null)
    or
    (fee_type = 'percentage' and percentage_rate is not null)
  )
);

create index if not exists idx_carrier_billing_terms_carrier
  on carrier_billing_terms(carrier_id, effective_date desc);

-- ============================================================
-- INVOICES  (accounts receivable)
-- ============================================================
create table if not exists invoices (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null,
  invoice_number  text,
  carrier_id      uuid not null references carriers(id),
  status          text not null default 'draft'
                    check (status in ('draft','sent','paid','overdue','void')),
  issue_date      date,
  due_date        date,
  subtotal        numeric not null default 0,
  total           numeric not null default 0,
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_invoices_carrier   on invoices(carrier_id);
create index if not exists idx_invoices_status    on invoices(status);
create index if not exists idx_invoices_due_date  on invoices(due_date);

-- ============================================================
-- INVOICE LINE ITEMS
-- Each line typically ties back to a real load — no re-entering freight data.
-- ============================================================
create table if not exists invoice_line_items (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null,
  invoice_id     uuid not null references invoices(id) on delete cascade,
  load_id        uuid references loads(id),
  description    text not null,
  fee_type       text check (fee_type in ('flat','percentage','other')),
  basis_amount   numeric,           -- linehaul rate the % was computed against, if applicable
  rate           numeric,           -- the flat amount or percentage used
  amount         numeric not null,
  created_at     timestamptz not null default now()
);

create index if not exists idx_invoice_line_items_invoice on invoice_line_items(invoice_id);
create index if not exists idx_invoice_line_items_load    on invoice_line_items(load_id);

-- ============================================================
-- EXPENSES  (accounts payable / cost tracking)
-- ============================================================
create table if not exists expenses (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null,
  account_id      uuid not null references chart_of_accounts(id),
  vendor          text,
  description     text,
  amount          numeric not null,
  incurred_on     date not null default current_date,
  payment_status  text not null default 'unpaid' check (payment_status in ('unpaid','paid')),
  created_at      timestamptz not null default now()
);

create index if not exists idx_expenses_account     on expenses(account_id);
create index if not exists idx_expenses_incurred_on on expenses(incurred_on);
create index if not exists idx_expenses_status      on expenses(payment_status);

-- ============================================================
-- PAYMENTS
-- Tracks ACTUAL cash movement, separate from the accrual figures above.
-- On accrual basis, invoices/expenses count when billed/incurred —
-- this table exists purely for real cash-flow visibility and reconciliation.
-- ============================================================
create table if not exists payments (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null,
  direction    text not null check (direction in ('in','out')),
  invoice_id   uuid references invoices(id),
  expense_id   uuid references expenses(id),
  amount       numeric not null,
  paid_on      date not null default current_date,
  method       text check (method in ('check','ach','cash','card','other')),
  notes        text,
  created_at   timestamptz not null default now(),

  constraint payment_not_both_linked check (
    not (invoice_id is not null and expense_id is not null)
  )
);

create index if not exists idx_payments_invoice on payments(invoice_id);
create index if not exists idx_payments_expense on payments(expense_id);
create index if not exists idx_payments_paid_on on payments(paid_on);

-- ============================================================
-- updated_at trigger (distinct name — avoids colliding with any existing trigger fn)
-- ============================================================
create or replace function biz_set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_chart_of_accounts_touch on chart_of_accounts;
create trigger trg_chart_of_accounts_touch
  before update on chart_of_accounts
  for each row execute function biz_set_updated_at();

drop trigger if exists trg_invoices_touch on invoices;
create trigger trg_invoices_touch
  before update on invoices
  for each row execute function biz_set_updated_at();

-- ============================================================
-- RLS — tenant isolation, matching the app_users → tenant_id pattern
-- ============================================================
alter table chart_of_accounts    enable row level security;
alter table carrier_billing_terms enable row level security;
alter table invoices             enable row level security;
alter table invoice_line_items   enable row level security;
alter table expenses             enable row level security;
alter table payments             enable row level security;

create policy tenant_all on chart_of_accounts
  for all using (
    tenant_id = (select tenant_id from app_users where auth_uid = auth.uid())
  );

create policy tenant_all on carrier_billing_terms
  for all using (
    tenant_id = (select tenant_id from app_users where auth_uid = auth.uid())
  );

create policy tenant_all on invoices
  for all using (
    tenant_id = (select tenant_id from app_users where auth_uid = auth.uid())
  );

create policy tenant_all on invoice_line_items
  for all using (
    tenant_id = (select tenant_id from app_users where auth_uid = auth.uid())
  );

create policy tenant_all on expenses
  for all using (
    tenant_id = (select tenant_id from app_users where auth_uid = auth.uid())
  );

create policy tenant_all on payments
  for all using (
    tenant_id = (select tenant_id from app_users where auth_uid = auth.uid())
  );

-- ============================================================
-- SEED — starter chart of accounts for your tenant
-- Safe to re-run: skips if accounts already exist for this tenant.
-- ============================================================
do $$
declare
  v_tenant uuid := 'e9dee1c9-7fc8-4caa-ab63-44328eaf532d';
begin
  if not exists (select 1 from chart_of_accounts where tenant_id = v_tenant) then

    insert into chart_of_accounts (tenant_id, account_code, account_name, account_type, tax_category) values
      (v_tenant, '4000', 'Dispatch Fee Income',        'income',  'Line 1 — Gross receipts'),
      (v_tenant, '4900', 'Other Income',                'income',  'Line 6 — Other income'),

      (v_tenant, '6010', 'Software & Subscriptions',    'expense', 'Line 27a — Other expenses'),
      (v_tenant, '6020', 'Phone',                        'expense', 'Line 25 — Utilities'),
      (v_tenant, '6030', 'Vehicle & Mileage',            'expense', 'Line 9 — Car and truck expenses'),
      (v_tenant, '6040', 'Insurance',                    'expense', 'Line 15 — Insurance'),
      (v_tenant, '6050', 'Professional Services',        'expense', 'Line 17 — Legal and professional services'),
      (v_tenant, '6060', 'Office Supplies',               'expense', 'Line 18 — Office expense'),
      (v_tenant, '6070', 'Marketing',                     'expense', 'Line 27a — Other expenses'),
      (v_tenant, '6080', 'Taxes & Licenses',              'expense', 'Line 23 — Taxes and licenses'),
      (v_tenant, '6090', 'Bank & Processing Fees',        'expense', 'Line 27a — Other expenses'),

      (v_tenant, '1000', 'Cash / Bank Balance',           'asset',   null),
      (v_tenant, '1100', 'Accounts Receivable',           'asset',   null),

      (v_tenant, '2000', 'Accounts Payable',              'liability', null),
      (v_tenant, '2100', 'Taxes Owed',                    'liability', null);

  end if;
end $$;

-- ============================================================
-- REPORTING VIEWS
-- ============================================================

-- Profit & Loss — accrual: invoices by issue_date, expenses by incurred_on
create or replace view v_profit_and_loss as
select
  tenant_id,
  date_trunc('month', period_date)::date as period_month,
  account_type,
  account_name,
  sum(amount) as total_amount
from (
  select
    i.tenant_id,
    i.issue_date as period_date,
    'income'::text as account_type,
    coa.account_name,
    li.amount
  from invoice_line_items li
  join invoices i        on i.id = li.invoice_id
  join chart_of_accounts coa
    on coa.tenant_id = i.tenant_id and coa.account_type = 'income'
    and coa.account_code = '4000'
  where i.status <> 'void'

  union all

  select
    e.tenant_id,
    e.incurred_on as period_date,
    'expense'::text as account_type,
    coa.account_name,
    e.amount
  from expenses e
  join chart_of_accounts coa on coa.id = e.account_id
) combined
group by tenant_id, date_trunc('month', period_date), account_type, account_name
order by period_month desc, account_type, account_name;

-- Accounts Receivable Aging
create or replace view v_ar_aging as
select
  i.id,
  i.tenant_id,
  i.invoice_number,
  i.carrier_id,
  i.status,
  i.due_date,
  i.total,
  (current_date - i.due_date) as days_overdue,
  case
    when i.status = 'paid' then 'paid'
    when i.due_date is null then 'no due date'
    when current_date <= i.due_date then 'current'
    when current_date - i.due_date <= 30 then '1-30 days'
    when current_date - i.due_date <= 60 then '31-60 days'
    when current_date - i.due_date <= 90 then '61-90 days'
    else '90+ days'
  end as aging_bucket
from invoices i
where i.status in ('sent','overdue');

-- Cash Flow — actual payments in vs out
create or replace view v_cash_flow as
select
  tenant_id,
  date_trunc('month', paid_on)::date as period_month,
  direction,
  sum(amount) as total_amount
from payments
group by tenant_id, date_trunc('month', paid_on), direction
order by period_month desc, direction;

-- Schedule C Summary — expenses grouped by tax category, per calendar year
create or replace view v_schedule_c_summary as
select
  e.tenant_id,
  extract(year from e.incurred_on)::int as tax_year,
  coa.tax_category,
  coa.account_name,
  sum(e.amount) as total_amount
from expenses e
join chart_of_accounts coa on coa.id = e.account_id
where coa.tax_category is not null
group by e.tenant_id, extract(year from e.incurred_on), coa.tax_category, coa.account_name
order by tax_year desc, coa.tax_category;
