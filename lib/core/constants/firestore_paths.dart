class FirestorePaths {
  // Collections
  static const String users = 'users';
  static const String shops = 'shops';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String customRequests = 'customRequests';
  static const String ads = 'ads';
  static const String notificationQueue = 'notificationQueue';
  static const String offers = 'offers';

  // Document paths
  static String userDoc(String uid) => 'users/$uid';
  static String shopDoc(String shopId) => 'shops/$shopId';
  static String productDoc(String productId) => 'products/$productId';
  static String orderDoc(String orderId) => 'orders/$orderId';
  static String offerDoc(String offerId) => 'offers/$offerId';

  // Sub-collections
  static String cartCollection(String uid) => 'users/$uid/cart';
  static String cartItem(String uid, String itemId) => 'users/$uid/cart/$itemId';
  static String reviewsCollection(String productId) => 'products/$productId/reviews';
  static String messagesCollection(String requestId) => 'customRequests/$requestId/messages';
}
