-- SchoolConnect core schema — initial foundation, not a complete production deployment.
-- Apply only after reviewing against the target Supabase project and its current docs.
create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  timezone text not null default 'Asia/Kolkata',
  default_language text not null default 'gu' check (default_language in ('gu','hi','en')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.school_memberships (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','admissions','teacher','viewer')),
  created_at timestamptz not null default now(),
  unique (school_id,user_id),
  unique (school_id,id)
);

-- This narrowly scoped SECURITY DEFINER helper avoids recursive RLS when a policy
-- checks membership in school_memberships itself. It can only test the caller's
-- own membership and is kept outside the exposed public schema.
create or replace function private.is_school_member(p_school_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
     and exists (
       select 1
       from public.school_memberships sm
       where sm.school_id = p_school_id
         and sm.user_id = auth.uid()
     );
$$;
revoke all on function private.is_school_member(uuid) from public;
grant execute on function private.is_school_member(uuid) to authenticated;

create table public.school_branches (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  address text,
  phone text,
  created_at timestamptz not null default now(),
  unique (school_id,id)
);

create table public.school_classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  age_min_months integer check (age_min_months is null or age_min_months >= 0),
  age_max_months integer check (age_max_months is null or age_max_months >= age_min_months),
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (school_id,id),
  unique (school_id,name)
);

create table public.fee_plans (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid,
  name text not null,
  fee_type text not null check (fee_type in ('admission','tuition','annual','transport','other')),
  amount_paise bigint not null check (amount_paise >= 0),
  currency char(3) not null default 'INR',
  billing_period text not null default 'one_time' check (billing_period in ('one_time','monthly','quarterly','yearly')),
  effective_from date,
  effective_to date,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  unique (school_id,id),
  foreign key (school_id,class_id) references public.school_classes(school_id,id),
  check (effective_to is null or effective_from is null or effective_to >= effective_from)
);

create table public.school_content (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  content_type text not null check (content_type in ('facility','faq','policy','hours','admission_info')),
  language text not null check (language in ('gu','hi','en')),
  title text not null,
  body text not null,
  is_published boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (school_id,id)
);

create table public.parents (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  full_name text not null,
  phone_e164 text,
  preferred_language text check (preferred_language in ('gu','hi','en')),
  whatsapp_opt_in_at timestamptz,
  whatsapp_opt_in_source text,
  privacy_notice_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id)
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  parent_id uuid not null,
  class_id uuid,
  full_name text not null,
  date_of_birth date,
  admission_status text not null default 'enquiry' check (admission_status in ('enquiry','applied','admitted','withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  foreign key (school_id,parent_id) references public.parents(school_id,id),
  foreign key (school_id,class_id) references public.school_classes(school_id,id)
);

create table public.admission_enquiries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  parent_id uuid,
  child_name text,
  class_id uuid,
  source text not null default 'staff' check (source in ('whatsapp','phone','walk_in','website','referral','staff','other')),
  status text not null default 'new' check (status in ('new','contacted','visit_booked','applied','admitted','closed')),
  notes text,
  assigned_to uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  foreign key (school_id,parent_id) references public.parents(school_id,id),
  foreign key (school_id,class_id) references public.school_classes(school_id,id)
);

create table public.visit_slots (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity integer not null check (capacity > 0),
  is_open boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id,id),
  check (ends_at > starts_at)
);

create table public.visit_bookings (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  slot_id uuid not null,
  parent_id uuid not null,
  enquiry_id uuid,
  party_size integer not null default 1 check (party_size > 0),
  status text not null default 'confirmed' check (status in ('confirmed','cancelled','attended','no_show')),
  created_at timestamptz not null default now(),
  unique (school_id,id),
  foreign key (school_id,slot_id) references public.visit_slots(school_id,id),
  foreign key (school_id,parent_id) references public.parents(school_id,id),
  foreign key (school_id,enquiry_id) references public.admission_enquiries(school_id,id)
);

