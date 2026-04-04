const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Stripe with test secret key
const stripeSecretKey = functions.config().stripe?.test_secret || process.env.STRIPE_TEST_SECRET || 'sk_test_51RxQUx1MrHSdlzA0HJ5SGdXpozdCqWwE10qH6EMhCmY1cpPP9M8IaPPSGHN4OUA6JBeTXqSAmWb8rwKSGINUx6Sg007Vvmrjm2';
const stripeInstance = new stripe(stripeSecretKey);

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