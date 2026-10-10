import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../config/app_config.dart';
import '../state/expense_controller.dart';

enum BuyResult { success, cancelled, pending, failed, unavailable }

/// Google Play Billing for the VIP subscriptions (Play Store edition only).
///
/// Google takes the payment; the app grants VIP only after Google reports the
/// purchase, and re-checks the active subscriptions on every launch so a
/// cancelled or expired one switches VIP off again.
class BillingService {
  BillingService._();
  static final instance = BillingService._();

  /// Product IDs of the subscriptions created in Play Console.
  static const monthlyId = 'meowtang_pro_monthly';
  static const yearlyId = 'meowtang_pro_yearly';
  static const productIds = {monthlyId, yearlyId};

  /// VIP stays on this long after the last successful check with Google,
  /// so it keeps working offline for a while.
  static const _offlineGrace = Duration(days: 7);

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  DateTime? _lastCheck;
  ExpenseController? _controller;
  Completer<BuyResult>? _pendingBuy;

  bool _available = false;
  bool get isAvailable => _available;

  /// Product details by ID, with Google's localized price (e.g. "฿59.00").
  final Map<String, ProductDetails> products = {};

  static bool get _supported => AppConfig.isPlayStoreEdition && !kIsWeb && Platform.isAndroid;

  Future<void> init(ExpenseController controller) async {
    if (!_supported) return;
    _controller = controller;
    // Listen before anything else: a purchase finished while the app was closed
    // (e.g. a pending PromptPay payment) is delivered here on start.
    _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
    // Google does not tell the app when a subscription ends, so ask again when
    // the user comes back to the app and every few minutes while it is open.
    _lifecycle ??= AppLifecycleListener(onResume: () => _recheck());
    _timer ??= Timer.periodic(const Duration(minutes: 10), (_) => _recheck());
    try {
      _available = await _iap.isAvailable();
      if (!_available) return;
      await loadProducts();
      await syncEntitlement();
    } catch (_) {
      // Billing problems must never stop the app from starting.
    }
  }

  Future<void> loadProducts() async {
    final res = await _iap.queryProductDetails(productIds);
    products.clear();
    for (final p in res.productDetails) {
      // A subscription comes back once per base plan / offer; keep the full-price one
      // so the paywall never shows a trial or discount price as the regular price.
      final kept = products[p.id];
      if (kept == null || p.rawPrice > kept.rawPrice) products[p.id] = p;
    }
  }

  /// Re-checks the subscription, at most once every 30 seconds and never
  /// while a purchase is in progress.
  Future<void> _recheck() async {
    if (!_available || _pendingBuy != null) return;
    final last = _lastCheck;
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 30)) return;
    await syncEntitlement();
  }

  /// Asks Google which subscriptions are active and sets VIP to match.
  /// Returns whether VIP is on afterwards; null when Google could not be reached.
  Future<bool?> syncEntitlement() async {
    final controller = _controller;
    if (!_supported || controller == null) return null;
    _lastCheck = DateTime.now();
    try {
      final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final res = await addition.queryPastPurchases();
      if (res.error != null) return null;
      final active = res.pastPurchases
          .where((p) => productIds.contains(p.productID) && p.status == PurchaseStatus.purchased)
          .toList();
      for (final p in active) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }
      if (active.isNotEmpty) {
        await _grant(active.any((p) => p.productID == yearlyId) ? 'yearly' : 'monthly');
        return true;
      }
      // Only switch off VIP that came from a subscription.
      if (const {'monthly', 'yearly'}.contains(controller.premiumTier)) {
        await controller.setPremiumStatus(false, tier: 'none');
      }
      return false;
    } catch (_) {
      return null;
    }
  }

  Future<BuyResult> buy(String productId) async {
    if (!_supported) return BuyResult.unavailable;
    if (!_available) {
      _available = await _iap.isAvailable();
      if (!_available) return BuyResult.unavailable;
    }
    if (!products.containsKey(productId)) await loadProducts();
    final product = products[productId];
    if (product == null) return BuyResult.unavailable;

    _pendingBuy = Completer<BuyResult>();
    try {
      final started = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
      if (!started) return BuyResult.failed;
    } catch (_) {
      _pendingBuy = null;
      return BuyResult.failed;
    }
    // Some payment methods (e.g. cash or bank transfer) stay pending for a long time.
    return _pendingBuy!.future.timeout(const Duration(minutes: 10), onTimeout: () => BuyResult.pending);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!productIds.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _finishBuy(BuyResult.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant(p.productID == yearlyId ? 'yearly' : 'monthly');
          _finishBuy(BuyResult.success);
        case PurchaseStatus.canceled:
          _finishBuy(BuyResult.cancelled);
        case PurchaseStatus.error:
          _finishBuy(BuyResult.failed);
      }
      // Google refunds purchases that are not acknowledged within 3 days.
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  void _finishBuy(BuyResult result) {
    final c = _pendingBuy;
    if (c != null && !c.isCompleted) c.complete(result);
    if (result != BuyResult.pending) _pendingBuy = null;
  }

  Future<void> _grant(String tier) async {
    await _controller?.setPremiumStatus(true, tier: tier, expiry: DateTime.now().add(_offlineGrace));
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _timer?.cancel();
    _timer = null;
  }
}
