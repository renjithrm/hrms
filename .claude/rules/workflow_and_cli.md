# ⚡ Mandatory Workflow, CLI Commands & Quality Gates

> Operational rules, CLI workflow, package management, pre-commit checklists, and quality assurance gates.

---

## 1. Stacked CLI Commands Reference

Use `stacked_cli` for creating views, services, dialogs, and bottom sheets to maintain project consistency.

```bash
# Feature generation commands
stacked create view <name>           # Creates view + viewmodel pair and updates app.dart
stacked create service <name>        # Creates service and registers it in app.locator.dart
stacked create dialog <name>         # Creates dialog and updates app.dialogs.dart
stacked create bottom_sheet <name>   # Creates bottom sheet and updates app.bottomsheets.dart

# Build code generator (CRITICAL after modifying app.dart)
stacked generate                     # Regenerates app.router.dart, app.locator.dart, etc.
```

### Auto-Generated Files — NEVER EDIT MANUALLY
- `lib/app/app.router.dart`
- `lib/app/app.locator.dart`
- `lib/app/app.dialogs.dart`
- `lib/app/app.bottomsheets.dart`
- `*.form.dart`
- `lib/ui/common/locale_keys.gen.dart`

---

## 2. Approved Package Ecosystem

| Category | Recommended / Approved Packages |
|----------|---------------------------------|
| Architecture Core | `stacked`, `stacked_services`, `stacked_cli`, `get_it` |
| Networking | `http`, `retry` |
| Models & JSON | `freezed`, `json_serializable`, `json_annotation` |
| Storage | `shared_preferences`, `flutter_secure_storage` |
| Authentication | `firebase_auth`, `google_sign_in` |
| UI & Visuals | `flutter_screenutil`, `cached_network_image`, `shimmer`, `skeletonizer` |
| Analytics & Monitoring | `firebase_analytics`, `firebase_crashlytics` |
| Native Utilities | `permission_handler`, `device_info_plus`, `package_info_plus`, `path_provider` |
| Testing & Mocks | `mockito`, `build_runner` |
| Linting | `flutter_lints` |

---

## 3. Mandatory 4-Step Development Workflow

### RULE 1 — Ask Before You Act
Ask for clarification when:
- Requirements are ambiguous or underspecified.
- Key files needed for feature context are missing.
- Reusing an existing model/widget versus building a new one is uncertain.
- Platform-specific implementation trade-offs exist.

### RULE 2 — Implementation Plan First
Create an implementation plan detailing:
1. Understood requirements.
2. Target files to read, create, or modify.
3. Logical implementation steps.
4. CLI commands to run (`stacked generate`, `flutter pub add`).

### RULE 3 — Code Generation Standards
1. Include full file path as a top comment.
2. Provide **complete, production-ready code** — zero placeholders or empty methods.
3. List required iOS (`Info.plist`, `Podfile`) and Android (`AndroidManifest.xml`, `build.gradle`) edits.
4. Remind to run `stacked generate` if `lib/app/app.dart` was edited.

### RULE 4 — Pre-Commit Code Review Checklist
Check the following before concluding any turn:
- [ ] Views extend `StackedView<VM>` (never `StatefulWidget`).
- [ ] No direct `Navigator.push` in Views (use `NavigationService`).
- [ ] No `locator<X>()` calls inside UI Widgets/Views (move to ViewModel).
- [ ] No `http` or API calls inside ViewModels or Views (move to Service).
- [ ] No stored `BuildContext` inside ViewModel fields.
- [ ] Colors use `Palette` class (`lib/constants/app_colors.dart`).
- [ ] Typography uses `AppTextStyle` (`lib/tools/app_text_style.dart`).
- [ ] Static strings use `AppStrings` / `LocaleKeys.tr()`.
- [ ] All public methods and fields have doc comments (`///`).
- [ ] No deprecated APIs used (e.g. `withOpacity` → `withValues`). See [code_style_and_dart.md](./code_style_and_dart.md#no-deprecated-apis).

### RULE 5 — Git: No Unrequested Branches or Commits
Leave all git state changes to the user unless they explicitly ask for them in the current request:
- ❌ **Never create a branch** (or a worktree) on your own. Work on the branch that is already checked out.
- ❌ **Never commit** changes on your own — not after finishing a task, not after the acceptance checks pass. Leave changes uncommitted for the user to review.
- ❌ **Never merge, rebase, push, or stash** without an explicit instruction.
- ✅ An ambiguous reply (e.g. "implement it", "go ahead", "ok") is **not** permission to commit or branch. Ask if unsure.
- ✅ Permission covers only the action asked for, in the repository named, for that request; it does not carry over to later changes or to another repository.

---

## 4. Common Agent Pitfalls & Corrections

| Pitfall | Mandatory Correction |
|---------|----------------------|
| Putting logic in View | Move all state and logic to ViewModel. View only calls `viewModel.method()`. |
| Using `Navigator.push` | Use `_navigationService.navigateToXView()`. |
| Forgetting `stacked generate` | Run `stacked generate` immediately after editing `lib/app/app.dart`. |
| Editing generated files | Modify `lib/app/app.dart` and run `stacked generate`. |
| Using `StatefulWidget` for View | Extend `StackedView<VM>`. |
| Storing `BuildContext` in VM | Pass `BuildContext` at method execution time only if mandatory. |
| Committing or branching unasked | Leave changes uncommitted on the current branch; only commit, branch, merge or push when the user explicitly says so. |
| Hardcoding display strings | Define in `AppStrings` or `assets/translations/*.json`. |
| Swallowing errors | Call `setError(e)` and log to Crashlytics or remote monitoring. |

---

## 5. Quality Assurance Acceptance Criteria

Every feature or bugfix must pass all three validation gates clean before marking work as complete:

```bash
dart format .           # Must have ZERO formatting warnings
flutter analyze         # ZERO errors, ZERO warnings, ZERO deprecated_member_use infos
flutter test            # Must have 100% passing tests
```
