-----------------------------------------
-- VIEWS
-----------------------------------------


---------------------------------------------
-- 1. JOBS READY FOR FILE EXTRACTION (QUEUED)
---------------------------------------------
create view public.view_jobs_ready_for_file_extraction as
select
  jobs.id,
  jobs.job_ref,
  jobs.job_title,
  jobs.employment_type,
  jobs.location,
  jobs.description,
  jobs.cv_folder,
  jobs.status,
  jobs.account_id,
  jobs.created_at,
  jobs.updated_at,
  jobs.created_by
from
  jobs
where
  jobs.status = 'queued'::text
order by
  jobs.created_at
limit
  4;


---------------------------------------------
-- 1. JOBS CARDS FOR FE
---------------------------------------------
create view public.job_cards_view as
select
  j.id as job_id,
  j.job_title,
  j.job_ref,
  j.location,
  j.employment_type,
  j.status,
  j.created_at,
  count(distinct f.id) as total_files,
  count(distinct c.id) as total_candidates,
  max(r.report_url) as report_url,
  bool_or(r.status = 'completed'::text) as has_report
from
  jobs j
  left join files f on f.job_id = j.id
  left join candidates c on c.job_id = j.id
  left join reports r on r.job_id = j.id
group by
  j.id,
  j.job_title,
  j.status,
  j.created_at;