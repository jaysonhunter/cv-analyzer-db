-----------------------------------------
-- EXTENSIONS
-----------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;
create extension if not exists moddatetime;


-----------------------------------------
-- SCHEMAS
-----------------------------------------
create schema if not exists kit;


-----------------------------------------
-- HELPER FUNCTIONS
-- You must paste your actual implementations here.
-- I include safe placeholders so the file executes.
-----------------------------------------

-- Replace this with your real logic
create or replace function kit.protect_account_fields()
returns trigger
language plpgsql
as $$
begin
  return new;
end;
$$;

-- Replace this with your real logic
create or replace function set_created_by()
returns trigger
language plpgsql
as $$
begin
  if new.created_by is null then
    new.created_by := auth.uid();
  end if;
  return new;
end;
$$;


-----------------------------------------
-- TABLES
-----------------------------------------

-----------------------------------------
-- 1. ACCOUNTS
-----------------------------------------
create table public.accounts (
  id uuid not null default extensions.uuid_generate_v4(),
  name character varying(255) not null,
  email character varying(320) null,
  updated_at timestamp with time zone null,
  created_at timestamp with time zone null,
  updated_by uuid null,
  picture_url character varying(1000) null,
  public_data jsonb not null default '{}'::jsonb,
  role text null default 'user'::text,
  constraint accounts_pkey primary key (id),
  constraint accounts_email_key unique (email),
  constraint accounts_updated_by_fkey foreign key (updated_by) references auth.users (id),
  constraint accounts_user_fkey foreign key (id) references auth.users (id) on delete cascade,
  constraint accounts_role_check check (
    role = any (array['user'::text, 'admin'::text])
  )
) tablespace pg_default;

create index if not exists accounts_role_idx
on public.accounts using btree (role);

create trigger protect_account_fields
before update on accounts
for each row
execute function kit.protect_account_fields();


-----------------------------------------
-- 2. JOBS
-----------------------------------------
create table public.jobs (
  id uuid not null default gen_random_uuid(),
  job_ref text null,
  job_title text not null,
  employment_type text null,
  location text null,
  description text null,
  cv_folder text null,
  status text null default 'open'::text,
  account_id uuid null,
  created_at timestamp with time zone null default (now() at time zone 'utc'::text),
  updated_at timestamp with time zone null default (now() at time zone 'utc'::text),
  created_by uuid null,
  started_at timestamp with time zone null,
  completed_at timestamp with time zone null,
  previous_status text null,
  retry_count numeric null default '0'::numeric,
  error_message text null,
  total_files numeric null,
  current_report_id uuid null,
  constraint jobs_pkey primary key (id),
  constraint jobs_account_id_fkey foreign key (account_id) references auth.users (id) on delete set null,
  constraint jobs_created_by_fkey foreign key (created_by) references auth.users (id),
  constraint jobs_current_report_id_fkey foreign key (current_report_id) references public.reports (id) on delete set null,
  constraint jobs_status_check check (
    status = any (
      array[
        'draft'::text,
        'queued'::text,
        'file_extraction'::text,
        'file_extracted'::text,
        'candidates_scoring'::text,
        'scored_initial'::text,
        'deep_analysis'::text,
        'deep_analysis_done'::text,
        'report_generation'::text,
        'completed'::text,
        'failed'::text
      ]
    )
  )
) tablespace pg_default;

create index if not exists idx_jobs_status
on public.jobs using btree (status);

create index if not exists idx_jobs_title
on public.jobs using btree (job_title);

create trigger update_jobs_updated_at
before update on jobs
for each row
execute function moddatetime();

create trigger set_created_by_trigger
before insert on jobs
for each row
execute function set_created_by();


-----------------------------------------
-- 3. FILES
-----------------------------------------
create table public.files (
  id uuid not null default gen_random_uuid(),
  job_id uuid null,
  file_name text not null,
  file_path text not null,
  file_size bigint null,
  cv_hash text null,
  extracted_text text null,
  content_type text null,
  status text null default 'queued'::text,
  extracting_finished_at timestamp with time zone null,
  uploaded_at timestamp with time zone null default now(),
  account_id uuid null,
  extracting_started_at timestamp with time zone null,
  constraint files_pkey primary key (id),
  constraint files_job_id_fkey foreign key (job_id) references jobs (id),
  constraint files_account_id_fkey foreign key (account_id) references accounts (id),
  constraint files_status_check check (
    status = any (
      array[
        'queued'::text,
        'text_extracting'::text,
        'text_extracted'::text,
        'scoring'::text,
        'scored'::text,
        'failed'::text,
        'skipped'::text,
        'needs_review'::text
      ]
    )
  )
) tablespace pg_default;


