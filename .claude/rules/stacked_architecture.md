# 🏗️ Stacked MVVM Architecture — Rules & Best Practices

> Comprehensive reference for Stacked MVVM architecture conventions in Flutter applications.

---

## 1. Overview & Layer Separation

Every feature in the application is split into **three distinct layers**. Never cross responsibilities between these layers.

```
┌─────────────────────────────────────────────────────┐
│  VIEW  (lib/ui/views/<feature>/<feature>_view.dart) │
│  → Dumb UI renderer. Reads from ViewModel. No logic.│
├─────────────────────────────────────────────────────┤
│  VIEWMODEL  (<feature>_viewmodel.dart)              │
│  → All business logic, state, navigation, calls.   │
│  → Calls Services. Never talks to API directly.    │
├─────────────────────────────────────────────────────┤
│  SERVICE  (lib/services/<name>_service.dart)        │
│  → Raw API calls, data persistence, device access. │
│  → No UI, no navigation, no ViewModel imports.     │
└─────────────────────────────────────────────────────┘
```

---

## 2. View Rules (`lib/ui/views/<feature>/<feature>_view.dart`)

### Core Purpose
Views render the user interface based strictly on state provided by the ViewModel. They delegate all user interactions back to the ViewModel.

### Class Declaration
- Views **MUST** extend `StackedView<MyViewModel>`.
- **NEVER** extend `StatefulWidget` or `StatelessWidget` directly for screen views.

### Lifecycle Hooks & Structure
```dart
class MyFeatureView extends StackedView<MyFeatureViewModel> {
  const MyFeatureView({Key? key}) : super(key: key);

  @override
  void onViewModelReady(MyFeatureViewModel viewModel) {
    viewModel.init();
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(
    BuildContext context,
    MyFeatureViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(viewModel.title)),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : _ContentSection(),
    );
  }

  @override
  MyFeatureViewModel viewModelBuilder(BuildContext context) =>
      MyFeatureViewModel();
}
```

### Sub-Widgets in View Files
For screen-specific sub-widgets, extend `ViewModelWidget<MyViewModel>`:

```dart
class _ContentSection extends ViewModelWidget<MyFeatureViewModel> {
  const _ContentSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, MyFeatureViewModel viewModel) {
    return Text(viewModel.someValue);
  }
}
```

### Strict Forbidden List for Views
- ❌ **No direct API or HTTP calls**: Views must never import `http` or call APIs.
- ❌ **No `Navigator.push` / `Navigator.pop`**: All navigation is performed by `NavigationService` via the ViewModel.
- ❌ **No Service Instantiation**: Views must never use `locator<SomeService>()`.
- ❌ **No Raw Storage Access**: Views must never touch `SharedPreferences`, `FlutterSecureStorage`, or local databases.
- ❌ **No Conditional Business Logic**: Complex `if/else` evaluations belong in the ViewModel.

---

## 3. ViewModel Rules (`<feature>_viewmodel.dart`)

### Core Purpose
ViewModels manage presentation state, trigger asynchronous operations via services, handle navigation decisions, and react to business events.

### ViewModel Base Classes

| ViewModel Type | Use Case | Implementation Key |
|----------------|----------|--------------------|
| `BaseViewModel` | Standard screens with manual async triggers | General state management |
| `FutureViewModel<T>` | Single async load on screen initialization | Override `Future<T> get futureToRun` |
| `ReactiveViewModel` | Reacts automatically to updates in registered services | Override `List<ListenableServiceMixin> get listenableServices` |
| `StreamViewModel<T>` | Listens to a continuous `Stream<T>` | Override `Stream<T> get stream` |
| `IndexTrackingViewModel` | Bottom navigation bars & multi-tab navigation | Call `setIndex(index)` to switch tabs |

### State Management Methods

```dart
setBusy(true);                  // Indicates global loading state
setBusy(false);                 // Clears loading state
setBusyForObject(object, true); // Sets granular loading for a specific object/key
setError(error);                // Sets global error object on ViewModel
clearErrors();                  // Resets error state
notifyListeners();              // Manually triggers UI rebuild
runBusyFuture(future);          // Wraps a Future call with setBusy automatically
```

