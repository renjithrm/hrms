# REBS HRMS — Screen-by-Screen TODO

Build order for the assignment, one screen at a time. Each screen lists the
services it needs, so the backend for a screen is built just before the screen.

- Screen letters (A–N) refer to the Employee Workspace plan:
  https://claude.ai/artifact/3jVWykJaK296R7oXgyT4bK
- Architecture (Stacked layers, services, schema):
  https://claude.ai/artifact/GNHWYJ2hD4HGRf3LmRrfLb
- Rules: `.claude/rules/` (Stacked MVVM, code style, UI tokens, testing).

**Done means, for every screen:** `dart format .`, `flutter analyze` (zero
issues, including deprecations) and `flutter test` all pass, and the
ViewModel has tests for initial load, happy path and error path. Animations
use `AppMotion` and turn off with the system reduce-motion setting (motion
plan: "Animations we will build" on the plan page).

**Decided:** local database is `sqflite`.
**Also adopted when implementation started:** `http` client; extra packages `geolocator`,
`connectivity_plus`, `uuid`, `timezone`, `intl`, `path`; cleartext HTTP in
debug builds only; one widget test as a rules exception; no
`easy_localization`; `lib/policies/` for business rules; local
`LoggerService` instead of Crashlytics.

---

## 0. Foundation (before any screen)

- [ ] Housekeeping (left for you: these change Git state or delete files)
  - [ ] `git init` and first commit (the brief asks for a Git repository)
  - [x] Rewrite `CLAUDE.md` for REBS (Sahayi paths and spec removed)
  - [ ] Remove copied Sahayi worktrees in `.claude/worktrees/`
  - [ ] Remove Sahayi entries from `.claude/settings.local.json`
  - [x] Delete template `home` view, `notice` sheet, `info_alert` dialog and their tests
- [x] Packages: sqflite, path, http, geolocator, connectivity_plus, uuid, timezone, intl, shared_preferences, skeletonizer; dev: sqflite_common_ffi. Removed the discontinued `golden_toolkit`.
- [x] Models are plain Dart classes with hand-written `fromJson`/`toJson` instead of freezed: fewer dependencies and no extra code generation for about a dozen small classes.
- [ ] Bundle fonts (Bricolage Grotesque, IBM Plex Sans) in `assets/fonts/` — deferred; `AppTextStyle` uses the system font until the font files are added
- [x] Design tokens
  - [x] `lib/constants/app_colors.dart` — `Palette`
  - [x] `lib/ui/tools/app_text_style.dart` — `AppTextStyle` (tabular figures for times)
  - [x] `lib/ui/theme/app_theme.dart` — Material 3 theme from the tokens
  - [x] `lib/constants/app_strings.dart` — `AppStrings`
  - [x] `lib/ui/theme/app_motion.dart` — `AppMotion`, zero durations when reduce motion is on
  - [x] `lib/ui/tools/ui_helpers.dart` — `Gap` spacing scale
- [x] `lib/app/config/` — per-flavour `AppConfig` (API URL, office lat/lng/radius, timezone), chosen from `--flavor`; fixed limits in `lib/constants/app_limits.dart`
- [x] Models in `lib/models/`: `Employee`, `OfficeLocation`, `Shift`, `AttendanceRecord`, `AttendanceEvent`, `AttendanceEventType`, `SyncState`, `GeoPosition`, `LeaveType`, `LeaveStatus`, `LeaveRequest`, `LeaveBalance`, `LeaveInput`, `AttendanceRuleViolation`, `GeofenceResult`, `LeaveRuleViolation`
- [x] Exceptions in `lib/exceptions/`: `ApiException` base, `OfflineException`, `RequestTimeoutException`, `ServerException`, `AttendanceConflictException`, `ValidationException`
- [x] Policies in `lib/policies/` (moved forward from stages 5, 6 and 10): `AttendancePolicy`, `GeofencePolicy`, `LeavePolicy`
  - [x] **Required test 1** (check-out without check-in) and **required test 4** (overlapping leave)
- [x] Core services, registered in `app.dart`
  - [x] `ClockService` — company today and work dates, fixed clock in tests
  - [x] `LoggerService` — debug logging, no PII
  - [x] `DatabaseService` — `InitializableSingleton`, schema v1, `outbox_one_per_day` unique index, injectable path
  - [x] `ApiService` — injected `http.Client`, 8 s timeout, `Idempotency-Key`, status → exception mapping
  - [x] `ConnectivityService` — `isOnline`, offline → online events
  - [x] `AppLifecycleService` — `resumed$` stream
