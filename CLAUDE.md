# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (desktop)
flutter run -d macos

# Run the app (web)
flutter run -d chrome

# Build
flutter build macos
flutter build web

# Analyze / lint
flutter analyze

# Format
dart format lib/

# Run with env vars
flutter run --dart-define-from-file=.env
```

The app requires a `.env` file at the root with `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Always pass `--dart-define-from-file=.env` when running.

There are no automated tests in this codebase.

## Architecture

### Tech Stack
- **Flutter** (Dart) — multi-platform: macOS desktop, web, iOS
- **Supabase** — Postgres DB, Auth, RLS policies, Edge Functions, Realtime

### Multi-platform shell
`main.dart` detects platform and routes to one of two shells:
- `DesktopShell` (`lib/app/shells/desktop_shell.dart`) — sidebar nav for macOS/web desktop
- `MobileShellProfessional` — tab-based nav for iOS/mobile web

Client users always go to `ClientDashboardPage`; all other roles go to the projects/missions landing.

### Role system
Four roles: `associe`, `partenaire`, `client`, `admin` (defined in `lib/models/user_role.dart`).
Role is stored in `profiles.role` and cached in `SupabaseService`. It drives route guards, sidebar items (`lib/widgets/side_menu.dart`), and what data each service query returns.

### Service layer
All Supabase calls live in `lib/services/`. `SupabaseService` (`supabase_service.dart`) is the central singleton — holds the client, handles auth, and contains most direct DB queries. Domain-specific services (`mission_service.dart`, `timesheet_service.dart`, `invoice_service.dart`, etc.) call `SupabaseService.client` directly.

**Fallback pattern**: many service methods try an RPC first, then a direct table query by `partner_id`, then by `assigned_to`, and log each attempt. If you see cascading debug prints, this is intentional degradation. Avoid adding new "last resort" fallbacks that ignore the user filter — that leaks data across users.

### Data models
`lib/models/` — plain Dart classes with `fromJson` factories. `Mission` is the central model; `timesheet_models.dart` contains `CalendarDay`, `TimesheetEntry`, `MonthlyStats`.

### Design system
`lib/config/app_theme.dart` — single source of truth for colors, typography, spacing, shadows, and the `ThemeData`. Always use `AppTheme.*` constants instead of hard-coded values. Key palette: primary `#16283C`, secondary `#3E5C76`, success `#2E7D5B`, warning `#B07B2E`.

### Pages vs Features
`lib/pages/` contains the routed screen widgets. `lib/features/` mirrors some of these as standalone modules — both coexist; prefer `lib/pages/` for navigation targets.

### Supabase / DB
Migrations are in `supabase/migrations/` in timestamp order. The initial schema (`20260709100000_initial_schema.sql`) defines all tables, views (`mission_with_context`), and RPC functions. Later migrations patch RLS and messaging visibility.

Key RPC functions used from Dart:
- `get_available_missions_for_timesheet(p_partner_id, p_date)` — missions assigned to a user active on a date
- `get_missions_by_partner(p_partner_id)` — all missions for a partner

Edge function `admin-create-user` handles server-side user creation (requires `service_role`).
