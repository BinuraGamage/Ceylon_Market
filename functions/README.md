# Firebase Cloud Functions for Ceylon Market

This directory contains Firebase Cloud Functions for handling Stripe payment processing.

## Setup

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize functions in your project (if not done):
   ```bash
   firebase init functions
   ```

4. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

## Configuration

### Option 1: Firebase Functions Config (Recommended)
Set your Stripe test secret key using Firebase CLI:
```bash
firebase functions:config:set stripe.test_secret="sk_test_51RxQUx1MrHSdlzA0HJ5SGdXpozdCqWwE10qH6EMhCmY1cpPP9M8IaPPSGHN4OUA6JBeTXqSAmWb8rwKSGINUx6Sg007Vvmrjm2"
```

### Option 2: Environment Variable (Alternative)
If Firebase CLI is not available, you can set the environment variable:
```bash
# For local development
export STRIPE_TEST_SECRET="sk_test_51RxQUx1MrHSdlzA0HJ5SGdXpozdCqWwE10qH6EMhCmY1cpPP9M8IaPPSGHN4OUA6JBeTXqSAmWb8rwKSGINUx6Sg007Vvmrjm2"

# For production deployment, set in Firebase console or deployment script
```

Optional: Set webhook secret for webhook verification:
```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

## Deployment

Deploy the functions:
```bash
firebase deploy --only functions
```

## Functions

### createPaymentIntent
- **Purpose**: Creates a Stripe Payment Intent for LKR transactions
- **Parameters**:
  - `amount`: Amount in cents (e.g., 1000 for LKR 10.00)
  - `currency`: Must be 'lkr'
  - `metadata`: Optional metadata object
- **Returns**: Payment intent client secret and ID
- **Authentication**: Requires Firebase Auth

### stripeWebhook (Optional)
- **Purpose**: Handles Stripe webhook events for server-side payment verification
- **Note**: Requires webhook endpoint configuration in Stripe dashboard

## Testing

Test the function locally:
```bash
firebase functions:shell
```

Then call the function:
```javascript
createPaymentIntent({
  amount: 1000,
  currency: 'lkr',
  metadata: { customer_id: 'test_user' }
})
```

## Security Notes

- All functions require Firebase Authentication
- Payment intents are created server-side to protect Stripe secret keys
- Amount validation prevents excessive charges
- Only LKR currency is supported
- Comprehensive error handling for different Stripe error types