- [x] Mock server `mock_server/` (own pubspec, `shelf` + `shelf_router`)
  - [x] Seed data relative to today: employee, office, shift, attendance since the start of last month, balances, 5 leave requests
  - [x] All 6 endpoints plus `/__mock/scenario` and `/__mock/reset`
  - [x] Idempotent `POST /attendance/events`; server computes the work date and re-checks every rule
  - [x] Scenarios: `success`, `slow`, `timeout_after_commit`, `server_error`, `attendance_conflict`, `leave_rejected`
  - [x] 12 tests (`dart test` inside `mock_server/`)
  - Note: the app sets the scenario through `POST /__mock/scenario` instead of an `X-Mock-Scenario` header, so the server holds one active scenario.
- [x] Shared widgets — built in stages 3 and 4 (`AppBackButton`, `StatusChip`, `SyncPill`, `StateView`, `StaleDataBanner`, `BalanceMeter`)
- [x] Test helpers: mocks for every service in `test/helpers/test_helpers.dart`, `openTestDatabase()` FFI helper (`ClockService(now:)` replaces a separate fake clock)
- [x] Debug-only cleartext HTTP (Android debug manifest) and iOS `NSAllowsLocalNetworking`

## 1. Startup

- [x] `StartupView` / `StartupViewModel`
  - [x] `EmployeeService`: cache first (sqflite), then network; applies the server's timezone to `ClockService`
  - [x] With a cache: open `MainView` at once and refresh in the background, so the app starts offline
  - [x] First launch with no cache: wait for the API; on failure show the error and "Try again"
  - [x] Starts connectivity, lifecycle and developer settings
- [x] `ErrorMessageExtension` turns any caught error into an `AppStrings` message
- [x] Tests: open from cache, background refresh failure, first launch online, first launch offline; `EmployeeService` cache and refresh
- Login: not built, as the brief puts it out of scope; the README will say so

## 2. Main shell (tab bar)

- [x] `stacked create view main`
- [x] `MainViewModel` extends `IndexTrackingViewModel`
- [x] Three tabs in an `IndexedStack`: Today, Attendance, Leave (each shows `StagePlaceholder` until its stage; delete that widget after stage 9)
- [x] Material 3 `NavigationBar`; its pill indicator animates between tabs and uses `Palette.brandSoft`
- [x] Tests: starts on Today, tab switching

## 3. Developer settings — screen N

- [x] `DevSettingsService` — preset and scenario in shared preferences, `activePreset` used by `LocationService` in stage 5, inert in release (`kDebugMode`)
- [x] `DevSettingsView` with `AppBackButton` (`lib/ui/widgets/app_back_button.dart`)
- [x] Location presets: device GPS, at office (0 m), near edge (190 m), outside (850 m), GPS unavailable, permission denied, permission blocked
- [x] Scenario selector calling `POST /__mock/scenario`; reads the server's real scenario when opened
- [x] "Reset mock data" button
- [x] Shows office coordinates, timezone and API URL
- [x] Error banner explaining how to start the mock API when it is down
- [x] Opened by long-pressing the avatar on Today (debug builds only)
- [x] Tests: preset persists, release builds ignore presets, scenario sent and remembered only on success, reset, ViewModel errors

## 4. Today, read-only — screens A and M

- [x] `TodayView` / `TodayViewModel` (`ReactiveViewModel` over employee, attendance, leave and connectivity)
- [x] Header band component: avatar (long-press opens developer settings in debug builds), greeting, name, ID · department, `SyncPill`
- [x] `OutboxService` (read side): active events for given dates, dates with unsynced events
- [x] `AttendanceService` (read side): today and the latest five days, merged from the server cache and the outbox; fetches last month too early in a month; per-event sync state for the cloud icons
- [x] `LeaveService` (read side): balances and requests cached in sqflite
- [x] `DatabaseService.readTimestamp` / `writeTimestamp` for "Showing data from 17:40"
- [x] Models: `AttendanceDay`, `TodayStatus` (not checked in, checked in, checked out), `SyncSummary` (synced, offline, waiting n, syncing, needs attention)
- [x] Today card: date, status chip, shift line with timezone; check-in/out times with synced or waiting icons; body switches with `AnimatedSwitcher` (fade + size)
- [x] Leave balance card with `BalanceMeter` bars that fill on first show
- [x] Recent attendance list (latest five) with Synced / Waiting chips
- [x] States: `skeletonizer` shimmer on first load, full error with "Try again" when nothing is cached, banner over cached data when offline or a refresh failed, empty recent list
- [x] Pull to refresh
- [x] Shared widgets: `StatusChip`, `StatusTone`, `SyncPill` (crossfade, spinning icon only while syncing), `StateView`, `StaleDataBanner`, `BalanceMeter`
- [x] Tests: attendance merge (pending check-in, server wins, rejected ignored, last month, offline cache), leave cache, Today loaded / refresh failed with cache / first load failed / offline / waiting check-in / formatting / developer settings
- [x] `SyncPill` tap opens the sync sheet — stage 7

