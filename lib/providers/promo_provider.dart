import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promo_code_model.dart';
import '../services/firestore_service.dart';

// ── Promo Code Provider ───────────────────────────────────────────────────
final promoCodeProvider = FutureProvider.family<PromoCodeModel?, String>((ref, code) async {
  final firestore = ref.read(firestoreServiceProvider);
  // TODO: Implement promo code lookup from Firestore
  // For now, return null - promo codes will be handled client-side for demo
  return null;
});

// ── Active Promo Codes Provider ───────────────────────────────────────────
final activePromoCodesProvider = FutureProvider<List<PromoCodeModel>>((ref) async {
  final firestore = ref.read(firestoreServiceProvider);
  // TODO: Implement fetching active promo codes from Firestore
  return [];
});