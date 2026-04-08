const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Stripe with test secret key
const stripeSecretKey = functions.config().stripe?.test_secret || process.env.STRIPE_TEST_SECRET || 'sk_test_51RxQUx1MrHSdlzA0HJ5SGdXpozdCqWwE10qH6EMhCmY1cpPP9M8IaPPSGHN4OUA6JBeTXqSAmWb8rwKSGINUx6Sg007Vvmrjm2';
const stripeInstance = new stripe(stripeSecretKey);

const db = admin.firestore();

async function sendNotificationToToken(token, payload) {
  if (!token) return null;
  try {
    return await admin.messaging().send({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data || {},
    });
  } catch (error) {
    console.error('Error sending FCM message:', error);
    return null;
  }
}

async function sendNotificationToUser(userId, payload) {
  if (!userId) return null;
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;
    const token = userDoc.get('fcmToken');
    return await sendNotificationToToken(token, payload);
  } catch (error) {
    console.error('Error sending user notification:', error);
    return null;
  }
}

async function sendNotificationToAdmins(payload) {
  try {
    const adminsSnap = await db
      .collection('users')
      .where('role', '==', 'admin')
      .get();
    if (adminsSnap.empty) return null;

    const tasks = [];
    adminsSnap.forEach((doc) => {
      const token = doc.get('fcmToken');
      if (token) tasks.push(sendNotificationToToken(token, payload));
    });
    return await Promise.all(tasks);
  } catch (error) {
    console.error('Error sending admin notifications:', error);
    return null;
  }
}

/**
 * Creates a Stripe Payment Intent for LKR transactions
 * Called from Flutter app during checkout
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to create payment intent'
    );
  }

  try {
    const { amount, currency, metadata } = data;

    // Validate required parameters
    if (!amount || !currency) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Amount and currency are required'
      );
    }

    // Validate currency is LKR
    if (currency.toLowerCase() !== 'lkr') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Only LKR currency is supported'
      );
    }

    // Validate amount (Stripe expects amount in smallest currency unit)
    if (amount <= 0 || amount > 10000000) { // Max ~100,000 LKR
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid amount. Must be between 1 and 10,000,000 cents (LKR 0.01 to 100,000)'
      );
    }

    // Create payment intent
    const paymentIntent = await stripeInstance.paymentIntents.create({
      amount: amount,
      currency: currency.toLowerCase(),
      metadata: {
        ...metadata,
        firebase_uid: context.auth.uid,
        created_at: new Date().toISOString(),
      },
      // Enable automatic payment methods for Sri Lanka
      automatic_payment_methods: {
        enabled: true,
      },
      // Set receipt email if available
      receipt_email: metadata?.customer_email,
    });

    // Log the payment intent creation for auditing
    console.log(`Payment intent created: ${paymentIntent.id} for user ${context.auth.uid}`);

    return {
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
    };

  } catch (error) {
    console.error('Error creating payment intent:', error);

    if (error.type === 'StripeCardError') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Card error: ${error.message}`
      );
    } else if (error.type === 'StripeRateLimitError') {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Too many requests. Please try again later.'
      );
    } else if (error.type === 'StripeInvalidRequestError') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid request: ${error.message}`
      );
    } else if (error.type === 'StripeAPIError') {
      throw new functions.https.HttpsError(
        'internal',
        'Stripe API error. Please try again.'
      );
    } else if (error.type === 'StripeConnectionError') {
      throw new functions.https.HttpsError(
        'unavailable',
        'Network error. Please check your connection and try again.'
      );
    } else if (error.type === 'StripeAuthenticationError') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Stripe authentication error.'
      );
    } else {
      throw new functions.https.HttpsError(
        'internal',
        'An unexpected error occurred. Please try again.'
      );
    }
  }
});

/**
 * Webhook handler for Stripe events (optional - for additional security)
 * This can be used to verify payment completion server-side
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.get('stripe-signature');
  const endpointSecret = functions.config().stripe?.webhook_secret;

  let event;

  try {
    event = stripeInstance.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error(`Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log(`PaymentIntent ${paymentIntent.id} was successful!`);

      // Update order status in Firestore if needed
      // This provides server-side confirmation of payment success

      break;
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.log(`PaymentIntent ${failedPayment.id} failed.`);

      // Handle failed payment - could update order status

      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});

exports.notifyAdminsOnNewShop = functions.firestore
  .document('shops/{shopId}')
  .onCreate(async (snap, context) => {
    const shop = snap.data() || {};
    const shopName = shop.name || 'New shop';
    const ownerId = shop.ownerId || '';

    return sendNotificationToAdmins({
      title: 'New shop pending approval',
      body: `${shopName} submitted by a seller.`,
      data: {
        type: 'shop_created',
        shopId: context.params.shopId,
        ownerId: ownerId,
      },
    });
  });

exports.notifySellerOnNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data() || {};
    const shopId = order.shopId;
    const customerId = order.customerId || '';
    if (!shopId) return null;

    const shopDoc = await db.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return null;
    const ownerId = shopDoc.get('ownerId');
    if (!ownerId) return null;

    return sendNotificationToUser(ownerId, {
      title: 'New order received',
      body: `Order ${context.params.orderId} has been placed.`,
      data: {
        type: 'order_created',
        orderId: context.params.orderId,
        shopId: shopId,
        customerId: customerId,
      },
    });
  });

exports.notifyOnCustomRequest = functions.firestore
  .document('customRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data() || {};
    const requestId = context.params.requestId;
    const type = request.type || 'customization';
    const shopId = request.shopId;
    const designerId = request.designerId;
    const customerId = request.customerId || '';

    if (type === 'ar_model' && designerId) {
      return sendNotificationToUser(designerId, {
        title: 'New AR model task',
        body: 'A new 3D model request has been assigned to you.',
        data: {
          type: 'ar_model_request',
          requestId: requestId,
          productId: request.productId || '',
        },
      });
    }

    if (!shopId) return null;
    const shopDoc = await db.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return null;
    const ownerId = shopDoc.get('ownerId');
    if (!ownerId) return null;

    return sendNotificationToUser(ownerId, {
      title: 'New custom request',
      body: 'A customer submitted a customization request.',
      data: {
        type: 'custom_request',
        requestId: requestId,
        shopId: shopId,
        customerId: customerId,
      },
    });
  });

exports.notifyCustomerOnOrderStatus = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    if (before.status === after.status) return null;
    const customerId = after.customerId;
    if (!customerId) return null;

    return sendNotificationToUser(customerId, {
      title: 'Order status updated',
      body: `Your order is now ${after.status || 'updated'}.`,
      data: {
        type: 'order_status',
        orderId: context.params.orderId,
        status: after.status || '',
      },
    });
  });