## 5. Location eligibility — screens E and F

- [x] `LocationService` — geolocator wrapper (injectable `GeolocatorPlatform`), 10 s limit, permission and location-service states, simulated presets from `DevSettingsService` in debug builds
- [x] `GeofencePolicy` in `lib/policies/` + tests (199 m inside, 201 m outside, accuracy limit)
- [x] Models: `LocationReading` (fix or unreadable), `LocationFailure`, `LocationCheck` (checking, inside, outside, imprecise, blocked)
- [x] `LocationStatusTile` widget: green inside, red outside, blue checking, amber for permission problems; radar pulse only while checking (stops with reduce motion)
- [x] Outside state (E): distance, 200 m limit, schematic `GeofenceMap` (offline, drawn to scale), "Update my location"
- [x] Location read on open (asks for permission once), every 30 s while Today is open, and on app resume; skipped once the day is complete
- [x] `LocationPermissionSheet` (F): one variant per failure — Allow location, Open settings (with steps), Open location settings, Try again — and "Not now"
- [x] Native: Android fine/coarse location + network state permissions; iOS `NSLocationWhenInUseUsageDescription`
- [x] Tests: real-GPS paths via `FakeGeolocator` (allowed, service off, denied once, denied forever, timeout), presets, Today tile states, help sheet, permission re-ask, finished day; sheet model actions
- [x] Locked slider and its shake — moved to stage 6, where the slider is built

## 6. Check-in and check-out — screens A, B and C

- [x] `AttendancePolicy` in `lib/policies/` + **required test 1** (check-out without check-in rejected)
- [x] `OutboxService` — enqueue in a transaction, next pending, status updates, reset stuck `SYNCING` on start (called from `StartupViewModel`)
- [x] `AttendanceService.checkIn()` / `checkOut()` — location → policies → enqueue → request sync. Until stage 7 it sends the day's pending events itself, in order, stopping at the first that stays pending; `SyncService` takes that over
- [x] **Required test 2 (part 1):** two concurrent `checkIn()` calls create one outbox row
- [x] `SlideToConfirm` widget: fires once per completed drag, spring snap-back when released early, knob morphs arrow → spinner → check, locks while submitting, haptic click at 90% and on commit, accessible button fallback
- [x] Widget test for `SlideToConfirm`: full drag fires once, short drag fires nothing
- [x] Slider locked unless `LocationInside`; tapping the locked slider shakes it (400 ms `TweenSequence`) with a light haptic
- [x] Checked-in state (B): `ShiftRing` (`CustomPainter` arc; sweeps in over 900 ms, eases 400 ms when the minute changes) with elapsed time (1 s timer in the ViewModel, cancelled on dispose), check-out slider
- [x] Checked-out state
- [x] `stacked create bottom_sheet attendance_result` (C): time, place, "Synced with REBS" or "Saved on this phone", success tick scales in and draws (450 + 400 ms), light haptic, auto-close after 4 s
- [x] Tests: slide → result sheet shown, policy violation shown, location failure opens the permission sheet

## 7. Sync — screens D and G

- [x] `SyncService` (registered by hand in `app.dart`: the CLI would have overwritten the file); it took over sending from `AttendanceService`, which now calls `syncNow(ignoreBackoff: true)` after each check-in or check-out
  - [x] Single-flight lock
  - [x] Send in `seq` order; stop at the first event that stays pending
  - [x] Check-out waits for its check-in
  - [x] 201 or 200 replay → synced; 409 or 422 → rejected with a plain-language reason; timeout, 5xx or offline → pending with backoff
  - [x] Triggers: app start, resume, reconnect, pull to refresh, Sync now
  - [x] `SyncSummary` sealed class for the pill
