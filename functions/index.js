const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripeLib = require("stripe");

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Initialize Stripe lazily to avoid errors during deployment
// if config is not set yet
let stripe = null;
/**
 * Get or initialize Stripe instance
 * @return {stripe} Stripe instance
 */
function getStripe() {
  if (!stripe) {
    const stripeConfig = functions.config().stripe;
    const secretKey = stripeConfig && stripeConfig.secret_key;
    if (!secretKey) {
      throw new Error("Stripe secret key not configured. " +
        "Run: firebase functions:config:set stripe.secret_key=\"sk_test_...\"");
    }
    stripe = stripeLib(secretKey);
  }
  return stripe;
}

/**
 * Create a Stripe Payment Intent
 *
 * This function securely creates a payment intent on the server side
 * using the Stripe secret key. It requires user authentication.
 *
 * @param {Object} data - Payment data
 * @param {number} data.amount - Amount in cents
 * @param {string} data.currency - Currency code (default: 'usd')
 * @param {Object} data.metadata - Additional metadata for the payment
 * @param {Object} context - Firebase Functions context
 * @returns {Object} Payment intent with client secret
 */
// Using Canadian region for data residency compliance.
// Using regular HTTP function instead of callable to allow manual auth token.
// This works around Flutter SDK bug with custom regions.
exports.createPaymentIntent = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

      // Handle preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Get auth token from header
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        console.error("Missing or invalid Authorization header");
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "User must be authenticated to create a payment intent",
          },
        });
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];

      // Verify the token and get user
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
        console.log("User authenticated:", decodedToken.uid);
      } catch (error) {
        console.error("Token verification failed:", error);
        res.status(401).json({
          error: {
            status: "UNAUTHENTICATED",
            message: "Invalid authentication token",
          },
        });
        return;
      }

      try {
        // Parse request body
        const requestData = req.body.data || req.body;
        const {amount, currency = "usd", metadata = {}} = requestData;

        // Validate amount
        if (!amount || amount <= 0) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Amount must be greater than 0",
            },
          });
          return;
        }

        // Validate currency
        if (typeof currency !== "string" || currency.length !== 3) {
          res.status(400).json({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Currency must be a valid 3-letter code",
            },
          });
          return;
        }

        // Add user ID to metadata for tracking
        const paymentMetadata = {
          ...metadata,
          userId: decodedToken.uid,
          userEmail: decodedToken.email || "unknown",
          createdAt: new Date().toISOString(),
        };

        // Create payment intent with Stripe
        const stripe = getStripe();
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amount, // Amount in cents
          currency: currency.toLowerCase(),
          metadata: paymentMetadata,
          // Optional: Add automatic payment methods
          automatic_payment_methods: {
            enabled: true,
          },
        });

        // Log payment intent creation in Firestore (optional)
        try {
          await admin.firestore().collection("payment_intents").add({
            userId: decodedToken.uid,
            paymentIntentId: paymentIntent.id,
            amount: amount,
            currency: currency,
            status: paymentIntent.status,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: paymentMetadata,
          });
        } catch (logError) {
          // Don't fail the payment if logging fails
          console.error("Failed to log payment intent:", logError);
        }

        // Return response in callable format for compatibility
        res.status(200).json({
          result: {
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
          },
        });
      } catch (error) {
        console.error("Error creating payment intent:", error);

        // Log error details for debugging
        console.error("Error type:", error.type || typeof error);
        console.error("Error message:", error.message);
        console.error("Error stack:", error.stack);

        // Handle Stripe errors
        let statusCode = 500;
        let errorStatus = "INTERNAL";
        let errorMessage = "Failed to create payment intent";

        if (error.type === "StripeCardError") {
          statusCode = 400;
          errorStatus = "FAILED_PRECONDITION";
          errorMessage = error.message || "Card payment failed";
        } else if (error.type === "StripeInvalidRequestError") {
          statusCode = 400;
          errorStatus = "INVALID_ARGUMENT";
          errorMessage = error.message || "Invalid payment request";
        } else {
          errorMessage = error.message || "Unknown error";
        }

        res.status(statusCode).json({
          error: {
            status: errorStatus,
            message: errorMessage,
          },
        });
      }
    });

/**
 * Webhook handler for Stripe events
 *
 * This function handles Stripe webhook events to update payment status
 * in Firestore when payments are completed or fail.
 *
 * To set up the webhook:
 * 1. Go to Stripe Dashboard > Developers > Webhooks
 * 2. Add endpoint:
 *    YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/handleStripeWebhook
 * 3. Select events: payment_intent.succeeded, payment_intent.payment_failed
 * 4. Copy webhook signing secret and set:
 *    firebase functions:config:set stripe.webhook_secret="whsec_..."
 */
exports.handleStripeWebhook = functions
    .region("northamerica-northeast1")
    .https.onRequest(async (req, res) => {
      const sig = req.headers["stripe-signature"];
      const webhookSecret = functions.config().stripe.webhook_secret;

      let event;

      try {
        // Verify webhook signature
        const stripe = getStripe();
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
      } catch (err) {
        console.error("Webhook signature verification failed:", err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
      }

      // Handle the event
      switch (event.type) {
        case "payment_intent.succeeded": {
          const paymentIntent = event.data.object;
          console.log("PaymentIntent succeeded:", paymentIntent.id);

          // Update Firestore with payment success
          try {
            const userId = paymentIntent.metadata &&
                paymentIntent.metadata.userId;
            if (userId) {
              await admin.firestore()
                  .collection("payment_intents")
                  .where("paymentIntentId", "==", paymentIntent.id)
                  .get()
                  .then(async (snapshot) => {
                    if (!snapshot.empty) {
                      await snapshot.docs[0].ref.update({
                        status: "succeeded",
                        succeededAt: admin.firestore.FieldValue
                            .serverTimestamp(),
                      });
                    }
                  });
            }
          } catch (error) {
            console.error("Error updating payment status:", error);
          }
          break;
        }

        case "payment_intent.payment_failed": {
          const failedPayment = event.data.object;
          console.log("PaymentIntent failed:", failedPayment.id);

          // Update Firestore with payment failure
          try {
            const userId = failedPayment.metadata &&
                failedPayment.metadata.userId;
            if (userId) {
              const errorMessage = (failedPayment.last_payment_error &&
              failedPayment.last_payment_error.message) || "Unknown error";
              await admin.firestore()
                  .collection("payment_intents")
                  .where("paymentIntentId", "==", failedPayment.id)
                  .get()
                  .then(async (snapshot) => {
                    if (!snapshot.empty) {
                      await snapshot.docs[0].ref.update({
                        status: "failed",
                        failedAt: admin.firestore.FieldValue.serverTimestamp(),
                        failureReason: errorMessage,
                      });
                    }
                  });
            }
          } catch (error) {
            console.error("Error updating payment failure:", error);
          }
          break;
        }

        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      // Return a response to acknowledge receipt of the event
      res.json({received: true});
    });

