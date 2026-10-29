# REBS Workspace

An offline-capable employee workspace for the REBS HRMS Flutter assignment:
geofenced check-in and check-out, an offline sync queue that never loses or
duplicates attendance, a month calendar, and leave with a two-step apply
flow.

## Setup

### Requirements

- Flutter **3.47.8** (stable channel), Dart 3.13
- Xcode for iOS, the Android SDK for Android
- Platforms: Android and iOS

### 1. Install packages (once)

```bash
flutter pub get
(cd mock_server && dart pub get)
```

### 2. Start the mock API

From the project root:

```bash
dart run mock_server/bin/server.dart
```

It listens on all interfaces, port **3001** by default, and prints the URLs
and scenario names. Choose another port with the `PORT` variable:

```bash
PORT=8080 dart run mock_server/bin/server.dart
```

### 3. Point the app at it (changing the base URL)

The API base URL is set per flavour, in one place each:

| Flavour | File | Field |
|---|---|---|
| `dev` | `lib/app/config/dev_config.dart` | `apiBaseUrl` |
| `prod` | `lib/app/config/prod_config.dart` | `apiBaseUrl` |

To change it:

1. Open the flavour's config file and edit `apiBaseUrl`. Use the server's
   root URL with no trailing slash and no path:

   ```dart
   const devConfig = AppConfig(
     environment: Environment.dev,
     appName: 'REBS Dev',
     apiBaseUrl: 'http://localhost:3001',
     // ...
   );
   ```

2. Stop the app and run it again (or hot restart). The config is read once
   at start-up, so hot reload doesn't pick up a new URL.

   ```bash
   flutter run --flavor dev
   ```

3. Check it took effect: long-press the avatar on Today to open
   **Developer settings**; the **API** row shows the URL in use.

Which URL to use:

| Where the app runs | `apiBaseUrl` |
|---|---|
| iOS simulator | `http://localhost:3001` |
| Android emulator or USB device | `http://localhost:3001`, after `adb reverse tcp:3001 tcp:3001` (once per connection) |
| Phone on the same Wi-Fi | `http://<your computer's IP>:3001` (Android dev flavour; on iOS prefer a tunnel) |
| Phone anywhere | an HTTPS tunnel to port 3001, for example `ngrok http 3001` |

Things to know:

- **Plain `http://`** works on Android only in the dev flavour
  (`android/app/src/dev/AndroidManifest.xml` allows it); prod requires
  `https://`. iOS allows `http://` for local addresses such as
  `localhost`; use HTTPS (a tunnel) for anything else.
- **Port:** the mock server defaults to 3001. If you start it with
  `PORT=8080`, change the URL to match.
- There is no `--dart-define` for the URL; the config file is the only
  place it's set.

It currently points at an ngrok tunnel in both flavours; change it to
`http://localhost:3001` to use a local server.

### 4. Run

```bash
flutter run --flavor dev
```

### Run flags

| Flag | Values | Notes |
|---|---|---|
| `--flavor` | `dev`, `prod` | Required on Android and iOS. Plain `flutter run` uses `dev` (`default-flavor` in `pubspec.yaml`). |
| `--debug` / `--profile` / `--release` | | Any mode works with either flavour. |
| `-d <device>` | | Pick a simulator, emulator or phone. |
| `PORT` (mock server) | any free port | Defaults to 3001. |

There are no `--dart-define` values: everything that differs per flavour
(API URL, office location and radius, company timezone, app name) lives in
`lib/app/config/dev_config.dart` and `prod_config.dart`, and `main.dart`
picks one from `--flavor`. VS Code has a launch configuration for each
flavour and mode.

| | `dev` | `prod` |
|---|---|---|
| App name | REBS Dev | REBS Workspace |
| Android id | `com.example.rebs_hrms.dev` | `com.example.rebs_hrms` |
| iOS bundle id | `com.example.rebsHrms.dev` | `com.example.rebsHrms` |
| API (`apiBaseUrl`) | mock server | set in `prod_config.dart`; currently the same tunnel as dev |
| Developer settings (`isDevSettingsEnabled`) | Yes, long-press the avatar, in any build mode | No |
| "DEV" corner ribbon | Yes | No |
| Plain-HTTP API on Android | Allowed | HTTPS only |

