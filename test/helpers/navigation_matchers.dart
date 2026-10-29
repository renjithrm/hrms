import 'package:mockito/mockito.dart';
import 'package:stacked_services/stacked_services.dart';

/// Verifies a `replaceWith` call to [route], whatever the extra arguments.
void verifyReplacedWith(NavigationService navigation, String route) {
  verify(
    navigation.replaceWith<dynamic>(
      route,
      arguments: anyNamed('arguments'),
      id: anyNamed('id'),
      preventDuplicates: true,
      parameters: anyNamed('parameters'),
      transition: anyNamed('transition'),
    ),
  ).called(1);
}

/// Verifies there was no `replaceWith` call to [route].
void verifyNeverReplacedWith(NavigationService navigation, String route) {
  verifyNever(
    navigation.replaceWith<dynamic>(
      route,
      arguments: anyNamed('arguments'),
      id: anyNamed('id'),
      preventDuplicates: true,
      parameters: anyNamed('parameters'),
      transition: anyNamed('transition'),
    ),
  );
}

/// Verifies a `navigateTo` call to [route], whatever the extra arguments.
void verifyNavigatedTo(NavigationService navigation, String route) {
  verify(
    navigation.navigateTo<dynamic>(
      route,
      arguments: anyNamed('arguments'),
      id: anyNamed('id'),
      preventDuplicates: true,
      parameters: anyNamed('parameters'),
      transition: anyNamed('transition'),
    ),
  ).called(1);
}
