# DeskFlow — V1, fully wired

Business Operations Desktop Platform (Flutter Windows + Supabase).

## Honest scope note

Every feature below is implemented with real logic against real Supabase
calls — there are no `onPressed: () {}` stubs, no hardcoded "—" numbers,
and no TODO placeholders left in the code. That said: this sandbox has
**no internet access and no Flutter SDK installed**, so nothing here has
been compiled or run against a live Supabase project. "Fully wired" means
the code is complete and internally consistent, not "tested end-to-end."
The setup steps below are exactly what's needed to actually run it.

## What's real in this version (not demo)

- **Auth & org creation** — sign up, email-confirmation handling (Supabase
  requires this by default), first-run "Create Organization" flow, and a
  root router that sends a confirmed-but-orgless user back to finish
  setup instead of dead-ending them.
- **Projects** — create dialog actually inserts a row and reloads the grid.
- **Kanban board** — drag-and-drop updates `status` in Postgres, synced
  live to every connected client via Supabase Realtime.
- **Tasks** — creating a task with an assignee actually sends that person
  an in-app notification and writes an Activity Log entry. Real assignee
  picker pulled from your org's member list (not a fixed dropdown).
- **Team / Invite employee** — calls a real Supabase Edge Function
  (`supabase/functions/invite-user`) that creates the auth user
  server-side (the service-role key needed for that can never live in
  the client app) and inserts their profile with the chosen role.
- **Documents** — real file picker, real upload to Supabase Storage,
  real signed download URLs, real Activity Log entry on upload.
- **Activity Log & Dashboard feed** — actor names are resolved from a
  real org-member lookup, not hardcoded "Someone".
- **Notification bell** — actually rendered in the top bar, loads
  existing notifications, updates live via Realtime, shows unread count.
- **Reports** — completed/in-progress/overdue counts and per-person
  completed-task totals are computed from real `tasks` rows, not a
  fixed 82%.
- **Multi-tenant RLS** — every table's policies key off `organization_id`
  resolved from the caller's own profile, so Company B's queries simply
  never return Company A's rows, enforced by Postgres itself.

## Project layout

```
deskflow/
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql   ← tables, RLS, realtime publication
│   │   └── 002_storage.sql          ← "documents" bucket + storage RLS
│   └── functions/
│       └── invite-user/index.ts     ← Edge Function, real user creation
└── flutter_app/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart                 root router (session + profile check)
        ├── core/                     constants, theme
        ├── models/                   Profile, Project, Task, ActivityItem,
        │                             NotificationItem, AppDocument
        ├── services/                 AuthService, ProjectService, TaskService,
        │                             ActivityService, NotificationService,
        │                             MemberService, DocumentService
        ├── screens/                  auth, dashboard, projects, tasks (Kanban),
        │                             team, documents, activity, reports
        └── widgets/                  AppShell, NotificationBell, StatCard,
                                       TaskCard, KanbanColumn
```

## How to actually run this

1. **Create a Supabase project**, then in the SQL editor run, in order:
   `supabase/migrations/001_initial_schema.sql`, then
   `supabase/migrations/002_storage.sql`.

2. **Deploy the Edge Function** (needed for "Invite employee" to work):
   ```
   supabase functions deploy invite-user
   ```
   No extra config needed — `SUPABASE_SERVICE_ROLE_KEY` is provided to
   Edge Functions automatically by Supabase.

3. **Fill in your credentials** in `flutter_app/lib/core/constants.dart`
   (`SupabaseConfig.url` / `.anonKey`, from Project Settings → API).

4. **Generate the native Windows runner.** This scaffold ships the
   Dart/`lib/` source only — the native `windows/` folder is generated
   by the Flutter SDK and can't be produced without it. From
   `flutter_app/`:
   ```
   flutter create --platforms=windows .
   flutter pub get
   flutter run -d windows
   ```

5. Open the app, click **"First time here? Create your organization"**,
   fill it in — that account becomes the org's Admin. Everything else
   (projects, tasks, team invites, documents, reports) works from there.

## Still genuinely out of scope for V1 (per the design review)

- Native OS / system-tray push notifications (needs a background
  service — in-app notifications only, deferred to V2).
- Offline mode / local caching + sync (deferred to V2).
- Dynamic/custom permissions beyond the 3 fixed roles (deferred to V2).
- Billing/Stripe integration — flagged as an open question, not yet designed.
- The marketing website (`deskflow.app`) — separate project.
