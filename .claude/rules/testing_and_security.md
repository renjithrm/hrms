# 🛡️🧪 Security, Testing & Error Handling Guidelines

> Protocols for environment security, exception handling architecture, and unit testing ViewModels.

---

## 1. Security Protocols

### Secret & Key Management
- **Never Hardcode Secrets**: API keys, credentials, and tokens must never be hardcoded in Dart source code.
- Use `--dart-define` or `flutter_dotenv` to inject environment configuration at compile time.
- **Git Safety**: Ensure `.env` files and signing keystores are listed in `.gitignore`.

### Sensitive Data Storage
- Store authentication tokens, refresh keys, and sensitive user credentials using `flutter_secure_storage` (backed by iOS Keychain and Android Keystore).
- **NEVER** store tokens, API keys, or raw credentials in `SharedPreferences`.

### Network & Build Hardening
- **HTTPS Only**: All network endpoints must use secure TLS (`https://`). Cleartext `http://` traffic is forbidden.
- **Release Build Obfuscation**: Always obfuscate production builds to protect reverse engineering:
  ```bash
  flutter build apk --obfuscate --split-debug-info=build/symbols
  flutter build appbundle --obfuscate --split-debug-info=build/symbols
  ```
- **Logging Hygiene**: Never log auth tokens, passwords, or PII (Personally Identifiable Information) in console output, even during debug sessions.

---

## 2. Error Handling & Exception Architecture

### Custom Exception Domain Classes (`lib/exceptions/`)
Define strongly-typed exceptions per domain to allow explicit handling:

```dart
// lib/exceptions/network_exception.dart
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  const NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message (HTTP $statusCode)';
}

// lib/exceptions/auth_exception.dart
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}
```

### ViewModel Error Management
ViewModels must capture exceptions cleanly, assign them to ViewModel error state via `setError(e)`, and log to Crashlytics or remote monitoring.

```dart
Future<void> loadProfileData() async {
  setBusy(true);
  try {
    _userProfile = await _apiService.getUserProfile();
    clearErrors();
  } catch (e, stackTrace) {
    setError(e);
    // Log to Crashlytics in production
    // locator<AnalyticsService>().logError(e, stackTrace);
  } finally {
    setBusy(false);
  }
  notifyListeners();
}
```

### Strict Forbidden List for Error Handling
- ❌ **No Empty Catch Blocks**: Catching an error and doing nothing (`try { ... } catch (_) {}`) is strictly forbidden.
- ❌ **No Swallowing Errors**: Always log or pass errors to ViewModel error state.

---

## 3. Testing Standards & Unit Test Pattern

### Directory Structure for Tests
```
test/
├── helpers/
│   └── test_helpers.dart          ← Registered mock services & GetIt setup
├── viewmodels/
│   └── home_viewmodel_test.dart   ← ViewModel unit tests
├── services/
│   └── api_service_test.dart     ← Service unit tests
└── models/
    └── user_model_test.dart       ← Model JSON serialization tests
```

### ViewModel Unit Test Pattern (with Mockito)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_helpers.dart';
import 'package:mynikah/ui/views/home/home_viewmodel.dart';
import 'package:mynikah/exceptions/network_exception.dart';

void main() {
  group('HomeViewModel Unit Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('init loads orders successfully and updates state', () async {
      // Arrange
      final mockApi = getAndRegisterApiService();
      when(mockApi.getOrders()).thenAnswer((_) async => []);

      // Act
      final vm = HomeViewModel();
      await vm.init();

      // Assert
      expect(vm.isBusy, false);
      expect(vm.hasError, false);
      expect(vm.orders, isEmpty);
      verify(mockApi.getOrders()).called(1);
    });

    test('init sets hasError true when API throws NetworkException', () async {
      // Arrange
      final mockApi = getAndRegisterApiService();
      when(mockApi.getOrders()).thenThrow(const NetworkException('Connection timeout'));

      // Act
      final vm = HomeViewModel();
      await vm.init();

      // Assert
      expect(vm.hasError, true);
      expect(vm.isBusy, false);
    });
  });
}
```

### Mandatory Testing Rules
- Every ViewModel **MUST** have unit tests covering initial load, happy path, and error path.
- Always test ViewModel state variables (`isBusy`, `hasError`, `modelError`, output properties).
- Test ViewModels directly — **do not attempt to unit test View widgets directly**. Views are declarative; ViewModels contain all business logic.
- Run `flutter test` to ensure 100% passing status before committing code.