### Build and check

```bash
flutter build apk --debug --flavor dev
dart format .
flutter analyze
flutter test
(cd mock_server && dart test)
```

## Architecture and state management

### Layers

Stacked MVVM, as the project's rules require:

- **Views** (`lib/ui/views/`) extend `StackedView` and only render
  ViewModel state. Screen-specific pieces live in `components/` as
  `ViewModelWidget`s.
- **ViewModels** hold all screen state and decisions, and talk only to
  services. No Flutter imports, no `BuildContext`.
- **Services** (`lib/services/`) own I/O: `ApiService` (the only HTTP
  code), `DatabaseService` (sqflite), `LocationService` (geolocator),
  `ConnectivityService`, `ClockService` (company timezone),
  `SyncService`, and one service per domain (`AttendanceService`,
  `LeaveService`, `OutboxService`, `EmployeeService`).
- **Policies** (`lib/policies/`) are pure Dart rules with no I/O:
  `AttendancePolicy`, `GeofencePolicy`, `LeavePolicy`. They're registered
  in the locator like services and are the easiest place to read or test
  the business rules.
- **Shared widgets** (`lib/ui/widgets/common/`) are presentational. The
  few with explicit animation controllers (slider, success tick, sync
  spinner, location pulse) keep only animation state.

Storage is **sqflite**. Attendance, leave and the employee are cached as the
server's JSON. The **outbox** table is the source of truth for attendance
taken on this phone until the server confirms it.

### State management, and why

- **One owner per piece of data.** Services hold the app's state (today's
  attendance, the sync queue, leave) and notify listeners through
  `ListenableServiceMixin`. ViewModels extend `ReactiveViewModel`, list the
  services they depend on, and rebuild when any of them changes. The sync
  pill, for example, reads `SyncService.summary` on every tab, so all three
  agree without passing data around.
- **ViewModels derive, they don't copy.** Labels, flags and lists are
  getters computed from service state, so there is no second copy to keep
  in sync.
- **States are sealed classes.** `TodayStatus`, `LocationCheck`,
  `SyncSummary` and `AttendanceOutcome` are sealed, so every `switch` over
  them is checked by the compiler and a new state can't be forgotten in a
  screen.
- **Busy and error state** use Stacked's `setBusy`/`setError`; screens show
  cached data with a banner instead of a spinner whenever a cache exists.
- **Why Stacked over BLoC or Riverpod:** it was the project's mandated
  architecture, and it keeps every decision in a plain ViewModel that unit
  tests drive with mocked services. Almost all of the 200 tests are
  ViewModel, service and policy tests; only two are widget tests.

## UX decisions

