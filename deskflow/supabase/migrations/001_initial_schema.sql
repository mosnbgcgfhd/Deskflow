-- =========================================================
-- DeskFlow — Initial Schema (V1)
-- Multi-tenant B2B SaaS on Supabase / PostgreSQL
-- Decisions locked in during design review:
--   * Backend: Supabase (Postgres + RLS + Realtime + Auth + Storage)
--   * Roles: 3 FIXED roles only -> admin / manager / employee
--   * Realtime: enabled on tasks, projects, activity_log, notifications
--   * Notifications: in-app only in V1 (native OS push -> V2)
--   * Offline mode: NOT included in V1 (V2)
-- =========================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------
-- 1. Organizations (tenants)
-- ---------------------------------------------------------
create table organizations (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  created_at  timestamptz not null default now(),
  created_by  uuid not null references auth.users(id)
);

-- ---------------------------------------------------------
-- 2. Profiles (1:1 with auth.users, scoped to one organization)
--    A user belongs to exactly one organization in V1.
-- ---------------------------------------------------------
create type user_role as enum ('admin', 'manager', 'employee');
create type presence_status as enum ('online', 'away', 'offline');

create table profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  full_name       text not null,
  role            user_role not null default 'employee',
  title           text,                     -- e.g. "Backend Developer"
  presence        presence_status not null default 'offline',
  created_at      timestamptz not null default now()
);

create index idx_profiles_org on profiles(organization_id);

-- ---------------------------------------------------------
-- 3. Projects
-- ---------------------------------------------------------
create table projects (
  id              uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name            text not null,
  description     text,
  created_by      uuid not null references profiles(id),
  created_at      timestamptz not null default now()
);

create index idx_projects_org on projects(organization_id);

