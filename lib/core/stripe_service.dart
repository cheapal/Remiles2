import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_service.dart';

/// Stripe Payment Service
/// 
/// This service handles Stripe payment processing for subscription plans.
/// 
/// IMPORTANT: You need to:
/// 1. Get your Stripe publishable key from https://dashboard.stripe.com/apikeys
/// 2. Set it in the StripeService.initialize() method
/// 3. Create a backend endpoint to create payment intents securely
///    (or use Stripe's test mode with test keys)
class StripeService {
  // TODO: Replace with your Stripe publishable key
  // Get it from: https://dashboard.stripe.com/apikeys
  static const String _publishableKey = 'pk_test_51RqCWCCEmM4LMAn7QdeqDoEmBstjnp01McbGYajDk9EWU5F7m0Izvm84F9DpxaecQFFo81dD5DZrtiThSMiP9QdI004pe9wGBG';
  
  // TODO: Replace with your backend endpoint for creating payment intents
  // This should be a secure endpoint that uses your Stripe secret key
  // static const String _paymentIntentEndpoint = 'https://your-backend.com/create-payment-intent';
  
  /// Initialize Stripe with publishable key
  static Future<void> initialize() async {
    Stripe.publishableKey = 'pk_test_51RqCWCCEmM4LMAn7QdeqDoEmBstjnp01McbGYajDk9EWU5F7m0Izvm84F9DpxaecQFFo81dD5DZrtiThSMiP9QdI004pe9wGBG';
    await Stripe.instance.applySettings();
  }
  
  /// Create a payment intent for the subscription amount using Firebase Cloud Functions
  /// 
  /// This calls the Firebase Cloud Function 'createPaymentIntent' which securely
  /// creates a Stripe payment intent using the server-side secret key
  /// 
  /// Returns the client secret string needed for the Payment Sheet
  static Future<String> createPaymentIntent({
    required int amountInCents,
    required String currency,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Verify user is authenticated with Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in with Firebase Auth to process payment');
      }
      
      // Get a fresh auth token to ensure it's valid
      final idToken = await currentUser.getIdToken(true);
      if (idToken != null) {
        debugPrint('Auth token obtained: ${idToken.substring(0, 20)}...');
      }
      
      debugPrint('Creating payment intent via Firebase Functions...');
      debugPrint('User ID: ${currentUser.uid}');
      debugPrint('Amount: \$${(amountInCents / 100).toStringAsFixed(2)}');
      debugPrint('Currency: $currency');
      debugPrint('Metadata: $metadata');
      
      // Call Firebase Cloud Function (using Canadian region: northamerica-northeast1)
      // NOTE: There's a known issue where instanceFor() might not automatically include
      // the auth token. We need to ensure FirebaseAuth is the active instance.
      
      // Verify user is still authenticated right before the call
      final userBeforeCall = FirebaseAuth.instance.currentUser;
      if (userBeforeCall == null || userBeforeCall.uid != currentUser.uid) {
        throw Exception('User authentication lost. Please login again.');
      }
      
      // Get a fresh auth token to ensure it's valid
      final freshToken = await userBeforeCall.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }
      debugPrint('Fresh token obtained before call: ${freshToken.substring(0, 20)}...');
      
      // WORKAROUND: Manually make HTTP request to Canadian region function
      // This bypasses the Flutter SDK bug where instanceFor() doesn't include auth token
      // Using Canadian region (northamerica-northeast1) for data residency compliance
      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/createPaymentIntent';
      
      debugPrint('Calling Canadian region function: $functionUrl');
      
