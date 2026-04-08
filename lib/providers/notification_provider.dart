import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';
import 'product_provider.dart' show firestoreServiceProvider;

final notificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final authState = ref.watch(authStateProvider);
      final uid = authState.value?.uid;
      if (uid == null || uid.isEmpty) {
        return Stream.value([]);
      }
      return ref.read(firestoreServiceProvider).watchNotificationsForUser(uid);
    });

class NotificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markRead(String notificationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(firestoreServiceProvider)
          .markNotificationRead(notificationId),
    );
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, void>(NotificationNotifier.new);
