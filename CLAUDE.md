# Flutter + Stacked MVVM — Rules & Best Practices Master Index

> Senior Flutter developer guidelines specializing in Stacked MVVM architecture with deep iOS and Android native platform knowledge.

---

## 📚 Master Index of Guidelines & Rules

The project guidelines have been organized into focused, modular rule files in [`.claude/rules/`](.claude/rules/). Click any topic below to access the full rule documentation.

| Rule Document | Main Topics Covered | File Link |
|---------------|---------------------|-----------|
| **1. Stacked MVVM Architecture** | View (`StackedView`), ViewModel (`BaseViewModel`, `ReactiveViewModel`, `FutureViewModel`), Service (`ListenableServiceMixin`), locator DI rules, GetIt rules, lifecycle hooks. | [stacked_architecture.md](.claude/rules/stacked_architecture.md) |
| **2. Code Style & Dart Standards** | Naming conventions (`UpperCamelCase`, `lowerCamelCase`, acronym rules), file naming, 1-class-per-file rule, import ordering, `dart format`, const correctness, Dart 3+ sealed classes/pattern matching, extension methods, deep nesting guidelines. | [code_style_and_dart.md](.claude/rules/code_style_and_dart.md) |
| **3. UI, Design System & Localization** | Shared Widgets (`lib/ui/widgets/`) vs Components (`components/`), Theme Palette (`lib/constants/app_colors.dart`), Typography (`lib/ui/tools/app_text_style.dart`), Static Strings (`lib/constants/app_strings.dart`), `easy_localization` setup, `CachedNetworkImage` optimization & aspect-ratio cache rules. | [ui_and_design_system.md](.claude/rules/ui_and_design_system.md) |
| **4. Native iOS & Android Knowledge** | **iOS**: `Runner.xcworkspace`, `Info.plist` usage descriptions, `Podfile` setup, Privacy Manifest (`PrivacyInfo.xcprivacy`), APNs push notifications, Fastlane, Xcode 15 build script fixes.<br>**Android**: `build.gradle` (SDK targets 34/35, AGP namespace), `AndroidManifest.xml` permissions (Android 13+), ProGuard/R8 keep rules, Multidex, D8/R8 fixes.<br>**Cross-Platform**: `Platform.isIOS`, `defaultTargetPlatform`, `kIsWeb` guards. | [native_ios_android.md](.claude/rules/native_ios_android.md) |
| **5. Security, Testing & Error Handling** | Secret management (`--dart-define`, `flutter_dotenv`), `flutter_secure_storage` tokens, build obfuscation, custom exception domain classes (`lib/exceptions/`), ViewModel error handling (`setError`), ViewModel unit testing with `mockito` & test helpers. | [testing_and_security.md](.claude/rules/testing_and_security.md) |
| **6. Mandatory Workflow & CLI** | Stacked CLI commands (`stacked create`, `stacked generate`), generated file rules, approved package ecosystem, 4-step workflow (Ask, Plan, Code, Review), agent pitfalls & fixes, acceptance criteria (`dart format`, `flutter analyze`, `flutter test`). | [workflow_and_cli.md](.claude/rules/workflow_and_cli.md) |

---

---

## 📋 Product Specification

REBS HRMS Flutter assignment: an offline-capable employee workspace
(attendance with geofenced check-in/out, an offline sync queue, leave).

- Build order and status: [TODO.md](TODO.md)
- Screens and motion plan: https://claude.ai/artifact/3jVWykJaK296R7oXgyT4bK
- Stacked architecture: https://claude.ai/artifact/GNHWYJ2hD4HGRf3LmRrfLb
- Mock API: `mock_server/` (run `dart run bin/server.dart` inside it)

Project-specific additions to the rules:
- Business rules live in `lib/policies/` as pure Dart classes, registered in
  the locator like services.
- Local storage is `sqflite`; the outbox table is the source of truth for
  attendance taken on the device.
- Two flavours, `dev` (default) and `prod`: always pass `--flavor` when
  building. Per-flavour values live in `lib/app/config/{dev,prod}_config.dart`;
  code reads `AppConfig.current` (set by `bootstrap`), never `appFlavor` or
  `--dart-define`. Native setup: Android `productFlavors` in
  `android/app/build.gradle.kts` (+ `src/dev/AndroidManifest.xml`), iOS
  `<Config>-dev|prod` build configurations, `ios/Flutter/{dev,prod}.xcconfig`
  and the `dev`/`prod` schemes.

---

## 🚀 Core Architecture Overview (Quick Reference)

```
┌─────────────────────────────────────────────────────┐
│  VIEW  (lib/ui/views/<feature>/<feature>_view.dart) │
│  → Dumb UI renderer. Extends StackedView<VM>.       │
├─────────────────────────────────────────────────────┤
│  VIEWMODEL  (<feature>_viewmodel.dart)              │
│  → All business logic, state, navigation, calls.   │
│  → Extends BaseViewModel / ReactiveViewModel.      │
├─────────────────────────────────────────────────────┤
│  SERVICE  (lib/services/<name>_service.dart)        │
│  → Raw API calls, data persistence, device access. │
│  → Uses ListenableServiceMixin for state updates.   │
└─────────────────────────────────────────────────────┘
```

---

## 🎨 Design System Quick Rules

1. **Colors**: Always reference `Palette` in [`lib/constants/app_colors.dart`](lib/constants/app_colors.dart). Never hardcode inline hex colors.
2. **Typography**: Always reference `AppTextStyle` in [`lib/ui/tools/app_text_style.dart`](lib/ui/tools/app_text_style.dart). Use `.copyWith()` for inline overrides.
3. **Strings**: Always define constants in `AppStrings` in [`lib/constants/app_strings.dart`](lib/constants/app_strings.dart) or translation JSON files (`assets/translations/`).

---

## ⚡ Mandatory Acceptance Criteria

Before concluding any turn, all three checks must pass with zero issues:

```bash
dart format .           # Zero formatting issues
flutter analyze         # Zero errors, zero warnings, zero deprecation infos
flutter test            # 100% test pass rate
```

> ⚠️ **Do not launch/run the app** (simulator, emulator, `flutter run`, Chrome, etc.) to verify a change. These three commands are the acceptance bar — stop once they pass. Only run the app if the user explicitly asks to see it running.