create table project_members (
  project_id uuid not null references projects(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  added_at   timestamptz not null default now(),
  primary key (project_id, profile_id)
);

-- ---------------------------------------------------------
-- 4. Tasks (Kanban)
-- ---------------------------------------------------------
create type task_status as enum ('todo', 'in_progress', 'in_review', 'done');
create type task_priority as enum ('low', 'medium', 'high');

create table tasks (
  id              uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  project_id      uuid not null references projects(id) on delete cascade,
  title           text not null,
  description     text,
  status          task_status not null default 'todo',
  priority        task_priority not null default 'medium',
  assigned_to     uuid references profiles(id),
  due_date        date,
  created_by      uuid not null references profiles(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_tasks_org on tasks(organization_id);
create index idx_tasks_project on tasks(project_id);
create index idx_tasks_assignee on tasks(assigned_to);

-- keep updated_at fresh (drives realtime "moved" events on the Kanban board)
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_tasks_updated_at
  before update on tasks
  for each row execute function set_updated_at();

-- ---------------------------------------------------------
-- 5. Documents
-- ---------------------------------------------------------
create table documents (
  id              uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  project_id      uuid not null references projects(id) on delete cascade,
  file_name       text not null,
  storage_path    text not null,   -- path inside the Supabase Storage bucket
  uploaded_by     uuid not null references profiles(id),
  uploaded_at     timestamptz not null default now()
);

create index idx_documents_project on documents(project_id);

-- ---------------------------------------------------------
-- 6. Activity Log (append-only, realtime feed)
-- ---------------------------------------------------------
create table activity_log (
  id              uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  actor_id        uuid not null references profiles(id),
  action          text not null,        -- e.g. "created_task", "uploaded_document"
  target_type     text not null,        -- e.g. "task", "project", "document"
  target_id       uuid,
  metadata        jsonb default '{}',   -- e.g. {"task_title": "API Authentication"}
  created_at      timestamptz not null default now()
);

create index idx_activity_org_time on activity_log(organization_id, created_at desc);

-- ---------------------------------------------------------
-- 7. Notifications (in-app only in V1)
-- ---------------------------------------------------------
create table notifications (
  id              uuid primary key default uuid_generate_v4(),
  organization_id uuid not null references organizations(id) on delete cascade,
  recipient_id    uuid not null references profiles(id) on delete cascade,
  title           text not null,
  body            text,
  read            boolean not null default false,
  created_at      timestamptz not null default now()
);

create index idx_notifications_recipient on notifications(recipient_id, read);

-- =========================================================
-- ROW LEVEL SECURITY
-- Core rule: a user can only ever see rows belonging to
-- their own organization_id. This is what enforces
-- "Company B never sees Company A's data".
-- =========================================================

create or replace function current_org_id() returns uuid as $$
  select organization_id from profiles where id = auth.uid();
$$ language sql stable security definer;

create or replace function current_role() returns user_role as $$
  select role from profiles where id = auth.uid();
$$ language sql stable security definer;

alter table organizations enable row level security;
alter table profiles enable row level security;
alter table projects enable row level security;
alter table project_members enable row level security;
alter table tasks enable row level security;
alter table documents enable row level security;
alter table activity_log enable row level security;
alter table notifications enable row level security;

-- organizations: members can read their own org row only
create policy org_select on organizations
  for select using (id = current_org_id());

-- profiles: everyone in the org can see teammates (needed for Team screen)
create policy profiles_select on profiles
  for select using (organization_id = current_org_id());

-- only admin can invite/remove/change roles
create policy profiles_admin_write on profiles
  for update using (organization_id = current_org_id() and current_role() = 'admin');
create policy profiles_admin_insert on profiles
  for insert with check (organization_id = current_org_id() and current_role() = 'admin');
create policy profiles_admin_delete on profiles
  for delete using (organization_id = current_org_id() and current_role() = 'admin');

-- projects: readable by org members, writable by admin + manager
create policy projects_select on projects
  for select using (organization_id = current_org_id());
create policy projects_write on projects
  for all using (organization_id = current_org_id() and current_role() in ('admin', 'manager'))
  with check (organization_id = current_org_id() and current_role() in ('admin', 'manager'));

-- project_members: readable by org members via join, writable by admin/manager
create policy project_members_select on project_members
  for select using (
    exists (select 1 from projects p where p.id = project_id and p.organization_id = current_org_id())
  );
create policy project_members_write on project_members
  for all using (
    current_role() in ('admin', 'manager')
    and exists (select 1 from projects p where p.id = project_id and p.organization_id = current_org_id())
  );

-- tasks: org members can read; write allowed if admin/manager,
-- OR employee editing a task assigned to them (status changes on the Kanban board)
create policy tasks_select on tasks
  for select using (organization_id = current_org_id());

create policy tasks_write_privileged on tasks
  for all using (organization_id = current_org_id() and current_role() in ('admin', 'manager'))
  with check (organization_id = current_org_id() and current_role() in ('admin', 'manager'));

create policy tasks_update_own on tasks
  for update using (organization_id = current_org_id() and assigned_to = auth.uid())
  with check (organization_id = current_org_id() and assigned_to = auth.uid());

-- documents: org members read; upload by any org member; delete by admin/manager or uploader
create policy documents_select on documents
  for select using (organization_id = current_org_id());
create policy documents_insert on documents
  for insert with check (organization_id = current_org_id());
create policy documents_delete on documents
  for delete using (
    organization_id = current_org_id()
    and (current_role() in ('admin', 'manager') or uploaded_by = auth.uid())
  );

-- activity_log: append-only, readable by org, insert by any org member (via service calls)
create policy activity_select on activity_log
  for select using (organization_id = current_org_id());
create policy activity_insert on activity_log
  for insert with check (organization_id = current_org_id());

-- notifications: a user only ever sees their own notifications
create policy notifications_select on notifications
  for select using (recipient_id = auth.uid());
create policy notifications_update_own on notifications
  for update using (recipient_id = auth.uid());
create policy notifications_insert on notifications
  for insert with check (organization_id = current_org_id());

-- =========================================================
-- REALTIME
-- Enable realtime replication on the tables that drive
-- live UI updates (Kanban board, Dashboard, Activity feed,
-- Notification bell).
-- =========================================================
alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table projects;
alter publication supabase_realtime add table activity_log;
alter publication supabase_realtime add table notifications;
