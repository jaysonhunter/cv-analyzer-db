-----------------------------------------
-- ENABLE RLS
-----------------------------------------
alter table accounts enable row level security;
alter table jobs enable row level security;
alter table files enable row level security;
alter table candidates enable row level security;
alter table reports enable row level security;

-----------------------------------------
-- HELPER INLINE ADMIN CHECK (expanded inside each policy)
-----------------------------------------
-- is_admin is checked inline inside policies:
-- exists (
--   select 1 from accounts a
--   where a.id = auth.uid() and a.role = 'admin'
-- )


-----------------------------------------
-- ACCOUNTS
-----------------------------------------
create policy accounts_select_policy
on accounts for select
using (
  id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy accounts_update_policy
on accounts for update
using (
  id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

-- No insert or delete on accounts from the client. Only via backend.


-----------------------------------------
-- JOBS
-----------------------------------------
create policy jobs_select_policy
on jobs for select
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy jobs_insert_policy
on jobs for insert
with check (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy jobs_update_policy
on jobs for update
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);


-----------------------------------------
-- FILES
-----------------------------------------
create policy files_select_policy
on files for select
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy files_insert_policy
on files for insert
with check (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy files_update_policy
on files for update
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);


-----------------------------------------
-- CANDIDATES
-----------------------------------------
create policy candidates_select_policy
on candidates for select
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy candidates_insert_policy
on candidates for insert
with check (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy candidates_update_policy
on candidates for update
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);


-----------------------------------------
-- REPORTS
-----------------------------------------
create policy reports_select_policy
on reports for select
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy reports_insert_policy
on reports for insert
with check (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

create policy reports_update_policy
on reports for update
using (
  account_id = auth.uid()
  or exists (select 1 from accounts a where a.id = auth.uid() and a.role = 'admin')
);