-----------------------------------------
-- 4. CANDIDATES
-----------------------------------------
create table public.candidates (
  id uuid not null default gen_random_uuid(),
  name text null,
  email text null,
  phone text null,
  candidate_level text null,
  level_basis text null,
  suitability_score smallint null,
  summary text null,
  skills_match text null,
  years_experience jsonb null,
  key_achievements text null,
  red_flags text null,
  job_id uuid null,
  account_id uuid null,
  file_id uuid null,
  created_by uuid null,
  status text null default 'new'::text,
  created_at timestamp with time zone null default (now() at time zone 'utc'::text),
  updated_at timestamp with time zone null default (now() at time zone 'utc'::text),
  extracted_title text null,
  initial_scores_model_used text null,
  analysis_scores_model_used text null,
  analysis_scores jsonb null,
  initial_scores jsonb null,
  constraint candidates_pkey primary key (id),
  constraint candidates_job_id_fkey foreign key (job_id) references jobs (id) on delete cascade,
  constraint candidates_account_id_fkey foreign key (account_id) references accounts (id) on delete cascade,
  constraint candidates_file_id_fkey foreign key (file_id) references files (id) on delete set null,
  constraint candidates_created_by_fkey foreign key (created_by) references auth.users (id) on delete set null,
  constraint candidates_status_check check (
    status = any (
      array[
        'scored'::text,
        'analysing'::text,
        'analysed'::text,
        'analysis_failed'::text
      ]
    )
  )
) tablespace pg_default;

create index if not exists idx_candidates_job_id on public.candidates using btree (job_id);
create index if not exists idx_candidates_account_id on public.candidates using btree (account_id);
create index if not exists idx_candidates_email on public.candidates using btree (email);
create index if not exists idx_candidates_status on public.candidates using btree (status);
create index if not exists idx_candidates_created_by on public.candidates using btree (created_by);

create trigger update_candidates_updated_at
before update on candidates
for each row
execute function moddatetime('updated_at');


-----------------------------------------
-- 5. REPORTS
-----------------------------------------
create table public.reports (
  id uuid not null default gen_random_uuid(),
  job_id uuid null,
  report_url text null,
  status text null default 'draft'::text,
  report_generated_at timestamp with time zone null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  account_id uuid null,
  transaction_ref text null,
  constraint reports_pkey primary key (id),
  constraint reports_job_id_fkey foreign key (job_id) references jobs (id) on delete cascade,
  constraint reports_account_id_fkey foreign key (account_id) references accounts (id),
  constraint reports_status_check check (
    status = any (
      array[
        'pending'::text,
        'in_progress'::text,
        'ready'::text,
        'failed'::text
      ]
    )
  )
) tablespace pg_default;


-----------------------------------------
-- 6. ERROR LOGS
-----------------------------------------
create table public.error_logs (
  id uuid not null default gen_random_uuid(),
  workflow_name text not null,
  workflow_id text null,
  execution_id bigint null,
  job_id uuid null,
  file_id uuid null,
  candidate_id uuid null,
  last_node_executed text null,
  error_message text not null,
  error_stack text null,
  created_at timestamp with time zone not null default now(),
  resolved boolean not null default false,
  constraint error_logs_pkey primary key (id),
  constraint error_logs_job_id_fkey foreign key (job_id) references jobs (id) on delete set null,
  constraint error_logs_file_id_fkey foreign key (file_id) references files (id) on delete set null,
  constraint error_logs_candidate_id_fkey foreign key (candidate_id) references candidates (id) on delete set null
) tablespace pg_default;


-----------------------------------------
-- 7. WORKFLOW LOGS
-----------------------------------------
create table public.workflow_logs (
  id uuid not null default gen_random_uuid(),
  workflow_name text not null,
  run_id uuid null default gen_random_uuid(),
  job_id uuid null,
  status text not null,
  message text null,
  error_details text null,
  started_at timestamp with time zone null default now(),
  ended_at timestamp with time zone null,
  duration_ms integer generated always as (
    extract(epoch from (ended_at - started_at)) * 1000
  ) stored null,
  created_at timestamp with time zone null default now(),
  constraint workflow_logs_pkey primary key (id),
  constraint workflow_logs_job_id_fkey foreign key (job_id) references jobs (id) on delete set null,
  constraint workflow_logs_status_check check (
    status = any (array['started'::text, 'completed'::text, 'error'::text])
  )
) tablespace pg_default;