### Correct ViewModel Pattern
```dart
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../models/order_model.dart';
import '../../../services/api_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/session_service.dart';

class OrderListViewModel extends ReactiveViewModel {
  final _apiService = locator<ApiService>();
  final _sessionService = locator<SessionService>();
  final _cartService = locator<CartService>();
  final _navigationService = locator<NavigationService>();

  List<OrderModel> orders = [];
  bool get isLoggedIn => _sessionService.currentUser?.isLoggedIn ?? false;

  Future<void> init() async {
    setBusy(true);
    try {
      orders = await runBusyFuture(_apiService.getOrders());
      clearErrors();
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  Future<void> reorder(OrderModel order) async {
    await _cartService.addOrderToCart(order);
    notifyListeners();
  }

  void goToCart() => _navigationService.navigateToCartView();

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_cartService, _sessionService];
}
```

### Strict Forbidden List for ViewModels
- ❌ **No Flutter UI Imports**: Never import `package:flutter/material.dart` or `package:flutter/widgets.dart` in ViewModels. ViewModels must be pure Dart.
- ❌ **No Stored `BuildContext`**: Never store `BuildContext` in a ViewModel variable. Pass it briefly at call-time only if mandatory (e.g. `easy_localization` runtime switching).
- ❌ **No Direct HTTP Calls**: ViewModels interact only with Services.
- ❌ **No Direct Navigation Operations via `Navigator`**: Always use `NavigationService`.

---

## 4. Service Rules (`lib/services/<name>_service.dart`)

### Core Purpose
Services are singletons registered in GetIt (`locator`) that handle domain-specific operations: REST API endpoints, secure storage, device hardware, authentication state, or cart state.

### Creating Services via Stacked CLI
```bash
stacked create service <name>
```

### Reactive Service Pattern
Services that notify ViewModels of state changes must use `ListenableServiceMixin`:

```dart
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import 'api_service.dart';

class CartService with ListenableServiceMixin {
  final _apiService = locator<ApiService>();

  int _itemCount = 0;
  int get itemCount => _itemCount;

  CartService() {
    listenToReactiveValues([() => _itemCount]);
  }

  Future<void> refreshCart() async {
    _itemCount = await _apiService.getCartItemCount();
    notifyListeners();
  }
}
```

### Standard Service Domains

| Service Name | Primary Responsibility |
|--------------|------------------------|
| `ApiService` | Single source of truth for all HTTP API interactions |
| `SessionService` / `AuthService` | User session token management, login state, profile state |
| `CartService` | Shopping cart items, counts, discount calculations |
| `CacheService` | Storage encapsulation (`SharedPreferences`, `FlutterSecureStorage`) |
| `NotificationService` | Push notification setup (FCM, APNs) and payload routing |
| `NavigationParamService` | Passing non-string objects safely between screens |
| `ConnectivityService` | Network connectivity status monitoring |

### Strict Forbidden List for Services
- ❌ **No UI Widgets or Dialogs**: Services never render UI or call `showDialog()`.
- ❌ **No ViewModel References**: Services never import or instantiate ViewModels.
- ❌ **No Navigation Calls**: Services handle data and state, leaving navigation to ViewModels.

---

## 5. Architecture Enforcement Rules

1. **File Locations**:
   - UI Views: `lib/ui/views/<feature>/<feature>_view.dart`
   - ViewModels: `lib/ui/views/<feature>/<feature>_viewmodel.dart`
   - Services: `lib/services/<name>_service.dart`
   - Models: `lib/models/<name>.dart`
2. **Dependency Injection**: Use `locator<ServiceName>()` — **NEVER** manually instantiate services (`ApiService()`).
3. **Stacked Generator**: Run `stacked generate` immediately after updating `lib/app/app.dart`.
4. **Never Edit Auto-Generated Files**:
   - `lib/app/app.locator.dart`
   - `lib/app/app.router.dart`
   - `lib/app/app.dialogs.dart`
   - `lib/app/app.bottomsheets.dart`
   - `*.form.dart`
