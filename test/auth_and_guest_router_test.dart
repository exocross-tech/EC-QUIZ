import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizapp/features/auth/domain/app_user.dart';
import 'package:quizapp/features/auth/presentation/auth_controller.dart';
import 'package:quizapp/core/routing/app_router.dart';

void main() {
  group('AppUser Model & copyWith Tests', () {
    test('AppUser initializes with correct values and defaults', () {
      const user = AppUser(uid: 'user_123', email: 'test@example.com', displayName: 'Player 1');
      expect(user.uid, 'user_123');
      expect(user.id, 'user_123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Player 1');
      expect(user.isAnonymous, isFalse);
    });

    test('AppUser copyWith updates specified fields while keeping others unchanged', () {
      const user = AppUser(
        uid: 'guest_999',
        displayName: 'OldName',
        isAnonymous: true,
      );

      final updated = user.copyWith(displayName: 'NewName');
      expect(updated.uid, 'guest_999');
      expect(updated.displayName, 'NewName');
      expect(updated.isAnonymous, isTrue);
      expect(updated.email, isNull);
    });

    test('AppUser equality compares based on uid', () {
      const u1 = AppUser(uid: 'same_uid', displayName: 'Alice');
      const u2 = AppUser(uid: 'same_uid', displayName: 'Bob');
      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
    });
  });

  group('Guest & RouterNotifier Reactivity Tests', () {
    test('GuestUserNotifier sets and clears guest user cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(guestUserProvider), isNull);
      expect(container.read(effectiveUserProvider), isNull);

      const guest = AppUser(uid: 'guest_101', displayName: 'SpeedyGuest', isAnonymous: true);
      container.read(guestUserProvider.notifier).setGuest(guest);

      expect(container.read(guestUserProvider), equals(guest));
      expect(container.read(effectiveUserProvider), equals(guest));

      container.read(guestUserProvider.notifier).clear();
      expect(container.read(guestUserProvider), isNull);
      expect(container.read(effectiveUserProvider), isNull);
    });

    test('RouterNotifier fires notifyListeners when guest user changes without recreating GoRouter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final routerNotifier = container.read(routerNotifierProvider);
      int notificationCount = 0;
      routerNotifier.addListener(() {
        notificationCount++;
      });

      const guest = AppUser(uid: 'guest_202', displayName: 'Alex', isAnonymous: true);
      container.read(guestUserProvider.notifier).setGuest(guest);

      expect(notificationCount, greaterThanOrEqualTo(1));

      // Clearing guest triggers notification again
      container.read(guestUserProvider.notifier).clear();
      expect(notificationCount, greaterThanOrEqualTo(2));
    });
  });
}