1. **Show eligibility before the action.** The Today card reads the
   location as soon as it opens ("You're at the office · 42 m" or "850 m
   away"), so people learn they can't check in before trying.
2. **One deliberate gesture.** Check-in and check-out are slide-to-confirm:
   a pocket tap can't trigger it, a double slide can't send it twice, and
   with a screen reader it becomes a button.
3. **Sync is always visible, never in the way.** A pill in every tab header
   shows Synced, "1 waiting", Syncing or Needs attention, and opens the
   queue with Sync now. No separate Sync tab.
4. **Say exactly what happened.** After each action a sheet confirms the
   time and either "Synced with REBS" or "Saved on this phone". A rejected
   event explains why and what to do.
5. **Offline is a normal state.** Cached screens load instantly with the
   time they're from. Only leave submission needs a connection, and its
   disabled button says so.
6. **Prevent leave errors before reporting them.** The range calendar
   blocks past dates and shows existing requests; the balance left is
   shown live; field errors appear only after a field is touched, and
   server errors land on the field they concern.
7. **Accessible by default.** Status is always an icon plus a word;
   buttons and chips have 48 dp tap targets (calendar days are about 44 dp
   on a 360 dp phone); layouts hold at 130% text on 360 dp phones; every
   animation turns off with the system reduce-motion setting.

## Event identity and idempotency

Every check-in or check-out gets a UUID v4 `eventId` the moment the slide
completes. It is written to the outbox before any network call and never
regenerated.

- The request carries `Idempotency-Key: <eventId>`. If the server already
  processed that ID it returns the original record (200, `replayed: true`)
  instead of applying it again.
- A timeout after the server committed (the `timeout_after_commit`
  scenario) leaves the event pending; the retry sends the same ID and the
  server still holds one record. Required test 2 covers both halves.
- A unique index `(work_date, type) WHERE status != 'REJECTED'` makes the
  database itself refuse a second check-in for a day, so two fast slides
  can't both be stored. `AttendanceService` also runs actions one at a
  time.
- `SyncService` sends events in `seq` order, one sync at a time, and stops
  at the first event that stays pending, so a check-out never overtakes its
  check-in. Retryable failures back off (5 s, 10 s, 20 s … 5 min). It runs
  on start-up, resume, reconnect, pull to refresh, "Sync now" and when a
  backoff expires. Events left "sending" by a killed app go back to pending
  at start-up.
- 409 or 422 marks the event rejected with the server's reason; the person
  can dismiss it from the sync sheet.

Leave requests are **not** queued: the server checks balance and overlap at
submission time, so the person sees its answer immediately. Offline, Apply
and Submit are disabled and say "Needs a connection". Because leave submit
has no idempotency key, a timeout tells the person the request may have been
saved and to check before trying again.

## Checks the server must repeat

The app checks everything below for a fast answer, but a real server must
not trust it:

- **Attendance:** one check-in and one check-out per company work date;
  check-out only after check-in; distance from the office within the radius
  using the server's office location; position accuracy limit; event time
  not in the future and in the claimed work date (company timezone);
  idempotency on `eventId`.
- **Leave:** start date not before the company's today; end not before
  start; days within the type's available balance (counting pending
  requests on hold); no overlap with pending or approved requests; reason of
  at least 10 non-whitespace characters; company-specific rules such as
  blackout periods.

## Simulating location and mock scenarios

In the dev flavour (any build mode, including the release APK), long-press
the avatar on Today to open **Developer settings**. Whether a flavour has
them is the `isDevSettingsEnabled` field in its config:

- **Location presets:** use device GPS, at the office (0 m), near the edge
  (190 m), outside (850 m), GPS unavailable, permission denied, permission
  blocked.
- **Mock API scenario:** `success`, `slow` (4 s responses),
  `timeout_after_commit`, `server_error` (500 on every call),
  `attendance_conflict` (409 on the next check-in), `leave_rejected` (422
  blackout on otherwise valid leave). "Reset mock data" restores the seed.
- **Clear today's attendance:** removes today's check-in and check-out on
  the phone and on the mock server (`POST /__mock/clear_today`), so the
  check-in flow can be tried again without resetting everything else.

The scenario can also be set without the app:

```bash
curl -X POST localhost:3001/__mock/scenario -H 'content-type: application/json' -d '{"name":"timeout_after_commit"}'
```

The office, radius and timezone come from the server's employee record;
the values in `dev_config.dart` are only used before it first loads.

## Assumptions

- One employee and one office, served by `GET /employee/me`. No login (out
  of the brief's scope).
- The working day is the company's calendar date in its timezone, not the
  phone's.
- One check-in and one check-out per day; no breaks or overtime.
- Leave days are calendar days; weekends and holidays aren't excluded.
- Pending requests hold balance, so the form validates against what's
  really left.

## Limitations

- One employee and one office; no login.
- Leave days are calendar days; weekends and holidays aren't excluded.
- Leave requests aren't queued offline (by design, see above).
- Release builds are signed with the debug key.
- iOS still has CocoaPods integration although every plugin is now a Swift
  package.



## Time spent

_To be filled in by the author._

## AI tools used

Claude Code (Anthropic) was used throughout: to analyse the brief, draft the
screen and architecture plans, write code and tests stage by stage against
`TODO.md`, and run the format, analyze and test checks after each stage.

_Add how you reviewed and changed its output._
