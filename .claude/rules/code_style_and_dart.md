# 🔤 Code Style, Naming Conventions & Dart Best Practices

> Guidelines for writing clean, maintainable, and idiomatic Dart & Flutter code.

---

## 1. Naming Conventions

Strict, enforced conventions across all files and Dart code symbols.

### Identifier Naming Table

| Type | Convention | Example |
|------|-----------|---------|
| Classes, Enums, Typedefs, Mixins, Extensions | `UpperCamelCase` | `UserProfileViewModel`, `OrderStatus` |
| Variables, Parameters, Named Constructors | `lowerCamelCase` | `isLoading`, `userName` |
| Private Instance Variables / Functions | `_lowerCamelCase` | `_apiService`, `_currentUser` |
| Constants (`const`) | `lowerCamelCase` | `const defaultTimeout = 30` |
| Enum Values | `lowerCamelCase` | `OrderStatus.inProgress` |
| Source Files, Directories, Packages | `snake_case` | `user_profile_view.dart`, `auth_service.dart` |

> **Acronym Rule**: Treat acronyms as words.
> Use `HttpRequest` (not `HTTPRequest`), `userId` (not `userID`), `ApiService` (not `APIService`), `UrlHelper` (not `URLHelper`).

### File Naming Conventions
```
✅ lib/ui/views/user_profile/user_profile_view.dart
✅ lib/services/authentication_service.dart
❌ lib/ui/views/user_profile/UserProfileView.dart (PascalCase file - forbidden)
❌ lib/services/authSvc.dart (Abbreviated name - forbidden)
```

### One Public Class Per File Rule
Each Dart file must define at most **one public top-level class**. Additional private helper classes (`_PrivateHelper`) are allowed in the same file.

```dart
// ✅ Correct
class UserCard extends StatelessWidget { ... }
class _UserCardState { ... } // Private helper class is allowed

// ❌ Incorrect - Move AddressCard to address_card.dart
class UserCard extends StatelessWidget { ... }
class AddressCard extends StatelessWidget { ... }
```

### Prefix / Suffix Conventions
```dart
// Booleans: Always use is/has/can/should prefix
bool isLoading = false;
bool hasError = false;
bool canSubmit = true;
bool shouldRefresh = false;

// Methods: Always start with an active verb
void loadUserProfile() { ... }
Future<void> submitOrder() { ... }
void navigateToCart() { ... }

// Reactive Streams: Use $ suffix
Stream<User> get user$ => _userController.stream;
```

---

## 2. Formatting & Line Length Rules

### Formatting Tools
- Run `dart format .` to format all Dart files (80-character column limit).
- Run `flutter analyze` — code must pass with **zero warnings and zero errors**.

### Import Ordering
Group imports into 4 distinct blocks separated by blank lines in this exact order:

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party package imports
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stacked/stacked.dart';

// 4. Relative application imports
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import 'home_viewmodel.dart';
```

### Trailing Commas & Const Discipline
Always add trailing commas for multi-line argument lists to maintain clean multi-line formatting upon `dart format`:

```dart
// ✅ Correct: Trailing commas retain readable formatting
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(viewModel.title),
    const SizedBox(height: 8),
  ],
);

// ✅ Correct: Use const whenever possible to prevent unnecessary subtree rebuilds
const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
```

---

## 3. Dart 3+ Features & Best Practices

### Null Safety Strict Discipline
- Avoid non-null assertions (`!`) unless non-nullability is mathematically guaranteed. Prefer `?.`, `??`, or explicit null checks (`if (val != null)`).
- Use `late` only when initialization is deferred but guaranteed before first read.

```dart
// ✅ Safe null handling
final displayName = user?.profile?.name ?? 'Guest';

// ❌ Risky null assertion
final displayName = user!.profile!.name;
```

### Explicit Type Annotations
- Always specify return types and parameter types for public APIs and methods.
- Avoid using `dynamic`. Use explicit types, generics, or `Object?`.

```dart
// ✅ Explicit types
Future<List<UserModel>> fetchUsers(String query) async { ... }

// ❌ Uninferred or dynamic types
fetchUsers(query) async { ... }
```

### No Deprecated APIs

**Mandatory Rule**: Never use an API marked `@Deprecated` — not in `lib/`, not in `test/`. `flutter analyze` must report **zero `deprecated_member_use` infos**, not just zero errors and warnings. Deprecation infos are treated as build failures for the acceptance gate.

- When adding code, use the current replacement API named in the deprecation message.
- When touching a file that already contains a deprecated call, migrate it in the same change.
- If a third-party package forces a deprecated call with no supported replacement, add a targeted `// ignore: deprecated_member_use` on that single line **plus a comment naming the package and why**. Never blanket-ignore the rule in `analysis_options.yaml`.

Migrations already applied in this codebase — use the right-hand column:

| Deprecated | Replacement | Notes |
|---|---|---|
| `color.withOpacity(0.5)` | `color.withValues(alpha: 0.5)` | Avoids precision loss. Applies to `Palette` aliases and `AppShadows`. |
| `color.value`, `color.red/green/blue` | `color.toARGB32()`, `color.r/.g/.b` | Channel getters return normalized doubles. |
| `tester.binding.window` | `tester.view` / `tester.platformDispatcher` | Widget & golden tests. |
| `window.devicePixelRatioTestValue = x` | `tester.view.devicePixelRatio = x` | Reset with `addTearDown(tester.view.reset)` when needed. |
| `MediaQuery.of(context).size` | `MediaQuery.sizeOf(context)` | Also `.paddingOf`, `.viewInsetsOf` — rebuilds less. |
| `RaisedButton` / `FlatButton` / `OutlineButton` | `ElevatedButton` / `TextButton` / `OutlinedButton` | Use the shared widgets in `lib/ui/widgets/` first. |

```dart
// ✅ Correct
static final Color textPrimary = black.withValues(alpha: 0.9);

// ❌ Incorrect — deprecated, fails the acceptance gate
static final Color textPrimary = black.withOpacity(0.9);
```

> ⚠️ Do not silence a deprecation by pinning an older package version. Migrate the call site.

### Pattern Matching & Sealed Classes (Dart 3+)
Use sealed class hierarchies for exhaustive state modeling:

```dart
sealed class ResultState<T> {}
class ResultData<T> extends ResultState<T> { final T data; ResultData(this.data); }
class ResultError<T> extends ResultState<T> { final String message; ResultError(this.message); }
class ResultLoading<T> extends ResultState<T> {}

// In View or ViewModel:
switch (state) {
  case ResultData(:final data) => _showContent(data),
  case ResultError(:final message) => _showError(message),
  case ResultLoading() => _showSpinner(),
}
```

### Extension Methods
Place pure utility extension methods in `lib/extensions/` to keep core code DRY:

```dart
// lib/extensions/string_extensions.dart
extension StringExtensions on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
}
```

---

## 4. Deep Nesting & Refactoring Guidelines

### Avoiding Widget Pyramids
If widget nesting exceeds **3 levels**, extract nested subtrees into separate `ViewModelWidget<VM>` components or helper classes:

```dart
// ❌ Deep Nesting (Pyramid of Doom)
Container(
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        Column(
          children: [
            Text(viewModel.userName),
          ],
        )
      ],
    ),
  ),
);

// ✅ Clean Decomposition
class UserHeaderCard extends ViewModelWidget<UserProfileViewModel> {
  const UserHeaderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, UserProfileViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _UserDetailRow(),
    );
  }
}
```
