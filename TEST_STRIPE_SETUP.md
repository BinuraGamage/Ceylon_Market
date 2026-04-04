# Test Stripe Integration Setup

This script helps verify that your Stripe integration is properly configured.

## Prerequisites
1. Node.js and npm installed
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. Firebase project initialized

## Quick Setup Test

### 1. Test Local Functions (Optional)
```bash
cd functions
npm install
npm run serve  # This will start local functions emulator
```

### 2. Test Payment Intent Creation
In another terminal, test the function:
```bash
# Set environment variable for local testing
export STRIPE_TEST_SECRET="sk_test_51RxQUx1MrHSdlzA0HJ5SGdXpozdCqWwE10qH6EMhCmY1cpPP9M8IaPPSGHN4OUA6JBeTXqSAmWb8rwKSGINUx6Sg007Vvmrjm2"

# Start Firebase shell
firebase functions:shell

# In the shell, test the function:
createPaymentIntent({
  amount: 1000,  // LKR 10.00 in cents
  currency: 'lkr',
  metadata: {
    customer_id: 'test_user',
    customer_email: 'test@example.com'
  }
})
```

Expected response:
```json
{
  "client_secret": "pi_xxx_secret_xxx",
  "payment_intent_id": "pi_xxx",
  "amount": 1000,
  "currency": "lkr"
}
```

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

## Flutter App Testing

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test the checkout flow**:
   - Add items to cart
   - Go to checkout
   - Fill shipping address
   - Click "Place Order"
   - Complete Stripe payment form
   - Verify order creation on success

## Troubleshooting

### Common Issues:

1. **"Function not found" error**:
   - Ensure functions are deployed: `firebase deploy --only functions`
   - Check function name matches: `createPaymentIntent`

2. **"Stripe authentication error"**:
   - Verify secret key is correctly set
   - Check Firebase Functions config or environment variable

3. **"Currency not supported"**:
   - Ensure currency is lowercase 'lkr'
   - Verify Stripe account supports LKR

4. **Payment fails**:
   - Check Stripe dashboard for test payments
   - Verify publishable key in Flutter app
   - Ensure test mode is enabled

### Debug Commands:

```bash
# Check Firebase project
firebase projects:list

# Check functions status
firebase functions:list

# View function logs
firebase functions:log
```

## Environment Variables

For production deployment, set these in your deployment environment:

```
STRIPE_TEST_SECRET=sk_test_51RxQUx1MrHSdlzA0HJ5SGdXpozdCqWwE10qH6EMhCmY1cpPP9M8IaPPSGHN4OUA6JBeTXqSAmWb8rwKSGINUx6Sg007Vvmrjm2
STRIPE_WEBHOOK_SECRET=whsec_... (optional)
```