create table public.whatsapp_channels (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  provider text not null default 'meta_cloud_api',
  phone_number_id text,
  display_phone text,
  connection_status text not null default 'not_connected' check (connection_status in ('not_connected','pending','connected','disabled')),
  created_at timestamptz not null default now(),
  unique (school_id,id)
);

create table public.message_logs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  parent_id uuid,
  direction text not null check (direction in ('inbound','outbound')),
  channel text not null default 'whatsapp',
  provider_message_id text,
  template_name text,
  language text check (language in ('gu','hi','en')),
  delivery_status text,
  created_at timestamptz not null default now(),
  foreign key (school_id,parent_id) references public.parents(school_id,id)
);

create index school_memberships_user_idx on public.school_memberships(user_id,school_id);
create index enquiries_school_status_created_idx on public.admission_enquiries(school_id,status,created_at desc);
create index students_school_parent_idx on public.students(school_id,parent_id);
create index visit_slots_school_start_idx on public.visit_slots(school_id,starts_at);
create index visit_bookings_school_slot_status_idx on public.visit_bookings(school_id,slot_id,status);
create index message_logs_school_created_idx on public.message_logs(school_id,created_at desc);

-- RLS is enabled on every application table in the exposed public schema.
alter table public.schools enable row level security;
alter table public.school_memberships enable row level security;
alter table public.school_branches enable row level security;
alter table public.school_classes enable row level security;
alter table public.fee_plans enable row level security;
alter table public.school_content enable row level security;
alter table public.parents enable row level security;
alter table public.students enable row level security;
alter table public.admission_enquiries enable row level security;
alter table public.visit_slots enable row level security;
alter table public.visit_bookings enable row level security;
alter table public.whatsapp_channels enable row level security;
alter table public.message_logs enable row level security;

-- Remove any inherited/default Data API grants first. RLS does not replace GRANT/REVOKE.
revoke all on table public.schools, public.school_memberships,
  public.school_branches,
  public.school_classes,
  public.fee_plans,
  public.school_content,
  public.parents,
  public.students,
  public.admission_enquiries,
  public.visit_slots,
  public.visit_bookings,
  public.whatsapp_channels,
  public.message_logs
from anon, authenticated;

-- Membership rows are readable only by the member themselves. Provision membership
-- from a trusted administrative workflow; there are intentionally no client INSERT/UPDATE policies.
create policy "members can read own memberships"
on public.school_memberships for select to authenticated
using (user_id = (select auth.uid()));

create policy "members can read their schools"
on public.schools for select to authenticated
using (private.is_school_member(id));

create policy "school members can update school profile"
on public.schools for update to authenticated
using (private.is_school_member(id))
with check (private.is_school_member(id));

-- Separate policies make each operation explicit. All members currently share the same
-- tenant-scoped CRUD baseline; enforce role-specific restrictions before production.

create policy "school_branches members can select"
on public.school_branches for select to authenticated
using (private.is_school_member(school_id));

create policy "school_branches members can insert"
on public.school_branches for insert to authenticated
with check (private.is_school_member(school_id));

create policy "school_branches members can update"
on public.school_branches for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "school_branches members can delete"
on public.school_branches for delete to authenticated
using (private.is_school_member(school_id));

create policy "school_classes members can select"
on public.school_classes for select to authenticated
using (private.is_school_member(school_id));

create policy "school_classes members can insert"
on public.school_classes for insert to authenticated
with check (private.is_school_member(school_id));

create policy "school_classes members can update"
on public.school_classes for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "school_classes members can delete"
on public.school_classes for delete to authenticated
using (private.is_school_member(school_id));

create policy "fee_plans members can select"
on public.fee_plans for select to authenticated
using (private.is_school_member(school_id));

create policy "fee_plans members can insert"
on public.fee_plans for insert to authenticated
with check (private.is_school_member(school_id));

create policy "fee_plans members can update"
on public.fee_plans for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "fee_plans members can delete"
on public.fee_plans for delete to authenticated
using (private.is_school_member(school_id));

