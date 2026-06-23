import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _isInitialized = false;

  static const String premiumBattlePassId = 'premium_battle_pass';
  static const String motivationBoostId = 'motivation_boost_pack';
  static const String megaEctsPackId = 'mega_ects_pack';
  static const String removeAdsId = 'remove_ads';

  static const String skinGoldLaptopId = 'skin_gold_laptop';
  static const String skinNeonId = 'skin_neon';
  static const String skinRetroId = 'skin_retro';

  static const Set<String> _productIds = {
    premiumBattlePassId,
    motivationBoostId,
    megaEctsPackId,
    removeAdsId,
    skinGoldLaptopId,
    skinNeonId,
    skinRetroId,
  };

  static List<ProductDetails> availableProducts = [];

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('❌ In-App Purchase not available');
      return false;
    }

    await _loadProducts();

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('❌ Purchase error: $error');
      },
    );

    await restorePurchases();

    _isInitialized = true;
    debugPrint('✅ Purchase service initialized');
    return true;
  }

  static Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint('❌ Error loading products: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('⚠️ No products found');
      return;
    }

    availableProducts = response.productDetails;
    debugPrint('✅ Loaded ${availableProducts.length} products');
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint('📦 Purchase update: ${purchase.productID} - ${purchase.status}');

      if (purchase.status == PurchaseStatus.purchased) {
        _handleSuccessfulPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase failed: ${purchase.error}');
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  static void _handleSuccessfulPurchase(PurchaseDetails purchase) {
    debugPrint('✅ Purchase successful: ${purchase.productID}');

    _onPurchaseSuccess?.call(purchase.productID);
  }

  static Function(String productId)? _onPurchaseSuccess;

  static void setOnPurchaseSuccess(Function(String) callback) {
    _onPurchaseSuccess = callback;
  }

  static Future<bool> buyProduct(String productId) async {
    if (!_isInitialized) {
      debugPrint('❌ Purchase service not initialized');
      return false;
    }

    final product = availableProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      final bool success =
          await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      debugPrint('❌ Error buying product: $e');
      return false;
    }
  }

  static Future<bool> buyConsumable(String productId) async {
    if (!_isInitialized) {
      debugPrint('❌ Purchase service not initialized');
      return false;
    }

    final product = availableProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      final bool success =
          await _iap.buyConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      debugPrint('❌ Error buying consumable: $e');
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      debugPrint('✅ Purchases restored');
    } catch (e) {
      debugPrint('❌ Error restoring purchases: $e');
    }
  }

  static Future<bool> isPurchased(String productId) async {
    await _iap.restorePurchases();
    return false; // TODO: Implement proper check
  }

  static String getProductPrice(String productId) {
    try {
      final product = availableProducts.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (e) {
      return '\$4.99';
    }
  }

  static String getProductDescription(String productId) {
    try {
      final product = availableProducts.firstWhere((p) => p.id == productId);
      return product.description;
    } catch (e) {
      return 'Premium content';
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}
