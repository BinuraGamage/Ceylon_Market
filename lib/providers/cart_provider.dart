import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ── FirestoreService instance ─────────────────────────────────────────────
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

// ── Cart Stream Provider ──────────────────────────────────────────────────
// Real-time cart items for logged-in users
final cartStreamProvider = StreamProvider<List<CartItemModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value?.uid == null) {
    return Stream.value([]);
  }
  return ref.watch(firestoreServiceProvider).watchCart(authState.value!.uid);
});

// ── Cart Items with Product Details Provider ─────────────────────────────
// Combines cart items with full product data
final cartWithProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final cartItems = ref.watch(cartStreamProvider).value ?? [];
  if (cartItems.isEmpty) return [];

  final firestore = ref.read(firestoreServiceProvider);
  final results = <Map<String, dynamic>>[];

  for (final cartItem in cartItems) {
    try {
      final product = await firestore.getProduct(cartItem.productId);
      results.add({
        'cartItem': cartItem,
        'product': product,
      });
    } catch (e) {
      // Skip items with missing products
      continue;
    }
  }

  return results;
});

// ── Cart Total Provider ───────────────────────────────────────────────────
final cartTotalProvider = Provider<double>((ref) {
  final cartWithProducts = ref.watch(cartWithProductsProvider).value ?? [];
  return cartWithProducts.fold(0.0, (total, item) {
    final cartItem = item['cartItem'] as CartItemModel;
    final product = item['product'] as ProductModel;
    return total + (product.price * cartItem.quantity);
  });
});

// ── Cart Item Count Provider ──────────────────────────────────────────────
final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartStreamProvider).value ?? [];
  return cartItems.fold(0, (total, item) => total + item.quantity);
});

// ── Cart Notifier — handles cart operations ──────────────────────────────
class CartNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addItem({
    required String productId,
    required String shopId,
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
    String? selectedMaterial,
    String? customNote,
  }) async {
    final authState = ref.read(authStateProvider).value;
    if (authState?.uid == null) {
      throw Exception('User must be logged in to add items to cart');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).addToCart(
        uid: authState!.uid,
        productId: productId,
        shopId: shopId,
        quantity: quantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        selectedMaterial: selectedMaterial,
        customNote: customNote,
      ),
    );
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final authState = ref.read(authStateProvider).value;
    if (authState?.uid == null) {
      throw Exception('User must be logged in to update cart');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).updateCartItemQuantity(
        uid: authState!.uid,
        cartItemId: cartItemId,
        quantity: quantity,
      ),
    );
  }

  Future<void> removeItem(String cartItemId) async {
    final authState = ref.read(authStateProvider).value;
    if (authState?.uid == null) {
      throw Exception('User must be logged in to remove items from cart');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).removeFromCart(
        uid: authState!.uid,
        cartItemId: cartItemId,
      ),
    );
  }

  Future<void> clearCart() async {
    final authState = ref.read(authStateProvider).value;
    if (authState?.uid == null) {
      throw Exception('User must be logged in to clear cart');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).clearCart(authState!.uid),
    );
  }
}

final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, void>(CartNotifier.new);