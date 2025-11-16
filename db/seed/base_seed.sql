-----------------------------------------
-- BASE SEED DATA
-- Runs in all environments
-----------------------------------------

-- Create an admin record if needed.
-- This is safe because it uses "on conflict do nothing".
insert into accounts (id, name, email, role, created_at)
values (
  uuid_generate_v4(),
  'System Administrator',
  'admin@example.com',
  'admin',
  now()
)
on conflict (email) do nothing;