create policy "school_content members can select"
on public.school_content for select to authenticated
using (private.is_school_member(school_id));

create policy "school_content members can insert"
on public.school_content for insert to authenticated
with check (private.is_school_member(school_id));

create policy "school_content members can update"
on public.school_content for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "school_content members can delete"
on public.school_content for delete to authenticated
using (private.is_school_member(school_id));

create policy "parents members can select"
on public.parents for select to authenticated
using (private.is_school_member(school_id));

create policy "parents members can insert"
on public.parents for insert to authenticated
with check (private.is_school_member(school_id));

create policy "parents members can update"
on public.parents for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "parents members can delete"
on public.parents for delete to authenticated
using (private.is_school_member(school_id));

create policy "students members can select"
on public.students for select to authenticated
using (private.is_school_member(school_id));

create policy "students members can insert"
on public.students for insert to authenticated
with check (private.is_school_member(school_id));

create policy "students members can update"
on public.students for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "students members can delete"
on public.students for delete to authenticated
using (private.is_school_member(school_id));

create policy "admission_enquiries members can select"
on public.admission_enquiries for select to authenticated
using (private.is_school_member(school_id));

create policy "admission_enquiries members can insert"
on public.admission_enquiries for insert to authenticated
with check (private.is_school_member(school_id));

create policy "admission_enquiries members can update"
on public.admission_enquiries for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "admission_enquiries members can delete"
on public.admission_enquiries for delete to authenticated
using (private.is_school_member(school_id));

create policy "visit_slots members can select"
on public.visit_slots for select to authenticated
using (private.is_school_member(school_id));

create policy "visit_slots members can insert"
on public.visit_slots for insert to authenticated
with check (private.is_school_member(school_id));

create policy "visit_slots members can update"
on public.visit_slots for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "visit_slots members can delete"
on public.visit_slots for delete to authenticated
using (private.is_school_member(school_id));

create policy "visit_bookings members can select"
on public.visit_bookings for select to authenticated
using (private.is_school_member(school_id));

create policy "visit_bookings members can insert"
on public.visit_bookings for insert to authenticated
with check (private.is_school_member(school_id));

create policy "visit_bookings members can update"
on public.visit_bookings for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "visit_bookings members can delete"
on public.visit_bookings for delete to authenticated
using (private.is_school_member(school_id));

create policy "whatsapp_channels members can select"
on public.whatsapp_channels for select to authenticated
using (private.is_school_member(school_id));

create policy "whatsapp_channels members can insert"
on public.whatsapp_channels for insert to authenticated
with check (private.is_school_member(school_id));

create policy "whatsapp_channels members can update"
on public.whatsapp_channels for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "whatsapp_channels members can delete"
on public.whatsapp_channels for delete to authenticated
using (private.is_school_member(school_id));

create policy "message_logs members can select"
on public.message_logs for select to authenticated
using (private.is_school_member(school_id));

create policy "message_logs members can insert"
on public.message_logs for insert to authenticated
with check (private.is_school_member(school_id));

create policy "message_logs members can update"
on public.message_logs for update to authenticated
using (private.is_school_member(school_id))
with check (private.is_school_member(school_id));

create policy "message_logs members can delete"
on public.message_logs for delete to authenticated
using (private.is_school_member(school_id));

-- Explicit table grants are still required in addition to RLS. No anon access is granted.
grant select, update on public.schools to authenticated;
grant select on public.school_memberships to authenticated;
grant select, insert, update, delete on
  public.school_branches,
  public.school_classes,
  public.fee_plans,
  public.school_content,
  public.parents,
  public.students,
  public.admission_enquiries,
  public.visit_slots,
  public.visit_bookings,
  public.whatsapp_channels,
  public.message_logs
to authenticated;

-- Intentionally not implemented here:
-- * self-service tenant creation / membership invitation flow
-- * public/anonymous enquiry intake
-- * role-specific permission matrix
-- * atomic capacity-checked booking RPC
-- * audit log, retention, deletion, and data export workflows
-- * verified Meta webhook and WhatsApp message sender