- [x] **Required test 2 (part 2):** timeout after server commit, retry with same ID, server holds one record
- [x] **Required test 3:** enqueue offline, close database, reopen, sync, order is check-in then check-out
- [x] Offline Today state (D): waiting chip, per-event cloud icons, offline banner text
- [x] `stacked create bottom_sheet sync_queue` (G): timeline, rejected explanation, dismiss, Sync now, long-press shows event ID; status nodes change through `AnimatedSwitcher` one row at a time, dismissed rows collapse via `AnimatedList` (300 ms)
- [x] **Required widget test:** Today shows "1 waiting" and the Waiting chip with one pending event (pump with `disableAnimations: true` so `pumpAndSettle` doesn't wait on the sync icon)
- [x] Tests: pill states, Sync now disabled while syncing, dismiss rejected event

## 8. Attendance month — screen H

- [x] `stacked create view attendance` (the view already existed from stage 2's tab shell)
- [x] Month fetch and cache (`GET /attendance?month=`), months viewed stay available offline
- [x] `CalendarDay` model and month grid component: present, waiting, leave, weekend, today
- [x] Previous and next month, selected day detail card
- [x] Summary: days present, average day
- [x] Accessible list view toggle; the header also carries the sync pill
- [x] Tests: month change, offline month from cache, empty month

## 9. Leave overview — screen I

- [x] `stacked create view leave` (the view already existed from stage 2's tab shell)
- [x] `LeaveService` read side: balances (available and on hold), requests cached for offline (built in stage 4)
- [x] Balance cards
- [x] Status filter chips: All, Pending, Approved, Rejected
- [x] Request list with reviewer note on rejected items
- [x] "Apply for leave" button, disabled offline with "Needs a connection"; the header also carries the sync pill
- [x] Tests: filters, offline disables apply, cached list shown offline

## 10. Apply leave, step 1 — screen J

- [x] `LeavePolicy` in `lib/policies/` + **required test 4** (overlapping dates rejected), plus start before today, end before start, reason length, over balance
- [x] `stacked create view apply_leave` (created in stage 9 so the Apply button has a route); step 2 shows a placeholder until stage 11
- [x] Leave type cards with available days
- [x] `LeaveRangeCalendar` widget: starts at company today, shows pending and approved requests, range selection; day cells animate (150 ms) and the validation message expands with `AnimatedSize` (200 ms)
- [x] Inline overlap and balance errors (overlap shown first); Continue disabled while invalid; "left after this" under a valid range
- [x] Tests: each rule shows the right message, valid range enables Continue

## 11. Apply leave, step 2 — screen K

- [x] Step change from J to K slides horizontally with a fade (250 ms), reversed when going back
- [x] Review summary: type, dates, days, balance after
- [x] Reason field with live count; error only after the field is touched, revealed with `AnimatedSize` + fade (180 ms)
- [x] `LeaveService.submit()` — online only; 422 field errors mapped to the form; the new request is cached first and balances refresh in the background. Until stage 12, success returns to the Leave tab
- [x] Server error banner; dates highlighted; reason kept
- [x] Tests: submit success, 422 mapped to fields, offline blocked, timeout message (warns the request may have been saved, since leave submit isn't idempotent)

## 12. Leave submitted — screen L

- [x] `stacked create view leave_submitted` with a `LeaveRequest` argument
- [x] Send badge scales in (the success tick is now the shared `SuccessTick` widget, used by the result sheet too)
- [x] Summary card and new balance (updates when the background refresh lands); new request appears first in the list as Pending. Submitting replaces the form with this screen, so back lands on Leave
- [x] Tests: back navigation returns to the Leave tab

## 13. Wrap-up

- [ ] Run every mock scenario by hand against each screen — the API side of every scenario was checked with curl on a separate server (201, replay 200, 8 s timeout then replay, 500, 409, 422 blackout); checking each screen in the app is left for you
- [x] Check layouts at 360 dp width and 130% text size — a temporary widget test rendered every screen and sheet; fixed overflows in the Today header and shift line, the review summary and the submitted summary
- [x] Turn on the system reduce-motion setting and check every animation stops or becomes instant — same check with `disableAnimations`; `AnimatedSize` asserted at zero duration, so it is wrapped in `MotionSize`
- [x] If time is short, cut decorative motion first: location pulse, locked-slider shake, balance bar fill, step slide — not needed, all kept
- [x] Android cleartext (dev flavour only); iOS `NSAllowsLocalNetworking`; `PrivacyInfo.xcprivacy` (precise location for app functionality, UserDefaults CA92.1) in the Runner target
- [x] README: setup, architecture, UX decisions, idempotency approach, server-side checks, location simulation, assumptions, limitations, time spent, AI tools used — time spent and how AI output was reviewed are left for you to fill in
- [x] `flutter build apk --debug --flavor dev` → `build/app/outputs/flutter-apk/app-dev-debug.apk`
- [ ] Record the 3–5 minute demo video (script on the plan page) — left for you
