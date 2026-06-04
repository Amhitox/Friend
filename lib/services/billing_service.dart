import 'dart:async';
import 'dart:developer' as dev;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription.dart';

/// Singleton service that manages Google Play Billing via the
/// `in_app_purchase` package.
///
/// Responsibilities:
/// - Connect to the billing client and load product details from the store.
/// - Initiate purchase flows for subscription plans.
/// - Listen to the store's purchase update stream and relay status.
/// - Restore previously purchased subscriptions.
/// - Provide a stub for server-side receipt verification.
///
/// Usage:
/// ```dart
/// final billing = BillingService.instance;
/// await billing.initialize();
/// final plans = billing.getAvailableProducts();
/// billing.purchasePlan(plans.first);
/// ```
class BillingService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  BillingService._();

  static final BillingService _instance = BillingService._();

  /// The shared singleton instance.
  static BillingService get instance => _instance;

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Google Play product IDs for all subscription plans.
  static const Set<String> _productIds = {
    'dostok_premium_monthly',
    'dostok_premium_yearly',
    'dostok_vip_monthly',
    'dostok_vip_yearly',
  };

  /// Maximum number of retry attempts for billing operations.
  static const int _maxRetries = 3;

  /// Delay between retry attempts.
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Tag for debug logging.
  static const String _tag = 'BillingService';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final InAppPurchase _iap = InAppPurchase.instance;

  /// Subscription to the store's purchase update stream.
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Controller that relays purchase status updates to listeners.
  final StreamController<PurchaseStatus> _purchaseStatusController =
      StreamController<PurchaseStatus>.broadcast();

  /// Products loaded from the store, keyed by product ID.
  final Map<String, ProductDetails> _storeProducts = {};

  /// Canonical plan definitions mapped by product ID.
  final Map<String, SubscriptionPlan> _planCatalog = {};

  /// Whether the billing client is connected and products are loaded.
  bool _isInitialized = false;

  /// Whether a purchase flow is currently in progress.
  bool _purchaseInProgress = false;

  /// The last error message, if any.
  String? _lastError;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  /// Stream of purchase status updates.
  ///
  /// Listen to this to react to completed, failed, or pending purchases.
  Stream<PurchaseStatus> get purchaseStream => _purchaseStatusController.stream;

  /// Whether the service has been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// Whether a purchase flow is currently in progress.
  bool get isPurchaseInProgress => _purchaseInProgress;

  /// The last error message, or null if no error.
  String? get lastError => _lastError;

  /// Whether in-app purchases are available on this device.
  Future<bool> get isAvailable => _iap.isAvailable();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Connects to the billing platform, loads products, and restores purchases.
  ///
  /// Must be called before any other billing method. Safe to call multiple
  /// times -- subsequent calls are no-ops if already initialized.
  ///
  /// Returns `true` if initialization succeeds, `false` otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) {
      dev.log('Already initialized', name: _tag);
      return true;
    }

    try {
      dev.log('Initializing billing service...', name: _tag);

      // Check store availability.
      final available = await _iap.isAvailable();
      if (!available) {
        _lastError = 'In-app purchases are not available on this device.';
        dev.log(_lastError!, name: _tag);
        return false;
      }

      // Build the canonical plan catalog.
      _buildPlanCatalog();

      // Listen to purchase updates before loading products so we don't miss
      // any pending transactions.
      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          dev.log('Purchase stream closed', name: _tag);
        },
        onError: (Object error) {
          dev.log('Purchase stream error: $error', name: _tag, error: error);
          _lastError = 'Purchase stream error: $error';
        },
      );

      // Load product details from the store.
      final loaded = await _loadProducts();
      if (!loaded) {
        dev.log('Failed to load products from store', name: _tag);
        // Continue initialization -- we can still attempt purchases with the
        // product IDs, the store will resolve them at checkout time.
      }

      // Restore any pending or previous purchases.
      await restorePurchases();

      _isInitialized = true;
      _lastError = null;
      dev.log('Billing service initialized successfully', name: _tag);
      return true;
    } catch (e, st) {
      _lastError = 'Initialization failed: $e';
      dev.log('initialize() failed', name: _tag, error: e, stackTrace: st);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Product catalog
  // ---------------------------------------------------------------------------

  /// Returns the list of loaded [SubscriptionPlan] objects.
  ///
  /// Plans are enriched with store pricing when available. If the store
  /// products have not loaded yet, returns the catalog with default prices.
  List<SubscriptionPlan> getAvailableProducts() {
    final plans = <SubscriptionPlan>[];
    for (final entry in _planCatalog.entries) {
      final plan = entry.value;
      final storeProduct = _storeProducts[entry.key];

      if (storeProduct != null) {
        // Enrich the plan with live store data.
        plans.add(plan.copyWith(
          priceString: storeProduct.price,
          // Note: rawPrice and currencyCode would need the
          // SkuDetails wrapper on Android to extract precisely.
          // The storeProduct.price is the formatted string.
        ));
      } else {
        plans.add(plan);
      }
    }
    return plans;
  }

  /// Returns a specific [SubscriptionPlan] by its product ID, or null.
  SubscriptionPlan? getPlanById(String productId) {
    return _planCatalog[productId];
  }

  // ---------------------------------------------------------------------------
  // Purchase flow
  // ---------------------------------------------------------------------------

  /// Initiates a purchase flow for the given [plan].
  ///
  /// Only one purchase can be in progress at a time. If a purchase is already
  /// running, this returns `false` immediately.
  ///
  /// Returns `true` if the purchase flow was successfully initiated (not
  /// completed -- listen to [purchaseStream] for the outcome).
  Future<bool> purchasePlan(SubscriptionPlan plan) async {
    if (!_isInitialized) {
      _lastError = 'Billing service not initialized. Call initialize() first.';
      dev.log(_lastError!, name: _tag);
      return false;
    }

    if (_purchaseInProgress) {
      dev.log('Purchase already in progress, ignoring request', name: _tag);
      return false;
    }

    try {
      _purchaseInProgress = true;
      _lastError = null;
      dev.log('Initiating purchase for: ${plan.id}', name: _tag);

      final storeProduct = _storeProducts[plan.id];
      if (storeProduct == null) {
        _lastError = 'Product "${plan.id}" not found in store catalog.';
        dev.log(_lastError!, name: _tag);
        _purchaseInProgress = false;
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: storeProduct);

      // Subscriptions use buyNonConsumable on some platforms; on Android
      // subscriptions are handled via buyConsumable with the subscription
      // extension. The in_app_purchase package handles this transparently
      // when the product type is subscription.
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      dev.log('Purchase flow launched for: ${plan.id}', name: _tag);
      return true;
    } catch (e, st) {
      _lastError = 'Purchase failed to start: $e';
      dev.log('purchasePlan() failed', name: _tag, error: e, stackTrace: st);
      _purchaseInProgress = false;
      _purchaseStatusController.add(PurchaseStatus.error);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Restore purchases
  // ---------------------------------------------------------------------------

  /// Restores previously completed purchases from the store.
  ///
  /// On Android this queries the store for active subscriptions owned by the
  /// current account. Results arrive asynchronously via [purchaseStream].
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      dev.log('restorePurchases called before initialize()', name: _tag);
      // Still attempt -- the store may be available.
    }

    try {
      dev.log('Restoring purchases...', name: _tag);
      await _iap.restorePurchases();
      dev.log('Restore purchases request sent', name: _tag);
    } catch (e, st) {
      _lastError = 'Restore failed: $e';
      dev.log('restorePurchases() failed',
          name: _tag, error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Verification
  // ---------------------------------------------------------------------------

  /// Verifies a purchase with the backend server.
  ///
  /// This is a stub for server-side receipt verification. In production, the
  /// purchase receipt (base64-encoded) and the product ID should be sent to
  /// a secure backend that validates the receipt with Google Play's API.
  ///
  /// Returns `true` if the purchase is verified, `false` otherwise.
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    dev.log(
      'verifyPurchase called for: ${purchase.productID} '
      '(status: ${purchase.status})',
      name: _tag,
    );

    // In a real implementation:
    // 1. Send purchase.verificationData.serverVerificationData to backend
    // 2. Backend calls Google Play Developer API to verify
    // 3. Backend returns verification result
    //
    // For now, accept all purchases that reached the purchased/restored state.
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      dev.log('Purchase verified (stub): ${purchase.productID}', name: _tag);
      return true;
    }

    dev.log('Purchase NOT verified: ${purchase.productID}', name: _tag);
    return false;
  }

  // ---------------------------------------------------------------------------
  // Purchase stream handler
  // ---------------------------------------------------------------------------

  /// Handles incoming purchase updates from the store.
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      dev.log(
        'Purchase update: ${purchase.productID} -> ${purchase.status} '
        '(pending: ${purchase.pendingCompletePurchase})',
        name: _tag,
      );

      _handlePurchase(purchase);
    }
  }

  /// Processes a single purchase detail, handling each status appropriately.
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final verified = await verifyPurchase(purchase);
        if (verified) {
          _purchaseStatusController.add(purchase.status);
          dev.log('Purchase confirmed: ${purchase.productID}', name: _tag);
        } else {
          _purchaseStatusController.add(PurchaseStatus.error);
          _lastError = 'Purchase verification failed for ${purchase.productID}';
          dev.log(_lastError!, name: _tag);
        }

        // Complete the purchase so the store knows we handled it.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
          dev.log('Purchase completed: ${purchase.productID}', name: _tag);
        }
        break;

      case PurchaseStatus.pending:
        _purchaseStatusController.add(PurchaseStatus.pending);
        dev.log('Purchase pending: ${purchase.productID}', name: _tag);
        break;

      case PurchaseStatus.error:
        _lastError = _mapStoreError(purchase.error);
        _purchaseStatusController.add(PurchaseStatus.error);
        dev.log(
          'Purchase error: ${purchase.productID} - $_lastError',
          name: _tag,
          error: purchase.error,
        );

        // Complete the errored purchase to clear it from the queue.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.canceled:
        _purchaseStatusController.add(PurchaseStatus.canceled);
        dev.log('Purchase canceled: ${purchase.productID}', name: _tag);

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      // exhaustive cases handled above
    }

    _purchaseInProgress = false;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds the canonical plan catalog from [SubscriptionPlan] constants.
  void _buildPlanCatalog() {
    _planCatalog.clear();
    for (final plan in SubscriptionPlan.allPlans) {
      _planCatalog[plan.id] = plan;
    }
    dev.log(
      'Plan catalog built: ${_planCatalog.keys.join(', ')}',
      name: _tag,
    );
  }

  /// Loads product details from the store for all known product IDs.
  ///
  /// Retries up to [_maxRetries] times on failure. Returns `true` if at
  /// least one product was loaded.
  Future<bool> _loadProducts() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        dev.log(
          'Loading products (attempt $attempt/$_maxRetries)...',
          name: _tag,
        );

        final response = await _iap.queryProductDetails(_productIds);

        if (response.error != null) {
          dev.log(
            'Query product details error: ${response.error}',
            name: _tag,
          );
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          return false;
        }

        if (response.notFoundIDs.isNotEmpty) {
          dev.log(
            'Products not found in store: ${response.notFoundIDs.join(', ')}',
            name: _tag,
          );
        }

        _storeProducts.clear();
        for (final product in response.productDetails) {
          _storeProducts[product.id] = product;
          dev.log(
            'Loaded product: ${product.id} - ${product.title} '
            '(${product.price})',
            name: _tag,
          );
        }

        if (_storeProducts.isEmpty) {
          dev.log('No products loaded from store', name: _tag);
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay * attempt);
            continue;
          }
          return false;
        }

        dev.log(
          'Loaded ${_storeProducts.length}/${_productIds.length} products',
          name: _tag,
        );
        return true;
      } catch (e, st) {
        dev.log(
          '_loadProducts attempt $attempt failed',
          name: _tag,
          error: e,
          stackTrace: st,
        );
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }
    return false;
  }

  /// Maps a store error to a user-friendly message.
  String _mapStoreError(IAPError? error) {
    if (error == null) return 'An unknown purchase error occurred.';

    switch (error.source) {
      case 'google_play':
        switch (error.code) {
          case 'BILLING_UNAVAILABLE':
            return 'Billing is not available. Please update Google Play Store.';
          case 'ITEM_UNAVAILABLE':
            return 'This plan is not available in your region.';
          case 'ITEM_ALREADY_OWNED':
            return 'You already own this subscription.';
          case 'ITEM_NOT_OWNED':
            return 'You do not own this item to consume.';
          case 'NETWORK_ERROR':
            return 'Network error. Please check your connection and try again.';
          case 'USER_CANCELED':
            return 'Purchase was canceled.';
          default:
            return 'Google Play error: ${error.message}';
        }
      default:
        return error.message;
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  /// Cleans up all resources.
  ///
  /// Call this when the billing service is no longer needed (e.g., app exit).
  /// After calling dispose, the service must be re-initialized before use.
  void dispose() {
    dev.log('Disposing billing service', name: _tag);
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _purchaseStatusController.close();
    _storeProducts.clear();
    _planCatalog.clear();
    _isInitialized = false;
    _purchaseInProgress = false;
    _lastError = null;
  }

  // ---------------------------------------------------------------------------
  // Debug helpers
  // ---------------------------------------------------------------------------

  /// Returns a debug summary of the billing service state.
  String debugSummary() {
    final buffer = StringBuffer()
      ..writeln('--- BillingService Debug ---')
      ..writeln('Initialized: $_isInitialized')
      ..writeln('Purchase in progress: $_purchaseInProgress')
      ..writeln('Last error: $_lastError')
      ..writeln('Store products: ${_storeProducts.length}')
      ..writeln('Plan catalog: ${_planCatalog.length}')
      ..writeln('Known product IDs: ${_productIds.join(', ')}');

    if (_storeProducts.isNotEmpty) {
      buffer.writeln('Loaded products:');
      for (final p in _storeProducts.values) {
        buffer.writeln('  - ${p.id}: ${p.title} (${p.price})');
      }
    }

    return buffer.toString();
  }
}
