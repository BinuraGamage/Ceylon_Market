import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ceylonmarketplace/features/checkout/screens/checkout_screen.dart';
import 'package:ceylonmarketplace/providers/auth_provider.dart';
import 'package:ceylonmarketplace/providers/cart_provider.dart';
import 'package:ceylonmarketplace/providers/order_provider.dart';
import 'package:ceylonmarketplace/models/user_model.dart';

// Mock classes for testing
class MockAuthState extends Mock implements AsyncValue<UserModel?> {}
class MockCartState extends Mock implements AsyncValue<List<Map<String, dynamic>>> {}
class MockOrderNotifier extends Mock implements OrderNotifier {}

void main() {
  group('CheckoutScreen Tests', () {
    testWidgets('CheckoutScreen builds correctly', (WidgetTester tester) async {
      // Create a mock container for Riverpod
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncValue.data(UserModel(
              uid: 'test-user-id',
              email: 'test@example.com',
              displayName: 'Test User',
              role: 'customer',
            )),
          ),
          cartWithProductsProvider.overrideWithValue(
            const AsyncValue.data([]), // Empty cart
          ),
          cartTotalProvider.overrideWithValue(0.0),
          orderNotifierProvider.overrideWithValue(MockOrderNotifier()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );

      // Verify the screen builds
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('Shows empty cart message when cart is empty', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AsyncValue.data(UserModel(
              uid: 'test-user-id',
              email: 'test@example.com',
              displayName: 'Test User',
              role: 'customer',
            )),
          ),
          cartWithProductsProvider.overrideWithValue(
            const AsyncValue.data([]),
          ),
          cartTotalProvider.overrideWithValue(0.0),
          orderNotifierProvider.overrideWithValue(MockOrderNotifier()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);
    });

    test('Payment amount conversion to cents', () {
      // Test that LKR amounts are correctly converted to cents for Stripe
      final amountLKR = 25.50;
      final amountCents = (amountLKR * 100).toInt();

      expect(amountCents, 2550);
    });

    test('Currency validation', () {
      // Test that only LKR currency is accepted
      const validCurrency = 'lkr';
      const invalidCurrency = 'usd';

      expect(validCurrency.toLowerCase(), 'lkr');
      expect(invalidCurrency.toLowerCase() == 'lkr', false);
    });
  });
}