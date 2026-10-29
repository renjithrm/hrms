# 🎨 UI, Design System & Asset Management Rules

> Guidelines for shared widgets, design system tokens (colors, typography, strings), performance optimizations, and localization.

---

## 1. Widget Organization & Reuse Standards

### Shared Widgets (`lib/ui/widgets/`)
Any widget reused across **2 or more views** MUST be placed in `lib/ui/widgets/`.

#### Rules for Shared Widgets:
- ✅ **Pure Presentation**: Pass data and event callbacks (`VoidCallback`, `Function(T)`) as parameters.
- ✅ **Stateless**: Extend `StatelessWidget` for pure visual elements.
- ❌ **No Service Instantiation**: Never use `locator<SomeService>()` inside shared widgets.
- ❌ **No Direct Navigation**: Shared widgets never call `NavigationService` or `Navigator`.
- ❌ **No Business Logic**: Shared widgets receive parsed models or primitives.

### Mandated Shared Widgets
Before building custom interactive chrome, always reach for the existing shared widgets:

| Widget | File | Usage |
|--------|------|-------|
| `AppBackButton` | `lib/ui/widgets/app_back_button.dart` | **All** screen nav-bar back buttons. Pass `onPressed: viewModel.onBackPressed`. Never roll a custom `InkWell` + `Icon` back button. |

```dart
// ✅ Correct
AppBackButton(onPressed: viewModel.onBackPressed)

// ❌ Incorrect — custom back button
InkWell(onTap: viewModel.onBackPressed, child: Icon(Icons.arrow_back_ios_new_rounded))
```

### View Components (`lib/ui/views/<feature>/components/`)
Sub-widgets specific to a single view belong in a `components/` subdirectory inside that feature folder.

#### Rules for View Components:
- Extend `ViewModelWidget<MyViewModel>` to access ViewModel state cleanly without parameter drilling.

```dart
class OrderSummaryComponent extends ViewModelWidget<CheckoutViewModel> {
  const OrderSummaryComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, CheckoutViewModel viewModel) {
    return Column(
      children: [
        Text(viewModel.orderTotal),
        Text(viewModel.deliveryEstimate),
      ],
    );
  }
}
```

---

## 2. Design System Tokens

### Colors & Palette (`lib/constants/app_colors.dart`)
- **Mandatory Rule**: All UI colors must be referenced from `Palette` in `lib/constants/app_colors.dart`.
- **Adding Colors**: If a required color or gradient does not exist in `Palette`, add it as a `static const Color` or `static const LinearGradient` inside `Palette` first.
- ❌ **No Inline Hex Colors**: `Color(0xFF123456)` directly inside view widgets is strictly forbidden.

```dart
// ✅ Correct
Container(color: Palette.primaryColor)

// ❌ Incorrect
Container(color: const Color(0xFF0066CC))
```

### Typography (`lib/tools/app_text_style.dart`)
- **Mandatory Rule**: All text styles must originate from `AppTextStyle` in `lib/tools/app_text_style.dart`.
- **Modifying Styles**: Use `.copyWith()` on existing `AppTextStyle` constants to change color, height, or font size.
- ❌ **No Inline `TextStyle(...)`**: Creating `TextStyle()` objects from scratch in UI views is strictly forbidden.

```dart
// ✅ Correct
Text(
  viewModel.title,
  style: AppTextStyle.headingBold.copyWith(color: Palette.textPrimary),
)

// ❌ Incorrect
Text(
  viewModel.title,
  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
)
```

### Static Text Strings (`lib/constants/app_strings.dart`)
- **Mandatory Rule**: All fixed string constants must be defined in `AppStrings` in `lib/constants/app_strings.dart`.
- Check `AppStrings` before adding a new string to avoid duplicates.
- ❌ **No Hardcoded Raw String Literals**: Never hardcode inline UI strings like `Text('Submit')`.

---

## 3. Localization (`easy_localization`)

Application translations use `easy_localization` with JSON translation files located in `assets/translations/`.

### Process for Adding New Localized Keys

1. **Step 1: Add key to ALL translation JSON files**:
   - `assets/translations/en.json`
   - `assets/translations/ar.json`
   ```json
   "cartTitle": "My Shopping Cart"
   ```
2. **Step 2: Generate locale keys**:
   ```bash
   flutter pub run easy_localization:generate \
     -S assets/translations \
     -O lib/ui/common \
     -o locale_keys.gen.dart \
     -f keys
   ```
3. **Step 3: Access in Flutter UI**:
   ```dart
   Text(LocaleKeys.cartTitle.tr())
   Text(LocaleKeys.itemCount.tr(args: ['5']))
   ```

> ⚠️ **CRITICAL**: Never manually edit `lib/ui/common/locale_keys.gen.dart`. Always regenerate via CLI.

---

## 4. Performance & Image Optimization

### Image Optimization Rules
- Use `CachedNetworkImage` for all remote network images.
- Provide `const` loading placeholders (`Shimmer`) and error fallback widgets.

```dart
CachedNetworkImage(
  imageUrl: viewModel.imageUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => const ShimmerPlaceholderWidget(),
  errorWidget: (context, url, error) => const ImageFallbackWidget(),
)
```

> ⚠️ **Cached Network Image Aspect-Ratio Warning**:
> Avoid passing **both** `memCacheWidth` and `memCacheHeight` to `CachedNetworkImage` simultaneously if the target display aspect ratio differs from the raw image. Specify only width OR height to avoid distortion.

### List Performance
- Always use `ListView.builder` or `GridView.builder` for dynamic or lengthy lists to ensure lazy element building. Never use `ListView(children: items.map(...).toList())`.
