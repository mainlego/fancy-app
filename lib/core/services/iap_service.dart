import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../features/settings/domain/models/subscription_model.dart';
import 'supabase_service.dart';

/// In-App Purchase Service for handling subscriptions and consumable purchases
class IAPService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final SupabaseService _supabase;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Callbacks
  Function(String message)? onError;
  Function(String productId)? onPurchaseSuccess;
  Function()? onPurchaseRestored;

  IAPService(this._supabase);

  /// All product IDs
  static Set<String> get allProductIds => {
    // Subscriptions
    ...PremiumPlan.values.where((p) => p.isPaid).map((p) => p.productId),
    // Consumables
    ...InAppPurchaseItem.values.map((p) => p.productId),
  };

  /// Initialize IAP
  Future<void> initialize() async {
    if (kIsWeb) return; // IAP not available on web

    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      print('IAP: Store not available');
      return;
    }

    // Listen to purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) {
        print('IAP: Purchase stream error: $error');
        onError?.call('Purchase failed. Please try again.');
      },
    );

    // Load products
    await loadProducts();
  }

  /// Load available products from store
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final response = await _inAppPurchase.queryProductDetails(allProductIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    print('IAP: Loaded ${_products.length} products');
  }

  /// Get product details by ID
  ProductDetails? getProduct(String productId) {
    return _products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == productId,
      orElse: () => null,
    );
  }

  /// Get subscription product
  ProductDetails? getSubscriptionProduct(PremiumPlan plan) {
    return getProduct(plan.productId);
  }

  /// Get in-app purchase product
  ProductDetails? getInAppProduct(InAppPurchaseItem item) {
    return getProduct(item.productId);
  }

  /// Buy subscription
  Future<bool> buySubscription(PremiumPlan plan) async {
    if (!_isAvailable) {
      onError?.call('Store not available');
      return false;
    }

    final product = getSubscriptionProduct(plan);
    if (product == null) {
      onError?.call('Product not found');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Use buyNonConsumable for subscriptions
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      print('IAP: Error buying subscription: $e');
      onError?.call('Purchase failed: $e');
      return false;
    }
  }

  /// Buy consumable item (super likes, invisible mode)
  Future<bool> buyConsumable(InAppPurchaseItem item) async {
    if (!_isAvailable) {
      onError?.call('Store not available');
      return false;
    }

    final product = getInAppProduct(item);
    if (product == null) {
      onError?.call('Product not found');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      print('IAP: Error buying consumable: $e');
      onError?.call('Purchase failed: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onError?.call('Store not available');
      return;
    }

    await _inAppPurchase.restorePurchases();
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          print('IAP: Purchase pending: ${purchase.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final valid = await _verifyPurchase(purchase);
          if (valid) {
            await _deliverPurchase(purchase);
            if (purchase.status == PurchaseStatus.purchased) {
              onPurchaseSuccess?.call(purchase.productID);
            } else {
              onPurchaseRestored?.call();
            }
          }
          break;

        case PurchaseStatus.error:
          print('IAP: Purchase error: ${purchase.error}');
          onError?.call(purchase.error?.message ?? 'Purchase failed');
          break;

        case PurchaseStatus.canceled:
          print('IAP: Purchase canceled');
          break;
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  /// Verify purchase (server-side verification recommended for production)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implement server-side verification for production
    // For now, we trust the purchase
    return true;
  }

  /// Deliver purchase to user
  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;

    // Check if it's a subscription
    final subscriptionPlan = PremiumPlan.values.cast<PremiumPlan?>().firstWhere(
      (p) => p?.productId == productId,
      orElse: () => null,
    );

    if (subscriptionPlan != null) {
      await _deliverSubscription(subscriptionPlan, purchase.purchaseID);
      return;
    }

    // Check if it's a consumable
    final consumableItem = InAppPurchaseItem.values.cast<InAppPurchaseItem?>().firstWhere(
      (p) => p?.productId == productId,
      orElse: () => null,
    );

    if (consumableItem != null) {
      await _deliverConsumable(consumableItem, purchase.purchaseID);
    }
  }

  /// Deliver subscription to user
  Future<void> _deliverSubscription(PremiumPlan plan, String? transactionId) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    await _supabase.saveSubscription(
      planType: plan.name,
      startDate: now,
      endDate: now.add(Duration(days: plan.durationInDays)),
      isActive: true,
      transactionId: transactionId,
      isTrialUsed: plan.isTrial,
    );

    print('IAP: Delivered subscription: ${plan.name}');
  }

  /// Deliver consumable to user
  Future<void> _deliverConsumable(InAppPurchaseItem item, String? transactionId) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    if (item.isSuperLike) {
      // Add super likes to balance
      await _supabase.addSuperLikes(item.quantity);
      print('IAP: Added ${item.quantity} super likes');
    } else if (item.isInvisibleMode) {
      // Activate invisible mode
      await _supabase.activateInvisibleMode(item.quantity);
      print('IAP: Activated invisible mode for ${item.quantity} days');
    }
  }

  /// Dispose
  void dispose() {
    _purchaseSubscription?.cancel();
  }

  /// Check if IAP is available
  bool get isAvailable => _isAvailable;

  /// Get all available products
  List<ProductDetails> get products => _products;
}

/// IAP Service Provider
final iapServiceProvider = Provider<IAPService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return IAPService(supabase);
});

/// IAP Products Provider
final iapProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final iap = ref.watch(iapServiceProvider);
  await iap.initialize();
  return iap.products;
});