      // Make HTTP POST request with auth token in header
      // Firebase callable functions require specific headers and format
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken', // Firebase Auth ID token
        },
        body: jsonEncode({
          'data': {
            'amount': amountInCents,
            'currency': currency,
            'metadata': metadata,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Payment intent creation timed out');
        },
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');
      
      debugPrint('Function response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorBody = response.body;
        debugPrint('Function error response: $errorBody');
        
        // Try to parse error message from Firebase Functions format
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorCode = error?['status'] as String?;
          final errorMessage = error?['message'] as String?;
          
          // Log to Crashlytics
          await FirebaseService.recordError(
            Exception(errorMessage ?? errorBody),
            StackTrace.current,
            reason: 'Firebase Functions error: $errorCode',
          );
          await FirebaseService.log('Payment Intent Creation Failed: $errorCode - $errorMessage');
          await FirebaseService.setCustomKey('payment_error_type', 'firebase_functions');
          if (errorCode != null) {
            await FirebaseService.setCustomKey('payment_error_code', errorCode);
          }
          
          // Log analytics event for payment intent failure
          await FirebaseService.logEvent(
            'payment_intent_failed',
            parameters: FirebaseService.convertParameters({
              'error_type': 'firebase_functions',
              'error_code': errorCode ?? 'unknown',
              'amount': amountInCents,
              'currency': currency,
            }),
          );
          
          if (errorCode == 'UNAUTHENTICATED' || errorCode == 'unauthenticated') {
            throw Exception('Please login to process payment');
          } else if (errorCode == 'PERMISSION_DENIED' || errorCode == 'permission-denied') {
            throw Exception('Permission denied. Please contact support.');
          } else {
            throw Exception('Payment intent creation failed: ${errorMessage ?? errorCode ?? response.statusCode}');
          }
        } catch (parseError) {
          // If parsing fails, log and throw generic error
          await FirebaseService.recordError(
            Exception('HTTP ${response.statusCode}: $errorBody'),
            StackTrace.current,
            reason: 'Payment intent creation HTTP error',
          );
          
          // Log analytics event for payment intent failure
          await FirebaseService.logEvent(
            'payment_intent_failed',
            parameters: FirebaseService.convertParameters({
              'error_type': 'http_error',
              'status_code': response.statusCode,
              'amount': amountInCents,
              'currency': currency,
            }),
          );
          
          throw Exception('Payment intent creation failed: ${response.statusCode} - ${response.body}');
        }
      }
      
      // Parse response
      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;
      final clientSecret = result?['clientSecret'] as String?;
      
      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Failed to get client secret from Firebase Function');
      }
      
      debugPrint('Payment intent created successfully in Canadian region');
      
      // Log successful payment intent creation to Crashlytics
      await FirebaseService.log('Payment Intent Created Successfully - Amount: \$${(amountInCents / 100).toStringAsFixed(2)}');
      await FirebaseService.setCustomKey('payment_intent_created', 'true');
      
      // Log analytics event for payment intent creation
      await FirebaseService.logEvent(
        'payment_intent_created',
        parameters: FirebaseService.convertParameters({
          'amount': amountInCents,
          'currency': currency,
          'value': amountInCents / 100.0, // For revenue tracking
        }),
      );
      
      return clientSecret;
    } on http.ClientException catch (e, stackTrace) {
      debugPrint('HTTP Client Error: $e');
      
      // Log to Crashlytics
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'HTTP client error in createPaymentIntent',
      );
      await FirebaseService.log('Payment Intent Creation Failed: HTTP client error');
      await FirebaseService.setCustomKey('payment_error_type', 'http_client_error');
      
      // Log analytics event for payment intent failure
      await FirebaseService.logEvent(
        'payment_intent_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': 'http_client_error',
          'amount': amountInCents,
          'currency': currency,
        }),
      );
      
      throw Exception('Network error. Please check your connection and try again.');
    } catch (e, stackTrace) {
      debugPrint('Error creating payment intent: $e');
      
      // Log to Crashlytics
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Unexpected error in createPaymentIntent',
      );
      await FirebaseService.log('Payment Intent Creation Error: $e');
      await FirebaseService.setCustomKey('payment_error_type', 'unexpected_error');
      
      // Log analytics event for payment intent failure
      await FirebaseService.logEvent(
        'payment_intent_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': 'unexpected_error',
          'amount': amountInCents,
          'currency': currency,
        }),
      );
      
      rethrow;
    }
  }
  
  /// Process payment using Stripe Payment Sheet
  /// 
  /// This method:
  /// 1. Creates a payment intent (via backend)
  /// 2. Initializes the Stripe Payment Sheet
  /// 3. Presents the payment sheet to the user
  /// 4. Returns the payment result
  static Future<bool> processPayment({
    required int amountInCents,
    required String currency,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Step 1: Create payment intent via Firebase Functions
      final clientSecret = await createPaymentIntent(
        amountInCents: amountInCents,
        currency: currency,
        metadata: metadata,
      );
      
      if (clientSecret.isEmpty) {
        throw Exception('Payment intent client secret is missing');
      }
      
      // Step 2: Initialize payment sheet parameters
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Remiles',
        ),
      );
      
      // Step 3: Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      // Step 4: Payment successful
      // Log successful payment to Crashlytics
      await FirebaseService.log('Payment Processed Successfully - Amount: \$${(amountInCents / 100).toStringAsFixed(2)}');
      await FirebaseService.setCustomKey('payment_success', 'true');
      await FirebaseService.setCustomKey('payment_amount', amountInCents);
      
      // Log analytics event for successful payment
      final planName = metadata['plan_name'] as String? ?? 'unknown';
      final transactionId = '${metadata['shipper_id']}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Log standard purchase event for revenue tracking
      await FirebaseService.logEvent(
        'purchase',
        parameters: FirebaseService.convertParameters({
          'transaction_id': transactionId,
          'value': amountInCents / 100.0,
          'currency': currency.toUpperCase(),
          'item_id': planName.toLowerCase().replaceAll(' ', '_'),
          'item_name': planName,
        }),
      );
      
      // Also log a custom event for subscription upgrade
      await FirebaseService.logEvent(
        'subscription_upgrade',
        parameters: FirebaseService.convertParameters({
          'plan_name': planName,
          'amount': amountInCents,
          'currency': currency,
          'value': amountInCents / 100.0,
        }),
      );
      
      return true;
    } on StripeException catch (e, stackTrace) {
      debugPrint('Stripe Error: ${e.error.message}');
      
      if (e.error.code == FailureCode.Canceled) {
        // User canceled the payment - don't log to Crashlytics as this is expected
        await FirebaseService.log('Payment canceled by user');
        
        // Log analytics event for payment cancellation
        await FirebaseService.logEvent(
          'payment_canceled',
          parameters: FirebaseService.convertParameters({
            'amount': amountInCents,
            'currency': currency,
          }),
        );
        
        return false;
      } else {
        // Log Stripe errors to Crashlytics
        await FirebaseService.recordError(
          e,
          stackTrace,
          reason: 'Stripe payment error: ${e.error.code}',
        );
        await FirebaseService.log('Stripe Payment Error: ${e.error.code} - ${e.error.message}');
        await FirebaseService.setCustomKey('payment_error_type', 'stripe_error');
        await FirebaseService.setCustomKey('stripe_error_code', e.error.code.toString());
        await FirebaseService.setCustomKey('stripe_error_message', e.error.message ?? 'Unknown');
        
        // Log analytics event for payment failure
        final planName = metadata['plan_name'] as String? ?? 'unknown';
        await FirebaseService.logEvent(
          'payment_failed',
          parameters: FirebaseService.convertParameters({
            'error_type': 'stripe_error',
            'error_code': e.error.code.toString(),
            'plan_name': planName,
            'amount': amountInCents,
            'currency': currency,
          }),
        );
        
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('Payment processing error: $e');
      
      // Log unexpected payment errors to Crashlytics
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Unexpected error in payment processing',
      );
      await FirebaseService.log('Payment Processing Error: $e');
      await FirebaseService.setCustomKey('payment_error_type', 'processing_error');
      
      // Log analytics event for payment failure
      final planName = metadata['plan_name'] as String? ?? 'unknown';
      await FirebaseService.logEvent(
        'payment_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': 'processing_error',
          'plan_name': planName,
          'amount': amountInCents,
          'currency': currency,
        }),
      );
      
      rethrow;
    }
  }
  
  /// Process payment using card details directly (Alternative method)
  /// 
  /// NOTE: This method is currently not fully implemented as it requires
  /// complex backend integration. It's recommended to use the Payment Sheet
  /// method instead (processPayment).
  /// 
  /// For card input, you should collect card details and then use the
  /// Payment Sheet with those details, or implement a full backend flow.
  static Future<bool> processPaymentWithCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required int amountInCents,
    required String currency,
    required Map<String, dynamic> metadata,
  }) async {
    // For now, redirect to Payment Sheet method
    // In a full implementation, you would:
    // 1. Create payment intent on backend
    // 2. Create payment method with card details
    // 3. Attach payment method to payment intent on backend
    // 4. Confirm payment on client
    
    throw UnimplementedError(
      'Card input payment requires backend integration. '
      'Please use the Payment Sheet method (processPayment) instead, '
      'or implement a backend endpoint to handle payment intent creation and confirmation.'
    );
  }
  
  /// Get error message from Stripe exception
  static String getErrorMessage(dynamic error) {
    if (error is StripeException) {
      return error.error.message ?? 'Payment failed. Please try again.';
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Create a Setup Intent for saving payment methods
  /// Returns the client secret for the Setup Intent
  static Future<String> createSetupIntent() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/createSetupIntent';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {},
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Setup intent creation timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to create setup intent');
        } catch (parseError) {
          throw Exception('Failed to create setup intent: ${response.statusCode}');
        }
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;
      final clientSecret = result?['clientSecret'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Failed to get client secret from Firebase Function');
      }

      return clientSecret;
    } catch (e, stackTrace) {
      debugPrint('Error creating setup intent: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in createSetupIntent',
      );
      rethrow;
    }
  }

  /// Save a payment method using Setup Intent
  static Future<bool> savePaymentMethod() async {
    try {
      final clientSecret = await createSetupIntent();

      // Initialize payment sheet with setup intent
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Remiles',
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment method saved successfully
      await FirebaseService.log('Payment method saved successfully');
      await FirebaseService.logEvent(
        'payment_method_added',
        parameters: FirebaseService.convertParameters({}),
      );

      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        await FirebaseService.log('Payment method setup canceled by user');
        return false;
      } else {
        await FirebaseService.recordError(
          e,
          StackTrace.current,
          reason: 'Stripe error in savePaymentMethod: ${e.error.code}',
        );
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving payment method: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in savePaymentMethod',
      );
      rethrow;
    }
  }

  /// List all payment methods for the current user
  static Future<List<Map<String, dynamic>>> listPaymentMethods() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/listPaymentMethods';

      final response = await http.get(
        Uri.parse(functionUrl),
        headers: {
          'Authorization': 'Bearer $freshToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('List payment methods timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to list payment methods');
        } catch (parseError) {
          throw Exception('Failed to list payment methods: ${response.statusCode}');
        }
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;
      final paymentMethods = result?['paymentMethods'] as List<dynamic>?;

      return paymentMethods != null
          ? List<Map<String, dynamic>>.from(
              paymentMethods.map((e) => e as Map<String, dynamic>),
            )
          : [];
    } catch (e, stackTrace) {
      debugPrint('Error listing payment methods: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in listPaymentMethods',
      );
      rethrow;
    }
  }

  /// Set a payment method as default
  static Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/setDefaultPaymentMethod';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {
            'paymentMethodId': paymentMethodId,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Set default payment method timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to set default payment method');
        } catch (parseError) {
          throw Exception('Failed to set default payment method: ${response.statusCode}');
        }
      }

      await FirebaseService.log('Default payment method set successfully');
      await FirebaseService.logEvent(
        'payment_method_set_default',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
        }),
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error setting default payment method: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in setDefaultPaymentMethod',
      );
      rethrow;
    }
  }

  /// Delete a payment method
  static Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/deletePaymentMethod';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {
            'paymentMethodId': paymentMethodId,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Delete payment method timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to delete payment method');
        } catch (parseError) {
          throw Exception('Failed to delete payment method: ${response.statusCode}');
        }
      }

      await FirebaseService.log('Payment method deleted successfully');
      await FirebaseService.logEvent(
        'payment_method_deleted',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
        }),
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error deleting payment method: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in deletePaymentMethod',
      );
      rethrow;
    }
  }

  /// Create a Stripe Connect account for carrier
  /// Returns the account ID and status
  ///
  /// NOTE: Only carriers need Connect accounts to receive money.
  /// Shippers only need Stripe Customer accounts (for payment methods).
  static Future<Map<String, dynamic>> createConnectAccount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl =
          'https://$region-$projectId.cloudfunctions.net/createConnectAccount';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({'data': {}}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Create Connect account timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            errorBody['error']?['message'] ?? 'Failed to create Connect account');
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;

      if (result == null) {
        throw Exception('Invalid response from createConnectAccount');
      }

      await FirebaseService.log('Stripe Connect account created successfully');
      await FirebaseService.logEvent(
        'connect_account_created',
        parameters: FirebaseService.convertParameters({
          'account_id': result['accountId'] as String? ?? '',
          'already_exists': result['alreadyExists'] == true ? 1 : 0,
        }),
      );

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error creating Connect account: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in createConnectAccount',
      );
      rethrow;
    }
  }

  /// Create Account Link for Stripe Connect onboarding
  /// Returns the onboarding URL
  ///
  /// NOTE: Only carriers need this. Shippers don't need Connect accounts.
  static Future<String> createAccountLink({String? returnUrl}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl =
          'https://$region-$projectId.cloudfunctions.net/createAccountLink';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {
            if (returnUrl != null) 'returnUrl': returnUrl,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Create Account Link timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            errorBody['error']?['message'] ?? 'Failed to create Account Link');
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;
      final url = result?['url'] as String?;

      if (url == null || url.isEmpty) {
        throw Exception('Invalid response: missing onboarding URL');
      }

      await FirebaseService.log('Account Link created successfully');
      await FirebaseService.logEvent(
        'account_link_created',
        parameters: FirebaseService.convertParameters({}),
      );

      return url;
    } catch (e, stackTrace) {
      debugPrint('Error creating Account Link: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in createAccountLink',
      );
      rethrow;
    }
  }

  /// Get Stripe Connect account status
  /// Returns account activation status and onboarding requirements
  ///
  /// NOTE: Only carriers need Connect accounts to receive money.
  static Future<Map<String, dynamic>> getConnectAccountStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl =
          'https://$region-$projectId.cloudfunctions.net/getConnectAccountStatus';

      final response = await http.get(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Get Connect account status timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            errorBody['error']?['message'] ??
                'Failed to get Connect account status');
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;

      if (result == null) {
        throw Exception('Invalid response from getConnectAccountStatus');
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error getting Connect account status: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in getConnectAccountStatus',
      );
      rethrow;
    }
  }

  /// Create an escrow payment intent for holding funds
  /// 
  /// This creates a Stripe Payment Intent with manual capture mode
  /// to hold funds in escrow until POD verification.
  /// 
  /// Returns the client secret for the Payment Sheet
  static Future<String> createEscrowPaymentIntent({
    required int amountInCents,
    required String loadId,
    required String carrierId,
    required String shipperId,
    String currency = 'cad',
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 
          'https://$region-$projectId.cloudfunctions.net/createEscrowPaymentIntent';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {
            'amount': amountInCents,
            'loadId': loadId,
            'carrierId': carrierId,
            'shipperId': shipperId,
            'currency': currency,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Escrow payment intent creation timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to create escrow payment intent');
        } catch (parseError) {
          throw Exception('Failed to create escrow payment intent: ${response.statusCode}');
        }
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;
      final clientSecret = result?['clientSecret'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Failed to get client secret from Firebase Function');
      }

      await FirebaseService.log('Escrow Payment Intent Created - Load: $loadId');
      await FirebaseService.logEvent(
        'escrow_payment_intent_created',
        parameters: FirebaseService.convertParameters({
          'load_id': loadId,
          'amount': amountInCents,
          'currency': currency,
        }),
      );

      return clientSecret;
    } catch (e, stackTrace) {
      debugPrint('Error creating escrow payment intent: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in createEscrowPaymentIntent',
      );
      rethrow;
    }
  }

  /// Process escrow payment using Stripe Payment Sheet
  /// 
  /// This method:
  /// 1. Creates an escrow payment intent (via backend)
  /// 2. Initializes the Stripe Payment Sheet
  /// 3. Presents the payment sheet to the user
  /// 4. Returns the payment result
  static Future<bool> processEscrowPayment({
    required int amountInCents,
    required String loadId,
    required String carrierId,
    required String shipperId,
    String currency = 'cad',
  }) async {
    try {
      // Step 1: Create escrow payment intent via Firebase Functions
      final clientSecret = await createEscrowPaymentIntent(
        amountInCents: amountInCents,
        loadId: loadId,
        carrierId: carrierId,
        shipperId: shipperId,
        currency: currency,
      );

      if (clientSecret.isEmpty) {
        throw Exception('Escrow payment intent client secret is missing');
      }

      // Step 2: Initialize payment sheet parameters
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Remiles',
        ),
      );

      // Step 3: Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 4: Payment successful
      await FirebaseService.log(
        'Escrow Payment Processed - Amount: \$${(amountInCents / 100).toStringAsFixed(2)} - Load: $loadId'
      );
      await FirebaseService.logEvent(
        'escrow_payment_processed',
        parameters: FirebaseService.convertParameters({
          'load_id': loadId,
          'amount': amountInCents,
          'currency': currency,
          'value': amountInCents / 100.0,
        }),
      );

      return true;
    } on StripeException catch (e, stackTrace) {
      debugPrint('Stripe Error: ${e.error.message}');

      if (e.error.code == FailureCode.Canceled) {
        await FirebaseService.log('Escrow payment canceled by user');
        await FirebaseService.logEvent(
          'escrow_payment_canceled',
          parameters: FirebaseService.convertParameters({
            'load_id': loadId,
            'amount': amountInCents,
            'currency': currency,
          }),
        );
        return false;
      } else {
        await FirebaseService.recordError(
          e,
          stackTrace,
          reason: 'Stripe escrow payment error: ${e.error.code}',
        );
        await FirebaseService.logEvent(
          'escrow_payment_failed',
          parameters: FirebaseService.convertParameters({
            'error_type': 'stripe_error',
            'error_code': e.error.code.toString(),
            'load_id': loadId,
            'amount': amountInCents,
            'currency': currency,
          }),
        );
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('Escrow payment processing error: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Unexpected error in escrow payment processing',
      );
      await FirebaseService.logEvent(
        'escrow_payment_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': 'processing_error',
          'load_id': loadId,
          'amount': amountInCents,
          'currency': currency,
        }),
      );
      rethrow;
    }
  }

  /// Capture escrow payment and transfer to carrier
  /// 
  /// This captures a held escrow payment and transfers funds to the carrier
  /// after POD verification.
  static Future<bool> captureEscrowPayment({
    required String paymentIntentId,
    required String loadId,
    required String carrierId,
    required String shipperId,
    int? amountInCents,
    String completionStatus = 'complete',
    String? carrierName,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 
          'https://$region-$projectId.cloudfunctions.net/captureEscrowPayment';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {
            'paymentIntentId': paymentIntentId,
            'loadId': loadId,
            'carrierId': carrierId,
            'shipperId': shipperId,
            if (amountInCents != null) 'amount': amountInCents,
            'completionStatus': completionStatus,
            if (carrierName != null) 'carrierName': carrierName,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Escrow payment capture timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to capture escrow payment');
        } catch (parseError) {
          throw Exception('Failed to capture escrow payment: ${response.statusCode}');
        }
      }

      final responseData = jsonDecode(response.body);
      final result = responseData['result'] as Map<String, dynamic>?;
      final success = result?['success'] as bool? ?? false;

      if (success) {
        await FirebaseService.log(
          'Escrow Payment Captured - Load: $loadId - Transfer: ${result?['transferId']}'
        );
        await FirebaseService.logEvent(
          'escrow_payment_captured',
          parameters: FirebaseService.convertParameters({
            'load_id': loadId,
            'payment_intent_id': paymentIntentId,
            'transfer_id': result?['transferId'] ?? '',
            'amount': result?['amount'] ?? 0,
          }),
        );
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('Error capturing escrow payment: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Error in captureEscrowPayment',
      );
      rethrow;
    }
  }
}

